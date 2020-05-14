# Terroform basic exmaples to try out. for AWS provider.

#### /terraform-basic-provider-variable
Creating resources
Creating variables
Using Loops

#### /terraform-remote-state-s3
Saving terraform state remotely in S3 bucket.

#### /terraform-resource/terraform-s3-lifecycle-rule
Creating lifecycle rule for S3 bucket

#### /terraform-resource/terraform-s3-website
Creating Static website - 


#### /terraform-upload-multiple-file-directory
Terraform - uploading multiple files in directory/sub-directory in one go.
using fileset and for_each

#### /terraform-api-gateway-with-lmbda-proxy
###Note: uncomment dynamoDB table creation part. 
Terraform 
* Creating API gateway rest api "aws_api_gateway_rest_api"
* Creating aws_api_gateway_resource
* Creating aws_api_gateway_method
* Creating aws_api_gateway_integration
* Creating aws_lambda_permission
* The difficult part making API CORS enable.
    that was little difficult for me to implement, setting proxy , producers, consumers, cors enable.
* LAMBDA proxy enabled
* Deploying the API
* updated lambda function to read from "pathParameter" i.e event.pathParameters.proxy
* Creating DynamoDB tables.
* Generate some sample data to play with.
* Give access to lambda role to communicate with DynamoDB.
* Necessary changes to .js and .html file to read/write conversations from DynamoDB.
* Reading from dynamoDB

#### / terraform-labda-dyanmodb-with-api-gateway 
 ###Note: uncomment dynamoDB table creation part.
 It does what /terraform-api-gateway-with-lmbda-proxy for resource creation
 * The difference it use's API Gateway Requet Flow with Schema Model for response.