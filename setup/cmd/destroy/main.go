package main

import (
	"fmt"
	"log"
	"flag"

	"os/exec"
	"strings"

	"github.com/hashicorp/terraform-exec/tfexec"
	"github.com/alustan/infrastructure/pkg/destroy"
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
	// Define and parse command-line flags
	destroyCluster := flag.Bool("c", false, "Destroy cluster module")
	destroyDatabase := flag.Bool("d", false, "Destroy database module")
	flag.Parse()

	// Extract variables
	workspace, region, err := destroy.ExtractVariables()
	if err != nil {
		log.Fatalf("Error extracting variables: %v", err)
	}

	// Print out the extracted variables
	fmt.Printf("Workspace: %s\n", workspace)
	fmt.Printf("Region: %s\n", region)
	

	// Initialize AWS session
	_, err = destroy.InitializeAWSSession(region)
	if err != nil {
		log.Fatalf("Failed to initialize AWS session: %v", err)
	}

	// Change directory to "backend"
	err = destroy.ChangeDirectory("backend")
	if err != nil {
		log.Fatalf("Failed to change directory to backend: %v", err)
	}

	// Find Terraform binary path
	terraformPath, err := findTerraformPath()
	if err != nil {
		log.Fatalf("Failed to find Terraform: %v", err)
	}

	// Initialize Terraform
	tf, err := tfexec.NewTerraform(".", terraformPath)
	if err != nil {
		log.Fatalf("Failed to initialize Terraform: %v", err)
	}

	// Initialize and plan Terraform
	err = destroy.InitializeAndPlanTerraform(tf)
	if err != nil {
		log.Fatalf("Failed to plan Terraform: %v", err)
	}

	// Extract planned outputs
	s3BucketName, dynamoDBName, err := destroy.ExtractPlannedOutputs("tfplan")
	if err != nil {
		log.Fatalf("Failed to extract planned outputs: %v", err)
	}

	// Change directory back
	defer destroy.ChangeDirectory("..")

	if err := destroy.WriteBackendConfig(s3BucketName, dynamoDBName, workspace, region); err != nil {
		log.Fatalf("Failed to write backend config: %v", err)
	}

	fmt.Printf("Destroying %s...\n", workspace)

	// Initialize Terraform configuration
	err = destroy.InitializeTerraformConfig(tf)
	if err != nil {
		log.Fatalf("Failed to initialize Terraform: %v", err)
	}

	// Manage Terraform workspaces
	err = destroy.ManageTerraformWorkspaces(tf, workspace)
	if err != nil {
		log.Fatalf("Failed to manage Terraform workspaces: %v", err)
	}

	
	err = destroy.UpdateKubeconfig(region, workspace)
	if err != nil {
		log.Fatalf("Failed to update kubeconfig: %v", err)
	}

	err = destroy.DeleteIngresses(region)
	if err != nil {
		log.Fatalf("Failed to delete ingresses: %v", err)
	}

	//  destroy Terraform configuration based on flags
	if *destroyCluster || *destroyDatabase {
		destroyTargets := []string{}
		if *destroyCluster {
			destroyTargets = append(destroyTargets, "-target=module.cluster")
		}
		if *destroyDatabase {
			destroyTargets = append(destroyTargets, "-target=module.database")
		}

		err = destroy.DestroyTerraformConfig(tf, tfVarsFile, destroyTargets)
		if err != nil {
			log.Fatalf("Failed to destroy Terraform config: %v", err)
		}
	} else {
		err = destroy.DestroyTerraformConfig(tf, tfVarsFile)
		if err != nil {
			log.Fatalf("Failed to apply Terraform configuration: %v", err)
		}

		fmt.Println("Terraform destroy completed successfully.")
	}
}

