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

data "aws_lambda_function" "start_function" {
  function_name = "${var.apex_function_names["start"]}"
}

data "aws_lambda_function" "stop_function" {
  function_name = "${var.apex_function_names["stop"]}"
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

resource "aws_api_gateway_rest_api" "mc-control" {
  name        = "MinecraftServerControl"
  description = "Minecraft Server Control"
}

resource "aws_api_gateway_resource" "start" {
  rest_api_id = "${aws_api_gateway_rest_api.mc-control.id}"
  parent_id   = "${aws_api_gateway_rest_api.mc-control.root_resource_id}"
  path_part   = "start"
}

resource "aws_api_gateway_resource" "stop" {
  rest_api_id = "${aws_api_gateway_rest_api.mc-control.id}"
  parent_id   = "${aws_api_gateway_rest_api.mc-control.root_resource_id}"
  path_part   = "stop"
}

resource "aws_api_gateway_method" "start_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.mc-control.id}"
  resource_id   = "${aws_api_gateway_resource.start.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "stop_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.mc-control.id}"
  resource_id   = "${aws_api_gateway_resource.stop.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "start_lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.mc-control.id}"
  resource_id = "${aws_api_gateway_resource.start.id}"
  http_method = "${aws_api_gateway_method.start_method.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${data.aws_lambda_function.start_function.invoke_arn}"
}

resource "aws_api_gateway_integration" "stop_lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.mc-control.id}"
  resource_id = "${aws_api_gateway_resource.stop.id}"
  http_method = "${aws_api_gateway_method.stop_method.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${data.aws_lambda_function.stop_function.invoke_arn}"
}

resource "aws_lambda_permission" "start_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${var.apex_function_names["start"]}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  // source_arn = "${var.apex_function_arns["start"]}/*/*"
}

resource "aws_lambda_permission" "stop_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${var.apex_function_names["stop"]}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  // source_arn = "${var.apex_function_arns["stop"]}/*/*"
}

resource "aws_api_gateway_deployment" "mc_control_deployment" {
  depends_on = ["aws_api_gateway_integration.start_lambda", "aws_api_gateway_integration.stop_lambda"]

  rest_api_id = "${aws_api_gateway_rest_api.mc-control.id}"
  stage_name  = "production"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.mc_control_deployment.invoke_url}"
}