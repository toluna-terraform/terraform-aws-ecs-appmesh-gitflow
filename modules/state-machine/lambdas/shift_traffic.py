import boto3
import json
import os
import consul

def lambda_handler(event, context):

  appName = os.getenv('APP_NAME')
  envName = os.getenv('ENV_NAME')
  cluster_name = "{app}-{env}".format( app= appName, env = envName )

  connection = consul.Consul(
        host = "consul-cluster-test.consul.06a3e2e2-8cc2-4181-a81b-eb88cb8dfe0f.aws.hashicorp.cloud", 
        port = 80,
        token = "96e58b76-3bf6-c588-9a8a-347f80a751d5",
        scheme = "http"
        )

  session = connection.session.create( behavior = "release", ttl=20 )
  
  current_color_tuple = connection.kv.get( "infra/chef-srinivas/current_color")
  current_color = current_color_tuple[1]["Value"].decode('utf-8')

  if current_color == "green":
    next_color = "blue"
  else:
    next_color = "green"

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
  connection.kv.put( 'infra/{app}-{env}/current_color'.format(app = appName, env = envName) , next_color, acquire=session )
  
  connection.session.destroy(session)
