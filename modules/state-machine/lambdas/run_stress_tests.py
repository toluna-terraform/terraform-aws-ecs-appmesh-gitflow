import boto3
import json
import os

def lambda_handler(event, context):

  appName = os.getenv('APP_NAME')
  envName = os.getenv('ENV_NAME')
  envType = os.getenv('ENV_TYPE')

  runStressTests = os.getenv('RUN_STRESS_TESTS')
  print ("runStressTests = ", runStressTests)
  
  if (runStressTests == "false" ):
     return { "is_healthy" : "true" }

  lambdaClient = boto3.client("lambda")
  
  lambdaPayloadJson = {
    "deploymentId": "dummy-deployment-id",
    "hookId": "eyJlbmNyeXB0ZWREYXRhIjoiUmRzQXo5eFBpbGRkTXU4RThlZG1TdGc4emFaalBzVVYvcWJWQVVSYnFBRlhMUnVyUG9oQXQxRGNwcHhwcXNiSnRJVzN1V3BFS0FyQVNtOEMxMldsc2NBemNFd2tKRG5zalZaN3dGTGFiVk40Y2h1Mk1sS2tQZW1sQzFJR3lvblJ0dDV4VnJGN3BKQk1SZz09IiwiaXZQYXJhbWV0ZXJTcGVjIjoiSURXZ28vWVN1b3o5RWFkNCIsIm1hdGVyaWFsU2V0U2VyaWFsIjoxfQ==",
    "lb_name": "qa.buffet-non-prod.toluna-internal.com",
    "port": "443",
    "environment": "{env}".format(env = envName),
    "trigger": "{app}-{env_type}-test-framework-manager".format(app = appName, env_type = envType),
    "report_group": "arn:aws:codebuild:us-east-1:603106382807:report-group/{app}-{env}-StressTestReport".format( app = appName, env = envName)
  }
  
  lambdaResp = lambdaClient.invoke(FunctionName="{app}-{env_type}-stress-runner".format(app = appName, env_type = envType), InvocationType='Event', Payload = json.dumps(lambdaPayloadJson) ) 
 
  responseStatusCode =  lambdaResp["StatusCode"]

  if (responseStatusCode == 200  or responseStatusCode == 202 ):
    return { "is_healthy" : "true" }
  else: 
    return { "is_healthy" : "false" }
