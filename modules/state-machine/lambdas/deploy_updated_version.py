import boto3
import json
import os
import consul

def lambda_handler(event, context):

  appName = os.getenv('APP_NAME')
  envName = os.getenv('ENV_NAME')

  c = consul.Consul(
        host = "consul-cluster-test.consul.06a3e2e2-8cc2-4181-a81b-eb88cb8dfe0f.aws.hashicorp.cloud", 
        port = 80,
        token = "96e58b76-3bf6-c588-9a8a-347f80a751d5",
        scheme = "http"
        )
  current_color_json = c.kv.get( "infra/{app}-{env}/current_color".format(app = appName,env = envName))
  currentColor = current_color_json[1]["Value"].decode('utf-8')

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


