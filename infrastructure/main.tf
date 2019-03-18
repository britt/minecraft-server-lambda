variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "us-west-2"
}

variable "apex_function_role" {}
variable "apex_function_names" { type = "map" }
variable "apex_function_arns" { type = "map" }
variable "project_name" {
    default = "MCControl"
}

provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_iam_policy" "ec2-start-stop" {
  name        = "ec2-start-stop"
    description = "Allow lambda functions to start and stop EC2 instances"
    policy      =  <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
    EOF
}

resource "aws_iam_policy_attachment" "ec2-start-stop-lambda-attach" {
    name       = "ec2-start-stop-attachment"
    roles      = ["${var.project_name}_lambda_function"]
    policy_arn = "${aws_iam_policy.ec2-start-stop.arn}"
}