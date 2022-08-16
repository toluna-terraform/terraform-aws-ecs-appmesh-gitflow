import urllib3
import os

def lambda_handler(event, context):

  # appName = os.getenv('APP_NAME')
  # envName = os.getenv('ENV_NAME')
  url = os.getenv('URL')

  http = urllib3.PoolManager()
  response = http.request('GET', url)    
  print (response.status)
  
  if (response.status == 200):
    return { "is_healthy" : "true" }
  else: 
    return { "is_healthy" : "false" }
