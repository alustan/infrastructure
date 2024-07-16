package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	ec2types "github.com/aws/aws-sdk-go-v2/service/ec2/types"
	"github.com/aws/aws-sdk-go-v2/service/eks"
	"github.com/aws/aws-sdk-go-v2/service/elasticloadbalancingv2"
	"github.com/aws/aws-sdk-go-v2/service/rds"
	
)

type AWSPlugin struct {
	workspace string
	region    string
}

type ResourceInfo struct {
	Service  string
	Resource map[string]interface{}
}

type PluginOutput struct {
	Outputs map[string]interface{} `json:"outputs"`
}

func NewAWSPlugin(workspace, region string) *AWSPlugin {
	return &AWSPlugin{
		workspace: workspace,
		region:    region,
	}
}

func (p *AWSPlugin) Execute() (map[string]interface{}, error) {
	resources, err := FetchAWSResourcesWithTag(p.workspace, p.region)
	if err != nil {
		return nil, err
	}

	// Wrap the resources under "externalresources" key
	externalResources := map[string]interface{}{
		"externalresources": resources,
	}

	result, err := json.Marshal(externalResources)
	if err != nil {
		return nil, fmt.Errorf("error marshalling creds: %v", err)
	}

	var resultMap map[string]interface{}
	err = json.Unmarshal(result, &resultMap)
	if err != nil {
		return nil, fmt.Errorf("error unmarshalling creds: %v", err)
	}
	return resultMap, nil
}

func FetchAWSResourcesWithTag(workspace, region string) ([]ResourceInfo, error) {
	tagKey := "Blueprint"
	tagValue := workspace
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	if err != nil {
		return nil, fmt.Errorf("unable to load AWS SDK config: %v", err)
	}

	var resources []ResourceInfo

	ec2Resources, err := fetchEC2Resources(cfg, tagKey, tagValue)
	if err != nil {
		return nil, err
	}
	resources = append(resources, ec2Resources...)

	rdsResources, err := fetchRDSResources(cfg, tagKey, tagValue)
	if err != nil {
		return nil, err
	}
	resources = append(resources, rdsResources...)

	eksResources, err := fetchEKSResources(cfg, tagKey, tagValue)
	if err != nil {
		return nil, err
	}
	resources = append(resources, eksResources...)

	ebsResources, err := fetchEBSResources(cfg, tagKey, tagValue)
	if err != nil {
		return nil, err
	}
	resources = append(resources, ebsResources...)

	elbResources, err := fetchALBAndNLBResources(cfg, tagKey, tagValue)
	if err != nil {
		return nil, err
	}
	resources = append(resources, elbResources...)

	

	return resources, nil
}

func fetchEC2Resources(cfg aws.Config, tagKey, tagValue string) ([]ResourceInfo, error) {
	svc := ec2.NewFromConfig(cfg)

	input := &ec2.DescribeInstancesInput{
		Filters: []ec2types.Filter{
			{
				Name:   aws.String(fmt.Sprintf("tag:%s", tagKey)),
				Values: []string{tagValue},
			},
		},
	}

	result, err := svc.DescribeInstances(context.TODO(), input)
	if err != nil {
		return nil, fmt.Errorf("failed to describe EC2 instances: %v", err)
	}

	var resources []ResourceInfo
	for _, reservation := range result.Reservations {
		for _, instance := range reservation.Instances {
			instanceInfo := map[string]interface{}{
				"InstanceID":   *instance.InstanceId,
				"InstanceType": instance.InstanceType,
				"State":        instance.State.Name,
				"Tags":         instance.Tags,
			}
			resources = append(resources, ResourceInfo{Service: "EC2", Resource: instanceInfo})
		}
	}

	return resources, nil
}

func fetchRDSResources(cfg aws.Config, tagKey, tagValue string) ([]ResourceInfo, error) {
	svc := rds.NewFromConfig(cfg)

	input := &rds.DescribeDBInstancesInput{}

	result, err := svc.DescribeDBInstances(context.TODO(), input)
	if err != nil {
		return nil, fmt.Errorf("failed to describe RDS instances: %v", err)
	}

	var resources []ResourceInfo
	for _, dbInstance := range result.DBInstances {
		for _, tag := range dbInstance.TagList {
			if *tag.Key == tagKey && *tag.Value == tagValue {
				instanceInfo := map[string]interface{}{
					"DBInstanceIdentifier": *dbInstance.DBInstanceIdentifier,
					"DBInstanceClass":      *dbInstance.DBInstanceClass,
					"DBInstanceStatus":     *dbInstance.DBInstanceStatus,
					"Tags":                 dbInstance.TagList,
				}
				resources = append(resources, ResourceInfo{Service: "RDS", Resource: instanceInfo})
			}
		}
	}

	return resources, nil
}



func fetchEKSResources(cfg aws.Config, tagKey, tagValue string) ([]ResourceInfo, error) {
	svc := eks.NewFromConfig(cfg)

	result, err := svc.ListClusters(context.TODO(), &eks.ListClustersInput{})
	if err != nil {
		return nil, fmt.Errorf("failed to list EKS clusters: %v", err)
	}

	var resources []ResourceInfo
	for _, clusterName := range result.Clusters {
		describeClusterOutput, err := svc.DescribeCluster(context.TODO(), &eks.DescribeClusterInput{
			Name: aws.String(clusterName),
		})
		if err != nil {
			return nil, fmt.Errorf("failed to describe EKS cluster %s: %v", clusterName, err)
		}

		cluster := describeClusterOutput.Cluster
		for key, value := range cluster.Tags {
			if key == tagKey && value == tagValue {
				clusterInfo := map[string]interface{}{
					"ClusterName": *cluster.Name,
					"Status":      cluster.Status,
					"Tags":        cluster.Tags,
				}
				resources = append(resources, ResourceInfo{Service: "EKS", Resource: clusterInfo})
			}
		}
	}

	return resources, nil
}

func fetchEBSResources(cfg aws.Config, tagKey, tagValue string) ([]ResourceInfo, error) {
	svc := ec2.NewFromConfig(cfg)

	input := &ec2.DescribeVolumesInput{
		Filters: []ec2types.Filter{
			{
				Name:   aws.String(fmt.Sprintf("tag:%s", tagKey)),
				Values: []string{tagValue},
			},
		},
	}

	result, err := svc.DescribeVolumes(context.TODO(), input)
	if err != nil {
		return nil, fmt.Errorf("failed to describe EBS volumes: %v", err)
	}

	var resources []ResourceInfo
	for _, volume := range result.Volumes {
		volumeInfo := map[string]interface{}{
			"VolumeID":   *volume.VolumeId,
			"Size":       volume.Size,
			"State":      volume.State,
			"Tags":       volume.Tags,
			"VolumeType": volume.VolumeType,
		}
		resources = append(resources, ResourceInfo{Service: "EBS", Resource: volumeInfo})
	}

	return resources, nil
}

func fetchALBAndNLBResources(cfg aws.Config, tagKey, tagValue string) ([]ResourceInfo, error) {
	svc := elasticloadbalancingv2.NewFromConfig(cfg)

	input := &elasticloadbalancingv2.DescribeLoadBalancersInput{}

	result, err := svc.DescribeLoadBalancers(context.TODO(), input)
	if err != nil {
		return nil, fmt.Errorf("failed to describe load balancers: %v", err)
	}

	var resources []ResourceInfo
	for _, lb := range result.LoadBalancers {
		tagDescription, err := svc.DescribeTags(context.TODO(), &elasticloadbalancingv2.DescribeTagsInput{
			ResourceArns: []string{*lb.LoadBalancerArn},
		})
		if err != nil {
			return nil, fmt.Errorf("failed to describe tags for load balancer %s: %v", *lb.LoadBalancerName, err)
		}

		for _, tagDesc := range tagDescription.TagDescriptions {
			for _, tag := range tagDesc.Tags {
				if *tag.Key == tagKey && *tag.Value == tagValue {
					lbInfo := map[string]interface{}{
						"LoadBalancerName": *lb.LoadBalancerName,
						"State":            lb.State.Code,
						"Type":             lb.Type,
						"Tags":             tagDesc.Tags,
					}
					resources = append(resources, ResourceInfo{Service: "LoadBalancer", Resource: lbInfo})
				}
			}
		}
	}

	return resources, nil
}




func main() {
	workspace := flag.String("workspace", "", "Workspace tag value to filter AWS resources")
	region := flag.String("region", "us-west-2", "AWS region to search for resources")
	flag.Parse()

	if *workspace == "" {
		fmt.Println("Workspace tag value is required")
		os.Exit(1)
	}

	awsPlugin := NewAWSPlugin(*workspace, *region)
	output, err := awsPlugin.Execute()
	if err != nil {
		fmt.Printf("Failed to execute AWS plugin: %v\n", err)
		os.Exit(1)
	}

	jsonOutput, err := json.MarshalIndent(PluginOutput{Outputs: output}, "", "  ")
	if err != nil {
		fmt.Printf("Failed to marshal output to JSON: %v\n", err)
		os.Exit(1)
	}

	fmt.Println(string(jsonOutput))
}
