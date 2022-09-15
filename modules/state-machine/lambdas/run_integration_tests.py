import boto3
import json
import os
# import urllib3

def lambda_handler(event, context):

  appName = os.getenv('APP_NAME')
  envName = os.getenv('ENV_NAME')


  lambdaClient = boto3.client("lambda")
  
  lambdaPayloadJson = {
    "deploymentId": "0400baeb-ed0c-4eca-bc8e-435277e876cf",
    "lb_name": "qa.buffet-non-prod.toluna-internal.com",
    "environment": envName,
    "report_group": "arn:aws:codebuild:us-east-1:603106382807:report-group/{app}-{env}-IntegrationTestReport".format(app = appName, env = envName)
  }
  
  lambdaResp = lambdaClient.invoke(FunctionName="{app}-non-prod-integration-runner".format(app = appName), InvocationType='Event', Payload = json.dumps(lambdaPayloadJson) ) 
  
  responseStatusCode =  lambdaResp["StatusCode"]

  if (responseStatusCode == 200  or responseStatusCode == 202 ):
    return { "is_healthy" : "true" }
  else: 
    return { "is_healthy" : "false" }
