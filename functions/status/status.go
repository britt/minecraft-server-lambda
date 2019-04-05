package main

import (
	"encoding/base64"
	"encoding/json"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
)

type instanceState struct {
	State string
	Type  string
}

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

	var states []instanceState
	for _, r := range resp.Reservations {
		for _, i := range r.Instances {
			states = append(states, instanceState{
				State: *i.State.Name,
				Type:  *i.InstanceType,
			})
		}
	}

	var body []byte

	body, err = json.Marshal(states)
	if err != nil {
		return nil, err
	}

	return &events.APIGatewayProxyResponse{
		StatusCode:      200,
		Body:            base64.StdEncoding.EncodeToString(body),
		IsBase64Encoded: true,
	}, nil
}

func main() {
	// Make the handler available for Remote Procedure Call by AWS Lambda
	lambda.Start(handler)
}