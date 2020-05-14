provider "aws" {
  region = var.region
}

# --- start lamdba policy/role for  -------

#####
resource "aws_iam_role" "lambda_role" {
  name = "lets-chat-lambda-data"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_attach_policy_basicExecutionRole" {
  role = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
# todo can create customized policy to access DynamoDB table access.
/*
{
    "Version": "2012-10-17",
    "Statement": [{
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "dynamodb:BatchWriteItem",
                "dynamodb:PutItem",
                "dynamodb:Query"
            ],
            "Resource": [
                "arn:aws:dynamodb:<region>:<your account id>:table/Chat-Conversations",
                "arn:aws:dynamodb:<region>:<your account id>:table/Chat-Messages",
                "arn:aws:dynamodb:<region>:<your account id>:table/Chat-Conversations/index/Username-ConversationId-index"
            ]
        }
    ]
}
*/

resource "aws_iam_role_policy_attachment" "lambda_attach_policy_dynamoDB" {
  role = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

data "archive_file" "lambda_zip" {
  type = "zip"
  source_file = "lambda/index.js"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "lambda_read_dynamoDB" {
  function_name = "lets-chat-API-01"
  filename = "lambda_function.zip"
  handler = "index.handler"
  role = aws_iam_role.lambda_role.arn
  runtime = "nodejs12.x"
  source_code_hash = filebase64sha256("lambda/index.js")
}


# --- end lamdba policy/role for  -------

# --- start API gateway ---------------

# https://www.terraform.io/docs/providers/aws/r/api_gateway_integration.html

resource "aws_api_gateway_rest_api" "api" {
  name = "letsChatAPI-01"
  description = "Lets Chat Lambda API"
  # Valid values: EDGE, REGIONAL or PRIVATE
  endpoint_configuration {
    types = [
      "REGIONAL"]
  }
}
resource "aws_api_gateway_resource" "resource" {
  path_part = "{proxy+}"
  # To define it's a proxy resource
  parent_id = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

# --- Mock Integration for CORS

resource "aws_api_gateway_method" "options_method" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  depends_on = [
    "aws_api_gateway_method.options_method"]
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  type = "MOCK"
  request_templates = {
    "application/json": "{\"statusCode\": 200}"
  }
  depends_on = [
    "aws_api_gateway_method.options_method"]
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  depends_on = [
    "aws_api_gateway_method_response.options_200"]
}

# --- lambda integration -------------

#https://www.terraform.io/docs/providers/aws/r/api_gateway_method.html
resource "aws_api_gateway_method" "method" {
  # http_method - (Required) The HTTP Method (GET, POST, PUT, DELETE, HEAD, OPTIONS, ANY)
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  # ANY won't work for integration_http_method
  integration_http_method = "POST"
  request_templates = {
    "application/json": "{\"statusCode\": 200}"
  }
  type = "AWS_PROXY"
  # Lambda proxy integration
  uri = aws_lambda_function.lambda_read_dynamoDB.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_read_dynamoDB.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  #  source_arn = "arn:aws:execute-api:${var.region}:${var.accountId}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}

# dploy lambda funciton
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name = "Dev"
  depends_on = [
    "aws_api_gateway_integration.integration"]
}
## --- end API gateway ---------------


###### dynamo db  tables for lambda to read from UNCOMMENT the code below
/*

# ------ start DynamoDB ------------

resource "aws_dynamodb_table" "chat-conv" {
  name = "Chat-Conversations"
  read_capacity = 1
  write_capacity = 1
  hash_key = "ConversationId"
  range_key = "Username"

  attribute {
    name = "ConversationId"
    type = "S"
  }
  attribute {
    name = "Username"
    type = "S"
  }
  global_secondary_index {
    name = "Username-ConversationId-index"
    projection_type = "ALL"
    hash_key = "Username"
    range_key = "ConversationId"
    write_capacity = 1
    read_capacity = 1
  }
}

resource "aws_dynamodb_table" "chat-messages" {
  name = "Chat-Messages"
  read_capacity = 1
  write_capacity = 1
  hash_key = "ConversationId"
  range_key = "Timestamp"

  attribute {
    name = "ConversationId"
    type = "S"
  }
  attribute {
    name = "Timestamp"
    type = "N"
  }
}
# add some sample data

resource "aws_dynamodb_table_item" "chat-messages_01" {
  table_name = aws_dynamodb_table.chat-messages.name
  hash_key = aws_dynamodb_table.chat-messages.hash_key
  range_key = aws_dynamodb_table.chat-messages.range_key

  item = <<ITEM
{
  "${aws_dynamodb_table.chat-messages.hash_key}": {"S": "1"},"${aws_dynamodb_table.chat-messages.range_key}": {"N": "1589307976345"},
  "Sender": {"S": "arun"},
  "Message": {"S": "Hello World! again"}
}
ITEM
}

resource "aws_dynamodb_table_item" "chat-messages_02" {
  table_name = aws_dynamodb_table.chat-messages.name
  hash_key = aws_dynamodb_table.chat-messages.hash_key
  range_key = aws_dynamodb_table.chat-messages.range_key

  item = <<ITEM
{
  "${aws_dynamodb_table.chat-messages.hash_key}": {"S": "2"},"${aws_dynamodb_table.chat-messages.range_key}": {"N": "1589307996345"},
  "Sender": {"S": "neo"},
  "Message": {"S": "Its beautiful world"}
}
ITEM
}


resource "aws_dynamodb_table_item" "chat-conv_01" {
  table_name = aws_dynamodb_table.chat-conv.name
  hash_key = aws_dynamodb_table.chat-conv.hash_key
  range_key = aws_dynamodb_table.chat-conv.range_key

  item = <<ITEM
{
"${aws_dynamodb_table.chat-conv.hash_key}": {"S": "1"},"${aws_dynamodb_table.chat-conv.range_key}": {"S": "arun"}
}
ITEM
}

resource "aws_dynamodb_table_item" "chat-conv_01_01" {
  table_name = aws_dynamodb_table.chat-conv.name
  hash_key = aws_dynamodb_table.chat-conv.hash_key
  range_key = aws_dynamodb_table.chat-conv.range_key

  item = <<ITEM
{
"${aws_dynamodb_table.chat-conv.hash_key}": {"S": "1"},"${aws_dynamodb_table.chat-conv.range_key}": {"S": "Student"}
}
ITEM
}

resource "aws_dynamodb_table_item" "chat-conv_02" {
  table_name = aws_dynamodb_table.chat-conv.name
  hash_key = aws_dynamodb_table.chat-conv.hash_key
  range_key = aws_dynamodb_table.chat-conv.range_key

  item = <<ITEM
{
  "${aws_dynamodb_table.chat-conv.hash_key}": {"S": "2"},"${aws_dynamodb_table.chat-conv.range_key}": {"S": "neo"}
}
ITEM
}
# ------ end DynamoDB ------------

*/
