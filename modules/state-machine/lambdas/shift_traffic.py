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

  consulResp = ssmClient.get_parameter(
    Name = "/infra/{app}-{envtype}/consul_project_id".format(app = appName, envtype = envType)
  )
  consulProjId = consulResp["Parameter"]["Value"]

  consulResp = ssmClient.get_parameter(
    Name = "/infra/{app}-{envtype}/consul_http_token".format(app = appName, envtype = envType)
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
  current_color = current_color_tuple[1]["Value"].decode()

  if current_color == "green":
    next_color = "blue"
  else:
    next_color = "green"

  print ("next_color = ", next_color)

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
                        'weight': 0
                    },
                    {
                        'virtualNode': 'vn-{app}-{env}-{color}'.format(app = appName, env = envName, color = next_color),
                        'weight': 100
                    }
                ]
            },
            'match': {
                'prefix': '/'
            }
        }
    }
  )

  # shutdown curent_color tasks
  client = boto3.client("ecs", region_name="us-east-1")
  
  print ("cluster_name = " + cluster_name)
  response = client.update_service(
    cluster = cluster_name,
    service = "{app}-{color}".format(app = appName, color = current_color) ,
    desiredCount = 0
  )
  print( json.dumps(response, indent=4, default=str))

  # update consul key current_color  with next_color
  kv_update_return_code = False
  iteration = 1
  print ("next_color = ", next_color)
  while kv_update_return_code == False : 
    print ("iteration = ", iteration )
    kv_update_return_code = connection.kv.put( 'infra/{app}-{env}/current_color'.format(app = appName, env = envName) , next_color, acquire=session )
    # if kv_update_return_code == False : 
    print ( "kv_update_return_code = ", kv_update_return_code)
    time.sleep (10)
    iteration = iteration + 1
  
  connection.session.destroy(session)
