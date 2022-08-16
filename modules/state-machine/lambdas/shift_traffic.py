import boto3
import json
import os

def lambda_handler(event, context):

  appName = os.getenv('APP_NAME')
  envName = os.getenv('ENV_NAME')
  cluster_name = "{app}-{env}".format( app= appName, env = envName )

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

  # --- switch traffic at appmesh route
  client = boto3.client("appmesh", region_name="us-east-1")
  response = client.update_route (
    meshName = os.getenv('MESH_NAME'), 
    meshOwner = os.getenv('MESH_OWNER')
    virtualRouterName = "vr-{app}-{env}".format(app = appName, env = envName),
    routeName = "route-{app}-{env}".format(app = appName, env = envName), 
    spec= {
        'httpRoute': {
            'action': {
                'weightedTargets': [
                    {
                        'virtualNode': 'vn-{app}-{env}-{color}'.format(app = appName, env = envName, color = currentColor),
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

  # update current_color 
  ssm_resonse = ssm_client.put_parameter(
    Name = '/infra/{app}-{env}/current_color'.format(app = appName, env = envName),
    Value = nextColor,
    Overwrite = True
  )
