package destroy

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
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/hashicorp/terraform-exec/tfexec"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/kubernetes"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
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
func ExtractVariables() (string, string, error) {
	workspace, err := getEnvOrTFVar("TF_VAR_workspace", "workspace")
	if err != nil {
		return "", "", err
	}
	region, err := getEnvOrTFVar("TF_VAR_region", "region")
	if err != nil {
		return "", "", err
	}
	return workspace, region, nil
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

// Check if an S3 bucket exists
func checkS3BucketExists(sess *session.Session, bucketName string) bool {
	svc := s3.New(sess)
	_, err := svc.HeadBucket(&s3.HeadBucketInput{
		Bucket: aws.String(bucketName),
	})
	return err == nil
}

// Write backend configuration to main Terraform configuration
func WriteBackendConfig(s3BucketName, dynamoDBName, workspace, region string) error {
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

// DestroyTerraformConfig destroys Terraform configuration.
// If targets are provided, it destroys specific resources. Otherwise, it destroys all.
func DestroyTerraformConfig(tf *tfexec.Terraform, tfVarsFile string, targets ...[]string) error {
	var cmd *exec.Cmd
	if len(targets) > 0 && len(targets[0]) > 0 {
		// Targets are provided, construct the command with targets
		args := append([]string{"destroy", "-auto-approve"}, targets[0]...)
		cmd = exec.Command("terraform", args...)
	} else {
		// No targets provided, check and construct the command accordingly
		if os.Getenv("TF_VAR_workspace") == "" || os.Getenv("TF_VAR_region") == "" {
			cmd = exec.Command("terraform", "destroy", "-auto-approve", "-var-file", tfVarsFile)
		} else {
			cmd = exec.Command("terraform", "destroy", "-auto-approve")
		}
	}

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("error running terraform destroy: %v\nOutput: %s", err, output)
	}

	return nil
}



// updateKubeconfig updates the kubeconfig for the specified EKS cluster.
func UpdateKubeconfig(region, clusterName string) error {
	cmd := exec.Command("aws", "eks", "--region", region, "update-kubeconfig", "--name", clusterName)
	return cmd.Run()
}

// deleteIngresses deletes all ingresses in all namespaces.
func DeleteIngresses(region string) error {
	config, err := clientcmd.BuildConfigFromFlags("", clientcmd.RecommendedHomeFile)
	if err != nil {
		return fmt.Errorf("failed to build kubeconfig: %v", err)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		return fmt.Errorf("failed to create Kubernetes client: %v", err)
	}

	namespaces, err := clientset.CoreV1().Namespaces().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		return fmt.Errorf("failed to list namespaces: %v", err)
	}

	for _, namespace := range namespaces.Items {
		ingresses, err := clientset.NetworkingV1().Ingresses(namespace.Name).List(context.TODO(), metav1.ListOptions{})
		if err != nil {
			fmt.Fprintf(os.Stderr, "Failed to list ingresses in namespace %s: %v\n", namespace.Name, err)
			continue
		}

		for _, ingress := range ingresses.Items {
			err = clientset.NetworkingV1().Ingresses(namespace.Name).Delete(context.TODO(), ingress.Name, metav1.DeleteOptions{})
			if err != nil {
				fmt.Fprintf(os.Stderr, "Failed to delete ingress %s in namespace %s: %v\n", ingress.Name, namespace.Name, err)
			}
		}
	}

	return nil
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