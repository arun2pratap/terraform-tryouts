provider "aws" {
  region = var.region
}

#####
resource "aws_iam_role" "role" {
  name = "dummy-lambda"

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
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_attach_policy_dynamoDB" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda/index.js"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name    = "lets-chat-API_03"
  filename         = "lambda_function.zip"
  handler          = "index.handler"
  role             = aws_iam_role.role.arn
  runtime          = "nodejs12.x"
  source_code_hash = filebase64sha256("lambda/index.js")
}


# --- end lamdba policy/role for  -------

# --- start API gateway ---------------

# https://www.terraform.io/docs/providers/aws/r/api_gateway_integration.html

resource "aws_api_gateway_rest_api" "api" {
  name        = "00lambdaAPI"
  description = "Lets Chat Lambda API"
  # Valid values: EDGE, REGIONAL or PRIVATE
  endpoint_configuration {
    types = [
    "REGIONAL"]
  }
}
resource "aws_api_gateway_resource" "resource" {
  path_part = "conversations"
  # To define it's a proxy resource
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}
# --- lambda integration -------------

#https://www.terraform.io/docs/providers/aws/r/api_gateway_method.html
resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  # ANY won't work for integration_http_method
  integration_http_method = "POST"
  request_templates = {
    "application/json" : "{\"statusCode\": 200}"
  }
  type = "AWS"
  uri  = aws_lambda_function.lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  #  source_arn = "arn:aws:execute-api:${var.region}:${var.accountId}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"
  response_models = {
    "application/json" = aws_api_gateway_model.MyDemoModel.name
  }
}

resource "aws_api_gateway_model" "MyDemoModel" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  name         = "ConverstationList"
  description  = "a JSON schema"
  content_type = "application/json"

  schema = <<EOF
{
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "id": {
        "type": "string"
      },
      "participants": {
        "type": "array",
        "items": {
          "type": "string"
        }
      },
      "last": {
        "type": "number",
        "format": "utc-millisec"
      }
    }
  }
}
EOF
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code
}

# create another child resource

resource "aws_api_gateway_resource" "resource_conv" {
  path_part = "{id}"
  parent_id   = aws_api_gateway_resource.resource.id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method_conv_GET" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource_conv.id
  http_method   = "GET"
  authorization = "NONE"
}
resource "aws_api_gateway_method" "method_conv_POST" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource_conv.id
  http_method   = "POST"
  authorization = "NONE"
}
##############

# --- Mock Integration for CORS

resource "aws_api_gateway_method" "method_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "response_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method_cors.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration" "integration_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method_cors.http_method
  type = "MOCK"
  request_templates = {
    "application/json": "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "integration_res_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method_cors.http_method
  status_code = aws_api_gateway_method_response.response_cors.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}
############
# dploy lambda funciton
//resource "aws_api_gateway_deployment" "deployment" {
//  rest_api_id = aws_api_gateway_rest_api.api.id
//  stage_name  = "test"
//  lifecycle {
//    create_before_destroy = true
//  }
//  depends_on = [aws_api_gateway_resource.resource ]
//}

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
