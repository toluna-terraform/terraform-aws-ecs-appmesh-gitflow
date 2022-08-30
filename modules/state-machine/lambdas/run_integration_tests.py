import urllib3
import os
# from postpy2.core import PostPython

def lambda_handler(event, context):

  # runner = PostPython('./chef.postman_collection2.json')
  # runner = PostPython('https://chef-non-prod-postman-tests.s3.amazonaws.com/srinivas/chef.postman_collection2.json')
  # response = runner.Folder1.get_version()
  # print ( "response status_code = " , response.status_code )
  # if (response.status_code == 200):
  #   return { "is_healthy" : "true" }
  # else: 
  #   return { "is_healthy" : "false" }

  # url = os.getenv('URL')
  url = "https://qa.buffet-non-prod.toluna-internal.com/srinivas/chef"
  http = urllib3.PoolManager()
  response = http.request('GET', url)    
  print (response.status)
  
  if (response.status == 200):
    return { "is_healthy" : "true" }
  else: 
    return { "is_healthy" : "false" }
