import boto3
import json
import os
import time
import consul

def lambda_handler(event, context):

  appName = os.getenv('APP_NAME')
  envName = os.getenv('ENV_NAME')
  envType = os.getenv('ENV_TYPE')
  cluster_name = "{app}-{env}".format( app= appName, env = envName )

  ssmClient = boto3.client('ssm')

  consulResp = ssmClient.get_parameter(  Name = "/infra/consul_url"  )
  consulUrl = consulResp["Parameter"]["Value"]

  consulResp = ssmClient.get_parameter(
    Name = "/infra/{app}-{envtype}/consul_http_token".format(app = appName, envtype = envType),
    WithDecryption=True
  )
  consulHttpToken = consulResp["Parameter"]["Value"]

  connection = consul.Consul(
        host = consulUrl , 
        port = 443,
        token = consulHttpToken,
        scheme = "https"
        )

  session = connection.session.create( behavior = "release", ttl=20 )
  
  # previous color is already changed in SF. Hence, keep current_color tasks
  current_color_tuple = connection.kv.get( "infra/{app}-{env}/current_color".format(app = appName, env = envName))
  current_color = current_color_tuple[1]["Value"].decode()

  if current_color == "green":
    previous_color = "blue"
  else:
    previous_color = "green"

  print ("previous_color = ", previous_color)

  # --- switch traffic at appmesh route
  client = boto3.client("appmesh", region_name="us-east-1")
  response = client.update_route (
    meshName = os.getenv('MESH_NAME'), 
    meshOwner = os.getenv('MESH_OWNER'),
    virtualRouterName = "vr-{app}-{env}".format(app = appName, env = envName) ,
    routeName = "route-{app}-{env}".format(app = appName, env = envName) , 
    spec= {
        'httpRoute': {
            'action': {
                'weightedTargets': [
                    {
                        'virtualNode': 'vn-{app}-{env}-{color}'.format(app = appName, env = envName, color = current_color) ,
                        'weight': 100
                    },
                    {
                        'virtualNode': 'vn-{app}-{env}-{color}'.format(app = appName, env = envName, color = previous_color),
                        'weight': 0
                    }
                ]
            },
            'match': {
                'prefix': '/'
            }
        }
    }
  )

  # shutdown previous_color tasks
  client = boto3.client("ecs", region_name="us-east-1")
  
  print ("cluster_name = " + cluster_name)
  response = client.update_service(
    cluster = cluster_name,
    service = "{app}-{env}-{color}".format(app = appName, env = envName, color = previous_color) ,
    desiredCount = 0
  )
  print( json.dumps(response, indent=4, default=str))

  connection.session.destroy(session)
