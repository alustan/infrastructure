package main

import (
	"fmt"
	"log"
	"os/exec"
	"strings"

	"github.com/hashicorp/terraform-exec/tfexec"
	"github.com/alustan/infrastructure/pkg/deploy"
)

const tfVarsFile = "terraform.tfvars"

// findTerraformPath finds the path to the Terraform binary.
func findTerraformPath() (string, error) {
	cmd := exec.Command("which", "terraform")
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("error finding Terraform: %v", err)
	}
	return strings.TrimSpace(string(output)), nil
}

func main() {
	workspace, region, vpcCidr, cluster, db, err := deploy.ExtractVariables()
	if err != nil {
		log.Fatalf("Error extracting variables: %v", err)
	}

	// Print out the extracted variables
	fmt.Printf("Workspace: %s\n", workspace)
	fmt.Printf("Region: %s\n", region)
	fmt.Printf("VPC CIDR: %s\n", vpcCidr)
	fmt.Printf("Cluster: %s\n", cluster)
	fmt.Printf("DB: %s\n", db)

	resourceType, err := deploy.DetermineResourceType(cluster, db)
	if err != nil {
		log.Fatalf("%v", err)
	}

	sess, err := deploy.InitializeAWSSession(region)
	if err != nil {
		log.Fatalf("Failed to initialize AWS session: %v", err)
	}

	err = deploy.ChangeDirectory("backend")
	if err != nil {
		log.Fatalf("Failed to change directory to backend: %v", err)
	}

	terraformPath, err := findTerraformPath()
	if err != nil {
		log.Fatalf("Failed to find Terraform: %v", err)
	}

	tf, err := tfexec.NewTerraform(".", terraformPath)
	if err != nil {
		log.Fatalf("Failed to initialize Terraform: %v", err)
	}

	err = deploy.InitializeAndPlanTerraform(tf)
	if err != nil {
		log.Fatalf("Failed to plan Terraform: %v", err)
	}

	plannedS3BucketName, plannedDynamoDBName, err := deploy.ExtractPlannedOutputs("tfplan")
	if err != nil {
		log.Fatalf("Failed to extract planned outputs: %v", err)
	}

	err = deploy.CheckAndCreateBackendResources(sess, plannedS3BucketName, plannedDynamoDBName, tf, workspace, region)
	if err != nil {
		log.Fatalf("Failed to handle backend resources: %v", err)
	}

	defer deploy.ChangeDirectory("..")

	err = deploy.CheckVPCCidr(sess, vpcCidr, region, resourceType)
	if err != nil {
		log.Fatalf("Error checking VPC CIDR: %v", err)
	}

	err = deploy.InitializeTerraformConfig(tf)
	if err != nil {
		log.Fatalf("Failed to initialize Terraform: %v", err)
	}

	err = deploy.ManageTerraformWorkspaces(tf, workspace)
	if err != nil {
		log.Fatalf("Failed to manage Terraform workspaces: %v", err)
	}

	err = deploy.ApplyTerraformConfig(tf, tfVarsFile)
	if err != nil {
		log.Fatalf("Failed to apply Terraform configuration: %v", err)
	}

	fmt.Println("Terraform apply completed successfully.")
}
