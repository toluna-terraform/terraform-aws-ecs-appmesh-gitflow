import boto3
import json
import os
import consul

def lambda_handler(event, context):

  appName = os.getenv('APP_NAME')
  envName = os.getenv('ENV_NAME')
  envType = os.getenv('ENV_TYPE')
  cluster_name = '{app}-{env}'.format(app = appName, env = envName)

  ssmClient = boto3.client('ssm')
  consulResp = ssmClient.get_parameter(
    Name = "/infra/{app}-{envtype}/consul_project_id".format(app = appName, envtype = envType), 
    WithDecryption=True
  )
  consulProjId = consulResp["Parameter"]["Value"]

  consulResp = ssmClient.get_parameter(
    Name = "/infra/{app}-{envtype}/consul_http_token".format(app = appName, envtype = envType),
    WithDecryption=True
  )
  consulHttpToken = consulResp["Parameter"]["Value"]

  connection = consul.Consul(
      host = "consul-cluster-test.consul.{proj}.aws.hashicorp.cloud".format(proj = consulProjId) , 
      port = 80,
      token = consulHttpToken,
      scheme = "http"
  )

  session = connection.session.create( behavior = "release", ttl=20 )
  current_color_tuple = connection.kv.get( "infra/{app}-{env}/current_color".format(app = appName, env = envName))
  currentColor = current_color_tuple[1]["Value"].decode()

  if currentColor == "green":
    nextColor = "blue"
  else:
    nextColor = "green"
  print ("currentColor = " + currentColor)

  # --- shutdown current next color tasks 
  client = boto3.client("ecs", region_name="us-east-1")

  # shutdown next_color tasks
  response = client.update_service(
    cluster = cluster_name,
    service = "{app}-{color}".format(app = appName, color = nextColor) ,
    desiredCount = 0
  )
  print( json.dumps(response, indent=4, default=str))

