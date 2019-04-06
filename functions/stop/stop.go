package main

import (
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
)

func handler(req interface{}) (*events.APIGatewayProxyResponse, error) {
	svc := ec2.New(session.New())
	findInput := &ec2.DescribeInstancesInput{
		Filters: []*ec2.Filter{
			&ec2.Filter{
				Name: aws.String("tag:Role"),
				Values: []*string{
					aws.String("Minecraft Server"),
				},
			},
		},
	}

	resp, err := svc.DescribeInstances(findInput)
	if err != nil {
		return nil, err
	}

	for _, r := range resp.Reservations {
		input := &ec2.StopInstancesInput{}
		for _, i := range r.Instances {
			input.InstanceIds = append(input.InstanceIds, i.InstanceId)
		}
		if _, err := svc.StopInstances(input); err != nil {
			return nil, err
		}
	}

	return &events.APIGatewayProxyResponse{
		StatusCode: 200,
		Headers: map[string]string{
			"Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
			"Access-Control-Allow-Methods": "POST,OPTIONS",
			"Access-Control-Allow-Origin":  "*",
		},
	}, nil
}

func main() {
	// Make the handler available for Remote Procedure Call by AWS Lambda
	lambda.Start(handler)
}
