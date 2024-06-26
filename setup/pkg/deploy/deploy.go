package deploy

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/hashicorp/terraform-exec/tfexec"
)

const tfVarsFile = "terraform.tfvars"

// Helper function to get a variable from tfvars file
func getTFVar(varName string) (string, error) {
	file, err := os.Open(tfVarsFile)
	if err != nil {
		return "", err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, varName) {
			parts := strings.SplitN(line, "=", 2)
			if len(parts) == 2 {
				return strings.TrimSpace(strings.Trim(parts[1], `"`)), nil
			}
		}
	}
	return "", fmt.Errorf("variable %s not found", varName)
}

// Extract variables from environment or tfvars
func ExtractVariables() (string, string, string, string, string, error) {
	workspace, err := getEnvOrTFVar("TF_VAR_workspace", "workspace")
	if err != nil {
		return "", "", "", "", "", err
	}
	region, err := getEnvOrTFVar("TF_VAR_region", "region")
	if err != nil {
		return "", "", "", "", "", err
	}
	vpcCidr, err := getEnvOrTFVar("TF_VAR_vpc_cidr", "vpc_cidr")
	if err != nil {
		return "", "", "", "", "", err
	}
	cluster, err := getEnvOrTFVar("TF_VAR_provision_cluster", "provision_cluster")
	if err != nil {
		return "", "", "", "", "", err
	}
	db, err := getEnvOrTFVar("TF_VAR_provision_db", "provision_db")
	if err != nil {
		return "", "", "", "", "", err
	}
	return workspace, region, vpcCidr, cluster, db, nil
}

func getEnvOrTFVar(envVar, tfVar string) (string, error) {
	value := os.Getenv(envVar)
	if value == "" {
		var err error
		value, err = getTFVar(tfVar)
		if err != nil {
			return "", err
		}
	}
	return strings.Trim(value, `"`), nil
}

// Determine resource type
func DetermineResourceType(provisionCluster, provisionDb string) (string, error) {
	if provisionCluster == "true" {
		return "cluster", nil
	} else if provisionDb == "true" {
		return "database", nil
	}
	return "", fmt.Errorf("No resource provision specified. Exiting.")
}

// Initialize AWS session
func InitializeAWSSession(region string) (*session.Session, error) {
	return session.NewSession(&aws.Config{
		Region: aws.String(region),
	})
}

// Change directory
func ChangeDirectory(path string) error {
	return os.Chdir(path)
}

func InitializeAndPlanTerraform(tf *tfexec.Terraform) error {
	// Initialize Terraform and reconfigure
	if err := tf.Init(context.Background(), tfexec.Reconfigure(true)); err != nil {
		return fmt.Errorf("error initializing Terraform: %v", err)
	}

	// Plan Terraform configuration
	if _, err := tf.Plan(context.Background(), tfexec.Out("tfplan")); err != nil {
		return fmt.Errorf("error planning Terraform: %v", err)
	}

	return nil
}

// Extract planned outputs from the Terraform plan JSON
func ExtractPlannedOutputs(planFile string) (string, string, error) {
	cmd := exec.Command("terraform", "show", "-json", planFile)
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		return "", "", fmt.Errorf("failed to run terraform show command: %v", err)
	}

	var plan map[string]interface{}
	err = json.Unmarshal(out.Bytes(), &plan)
	if err != nil {
		return "", "", fmt.Errorf("failed to parse terraform plan JSON: %v", err)
	}

	plannedValues := plan["planned_values"].(map[string]interface{})
	outputs := plannedValues["outputs"].(map[string]interface{})

	s3BucketName := outputs["s3_bucket_name"].(map[string]interface{})["value"].(string)
	dynamoDBName := outputs["dynamodb_name"].(map[string]interface{})["value"].(string)

	return s3BucketName, dynamoDBName, nil
}

// Check and create backend resources
func CheckAndCreateBackendResources(sess *session.Session, plannedS3BucketName, plannedDynamoDBName string, tf *tfexec.Terraform, workspace, region string) error {
	if checkS3BucketExists(sess, plannedS3BucketName) && checkDynamoDBTableExists(sess, plannedDynamoDBName) {
		fmt.Println("S3 bucket and DynamoDB table already exist. Skipping creation.")
	} else {
		fmt.Println("S3 bucket or DynamoDB table does not exist. Creating...")
		err := initializeBackendBootstrap(tf)
		if err != nil {
			return err
		}
		s3BucketName, dynamoDBName, err := extractBackendOutputs(tf)
		if err != nil {
			return err
		}
		return writeBackendConfig(s3BucketName, dynamoDBName, workspace, region)
	}
	return nil
}

func writeBackendConfig(s3BucketName, dynamoDBName, workspace, region string) error {
	backendConfig := fmt.Sprintf(`terraform {
  backend "s3" {
    bucket         = "%s"
    key            = "%s/%s/terraform.tfstate"
    region         = "%s"
    dynamodb_table = "%s"
  }
}`, s3BucketName, workspace, region, region, dynamoDBName)
	return os.WriteFile("backend.tf", []byte(backendConfig), 0644)
}

// Check VPC CIDR
func CheckVPCCidr(sess *session.Session, cidr, region, resourceType string) error {
	svc := ec2.New(sess, aws.NewConfig().WithRegion(region))
	result, err := svc.DescribeVpcs(&ec2.DescribeVpcsInput{
		Filters: []*ec2.Filter{
			{
				Name:   aws.String("cidr"),
				Values: []*string{aws.String(cidr)},
			},
			{
				Name:   aws.String("tag:ResourceType"),
				Values: []*string{aws.String(resourceType)},
			},
		},
	})
	if err != nil {
		return err
	}
	if len(result.Vpcs) > 0 {
		return fmt.Errorf("VPC CIDR %s is already in use for %s in region %s", cidr, resourceType, region)
	}
	fmt.Printf("VPC CIDR %s is available for %s.\n", cidr, resourceType)
	return nil
}

// Initialize Terraform configuration
func InitializeTerraformConfig(tf *tfexec.Terraform) error {
	return tf.Init(context.Background(), tfexec.Reconfigure(true))
}

// Manage Terraform workspaces
func ManageTerraformWorkspaces(tf *tfexec.Terraform, workspace string) error {
	workspaces, _, err := tf.WorkspaceList(context.Background())
	if err != nil {
		return err
	}
	if contains(workspaces, workspace) {
		fmt.Printf("Workspace %s exists.\n", workspace)
		return tf.WorkspaceSelect(context.Background(), workspace)
	}
	fmt.Printf("Workspace %s does not exist. Creating...\n", workspace)
	err = tf.WorkspaceNew(context.Background(), workspace)
	if err != nil {
		return err
	}
	return tf.WorkspaceSelect(context.Background(), workspace)
}

// Apply Terraform configuration
func ApplyTerraformConfig(tf *tfexec.Terraform, tfVarsFile string) error {
	if os.Getenv("TF_VAR_workspace") == "" || os.Getenv("TF_VAR_region") == "" || os.Getenv("TF_VAR_vpc_cidr") == "" {
		return tf.Apply(context.Background(), tfexec.VarFile(tfVarsFile))
	}
	return tf.Apply(context.Background())
}

// Check if an S3 bucket exists
func checkS3BucketExists(sess *session.Session, bucketName string) bool {
	svc := s3.New(sess)
	_, err := svc.HeadBucket(&s3.HeadBucketInput{
		Bucket: aws.String(bucketName),
	})
	return err == nil
}

// Check if a DynamoDB table exists
func checkDynamoDBTableExists(sess *session.Session, tableName string) bool {
	svc := dynamodb.New(sess)
	_, err := svc.DescribeTable(&dynamodb.DescribeTableInput{
		TableName: aws.String(tableName),
	})
	return err == nil
}

// Initialize and apply backend Terraform configuration
func initializeBackendBootstrap(tf *tfexec.Terraform) error {
	err := tf.Init(context.Background(), tfexec.Reconfigure(true))
	if err != nil {
		return err
	}
	err = tf.Apply(context.Background())
	return err
}


// Function to extract backend outputs
func extractBackendOutputs(tf *tfexec.Terraform) (string, string, error) {
	ctx := context.Background()

	// Retrieve s3_bucket_name output
	outputs, err := tf.Output(ctx)
	if err != nil {
		return "", "", fmt.Errorf("error getting outputs: %v", err)
	}

	// Unmarshal the value of s3_bucket_name into a string
	var s3BucketName string
	s3BucketOutput, ok := outputs["s3_bucket_name"]
	if !ok {
		return "", "", fmt.Errorf("s3_bucket_name output not found")
	}
	err = json.Unmarshal(s3BucketOutput.Value, &s3BucketName)
	if err != nil {
		return "", "", fmt.Errorf("error unmarshaling s3_bucket_name output: %v", err)
	}

	// Unmarshal the value of dynamodb_name into a string
	var dynamoDBName string
	dynamoDBOutput, ok := outputs["dynamodb_name"]
	if !ok {
		return "", "", fmt.Errorf("dynamodb_name output not found")
	}
	err = json.Unmarshal(dynamoDBOutput.Value, &dynamoDBName)
	if err != nil {
		return "", "", fmt.Errorf("error unmarshaling dynamodb_name output: %v", err)
	}

	return s3BucketName, dynamoDBName, nil
}

// Helper function to check if a string slice contains a specific string
func contains(slice []string, str string) bool {
	for _, s := range slice {
		if s == str {
			return true
		}
	}
	return false
}
