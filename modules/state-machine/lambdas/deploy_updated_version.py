import boto3
import json
import os
import consul
import time

def lambda_handler(event, context):

  appName = os.getenv('APP_NAME')
  envName = os.getenv('ENV_NAME')
  envType = os.getenv('ENV_TYPE')

  # getting consul proj id, and token from SSM
  ssm_client = boto3.client("ssm", region_name="us-east-1")

  ssm_resonse = ssm_client.get_parameter ( Name = "/infra/{app}-{envtype}/consul_project_id".format(app = appName, envtype = envType)  )
  consulProjId = ssm_resonse["Parameter"]["Value"]

  ssm_resonse = ssm_client.get_parameter ( Name = "/infra/{app}-{envtype}/consul_http_token".format(app = appName, envtype = envType)  )
  consulToken = ssm_resonse["Parameter"]["Value"]

  # getting current_color
  c = consul.Consul(
        host = "consul-cluster-test.consul.{projId}.aws.hashicorp.cloud".format(projId = consulProjId) , 
        port = 80,
        token = consulToken,
        scheme = "http"
        )
  current_color_json = c.kv.get( "infra/chef-srinivas/current_color")
  currentColor = current_color_json[1]["Value"].decode('utf-8')
  print ("currentColor = " + currentColor)

  if currentColor == "green":
    nextColor = "blue"
  else:
    nextColor = "green"

  # deploying updated version
  client = boto3.client("ecs", region_name="us-east-1")
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

  # allowing time to stabilizing ECS tasks booted above
  time.sleep(120)

  # --- change Route in test VR to next_color so that, 
  # integ tests and stress tests will happen in the test VR route
  client = boto3.client("appmesh", region_name="us-east-1")
  response = client.update_route (
    meshName = os.getenv('MESH_NAME'), 
    meshOwner = os.getenv('MESH_OWNER'),
    virtualRouterName = "vr-{app}-{env}-test".format(app = appName, env = envName) ,
    # this is name of test route used only for tests
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
