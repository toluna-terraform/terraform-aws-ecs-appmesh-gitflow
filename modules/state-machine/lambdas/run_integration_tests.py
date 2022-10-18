import boto3
import json
import os
# import urllib3

def lambda_handler(event, context):

  appName = os.getenv('APP_NAME')
  envName = os.getenv('ENV_NAME')
  envType = os.getenv('ENV_TYPE')
  AwsAcctId = os.getenv('AWS_ACCOUNT_ID')



  lambdaClient = boto3.client("lambda")
  
  lambdaPayloadJson = {
    "deploymentId": "0400baeb-ed0c-4eca-bc8e-435277e876cf",
    "lb_name": "qa.buffet-non-prod.toluna-internal.com",
    "environment": envName,
    "report_group": "arn:aws:codebuild:us-east-1:{aws_acct_id}:report-group/{app}-{env}-IntegrationTestReport".format(aws_acct_id = AwsAcctId, app = appName, env = envName)
  }
  
  runIntegrationTests = os.getenv('RUN_INTEGRATION_TESTS')
  print ("runStressTests = ", runIntegrationTests)
  
  if (runIntegrationTests == "false" ):
     return { "is_healthy" : "true" }

  lambdaResp = lambdaClient.invoke(FunctionName="{app}-{env}-integration-runner".format(app = appName, env = envType), InvocationType='Event', Payload = json.dumps(lambdaPayloadJson) ) 
  
  responseStatusCode =  lambdaResp["StatusCode"]

  if (responseStatusCode == 200  or responseStatusCode == 202 ):
    return { "is_healthy" : "true" }
  else: 
    return { "is_healthy" : "false" }
