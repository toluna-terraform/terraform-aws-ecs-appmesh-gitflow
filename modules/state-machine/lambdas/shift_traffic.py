import boto3
import json
import os
import consul

def lambda_handler(event, context):

  appName = os.getenv('APP_NAME')
  envName = os.getenv('ENV_NAME')
  cluster_name = "{app}-{env}".format( app= appName, env = envName )

  # getting current_color
  # ssm_client = boto3.client("ssm", region_name="us-east-1")
  # ssm_resonse = ssm_client.get_parameter    (
  #   Name = '/infra/{app}-{env}/current_color'.format(app = appName, env = envName)
  # )
  # currentColor = ssm_resonse["Parameter"]["Value"]
  
  c = consul.Consul(
        host = "consul-cluster-test.consul.06a3e2e2-8cc2-4181-a81b-eb88cb8dfe0f.aws.hashicorp.cloud", 
        port = 80,
        token = "96e58b76-3bf6-c588-9a8a-347f80a751d5",
        scheme = "http"
        )
  current_color_json = c.kv.get( "infra/chef-srinivas/current_color")
  currentColor = current_color_json[1]["Value"].decode('utf-8')


  if currentColor == "green":
    nextColor = "blue"
  else:
    nextColor = "green"

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
                        'virtualNode': 'vn-{app}-{env}-{color}'.format(app = appName, env = envName, color = currentColor) ,
                        'weight': 0
                    },
                    {
                        'virtualNode': 'vn-{app}-{env}-{color}'.format(app = appName, env = envName, color = nextColor),
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

  # --- shutdown current previous color tasks after traffic switch
  client = boto3.client("ecs", region_name="us-east-1")
  
  print ("cluster_name = " + cluster_name)

  # shutdown curent_color tasks
  response = client.update_service(
    cluster = cluster_name,
    service = "{app}-{color}".format(app = appName, color = currentColor) ,
    desiredCount = 0
  )
  print( json.dumps(response, indent=4, default=str))

  # update current_color  with next_color

  # ssm_resonse = ssm_client.put_parameter(
  #   Name = '/infra/{app}-{env}/current_color'.format(app = appName, env = envName),
  #   Value = nextColor,
  #   Overwrite = True
  # )
  
  c.kv.put( 'infra/chef-srinivas/current_color', nextColor )

  
  
