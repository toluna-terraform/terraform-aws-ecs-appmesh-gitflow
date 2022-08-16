import boto3
import json
import os

def lambda_handler(event, context):

  appName = os.getenv('APP_NAME')
  envName = os.getenv('ENV_NAME')

  # getting current_color
  ssm_client = boto3.client("ssm", region_name="us-east-1")
  ssm_resonse = ssm_client.get_parameter (
    Name = "/infra/{app}-{env}/current_color".format(app = appName, env = envName)
  )
  currentColor = ssm_resonse["Parameter"]["Value"]

  # deploying updated version
  client = boto3.client("ecs", region_name="us-east-1")
  if currentColor == "green":
    nextColor = "blue"
  else:
    nextColor = "green"

  cluster_name = "{app}-{env}".format(app = appName, env = envName)
  print ("cluster_name = " + cluster_name)


  # start next_color tasks
  response = client.update_service(
    cluster = cluster_name,
    service = "{app}-{color}".format(app = appName, color = nextColor) ,
    desiredCount = 3,
    # updating taskdef
    taskDefinition = "{app}-{env}-{color}".format(app = appName, env = envName, color = nextColor) 
  )


