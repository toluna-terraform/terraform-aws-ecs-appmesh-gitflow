import boto3
import json
import os

def lambda_handler(event, context):

  appName = os.getenv('APP_NAME')
  envName = os.getenv('ENV_NAME')
  cluster_name = '{app}-{env}'.format(app = appName, env = envName)

  # getting current_color
  ssm_client = boto3.client("ssm", region_name="us-east-1")
  ssm_resonse = ssm_client.get_parameter    (
    Name = '/infra/{app}-{env}/current_color'.format(app = appName, env = envName)
  )
  currentColor = ssm_resonse["Parameter"]["Value"]
  
  if currentColor == "green":
    nextColor = "blue"
  else:
    nextColor = "green"


  # --- shutdown current next color tasks after traffic switch
  client = boto3.client("ecs", region_name="us-east-1")

  # shutdown next_color tasks
  response = client.update_service(
    cluster = cluster_name,
    service = "{app}-{color}".format(app = appName, color = nextColor) ,
    desiredCount = 0
  )
  print( json.dumps(response, indent=4, default=str))

