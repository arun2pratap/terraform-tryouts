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
 * Modular lambda function, per lambda function per operation
 * API gateway configured for each lambda function, and javascript function's for the same.
 * Using request and response model - to set schema that we accept.
 * Use velocity parameter read's path variable and generate param as needed.
 ```javascript
     passthrough_behavior = "WHEN_NO_TEMPLATES"
     request_templates = {
       "application/json" :  "#set($inputRoot = $input.path('$'))    {    \"id\": \"$input.params('id')\",    \"message\": \"$inputRoot\"  }"
     }
```
* Deploying the same, It does give some exception because terraform was not able to deploy that in the right sequence, had to give depends_on = [] tag to control that behaviour.

* Downloading api gateway SDK from  STAGE -> generator generator- and will use that in our script's
* ##### Preparing for cognito , removing hardcorded value fo 'Student' from .js files and updating the reuquest_templates for the same. 
* 
  "application/json" : <<EOF
{
  "cognitoUsername":"Student"
}
EOF

request_templates = {
    #    "application/json" :  "#set($inputRoot = $input.path('$'))    {    \"id\": \"$input.params('id')\",    \"message\": \"$inputRoot\"  }"
    "application/json" :  <<EOF
  #set($inputRoot = $input.path('$'))
  {
      "id": "$input.params('id')",
      "message": "$inputRoot",
      "cognitoUsername": "Student"
  }
EOF
  }
  
  * creating cognito user pool
    * Lmabda function for the same read user's
    * Attaching cognito read policy to lambda  
    * API gateway configuration for the same
  * Another lambda function to post conversation to DynamoDB
    * API gateway configuration for the same.
   
  * npm install --save amazon-cognito-identity-js
    * copy node_modules\amazon-cognito-identity-js\dist\amazon-cognito-identity.min.js to our /js/ folder
  
  * Update Config.js with 
  ```javascript
var poolData = {
    UserPoolId: 'us-east-1_f5W2BETw2',
    ClientId: '4nffgdp2be4ansrgrkd5qnflht'
};
```
* create a cognito authorizer for API.
* updated all the API Gateway's to use Cognito authentication.
   
   
Note: Though everything has been changed updated in repository, for purpose of note.
* Update Config.js with 
    ```javascript
  var poolData = {
      UserPoolId: 'us-east-1_f5W2BETw2',
      ClientId: '4nffgdp2be4ansrgrkd5qnflht'
  };
  ```
* npm install --save amazon-cognito-identity-js
    * copy node_modules\amazon-cognito-identity-js\dist\amazon-cognito-identity.min.js to our /js/ folder
* Chat-Conversation-POST. //  const uuidV4 = require('uuid/v4'); // doesnot work's.
    * isntead use context.awsRequestId; // it's unique.
* Chat-Users-GET.js // update UserPoolId: 'us-east-1_Se3DtD5Ze',
* Downloading api gateway SDK from  STAGE -> generator generator- and will use that in our script's. In site.js now can use use apiGateWayClient instead of using gateway endpoint.
  * Put in the apiGateway-js-sdk in /js/ folder.
  * apiGateway-js-sdk/appClient.js -- replace parseParametersToObject(params, [])) with parseParametersToObject(params, ["id"]))
  * apiGateway-js-sdk/readme.md - the include .js files need to be included in .HTML * chats.html, chat.html