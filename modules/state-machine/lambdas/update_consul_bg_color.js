const AWS = require('aws-sdk');
const ssm = new AWS.SSM({apiVersion: '2014-11-06', region: 'us-east-1' });
const Consul = require('consul-kv');

let appName = process.env.APP_NAME;
let envName = process.env.ENV_NAME;
let envType = process.env.ENV_TYPE;
let consulProjId = '06a3e2e2-8cc2-4181-a81b-eb88cb8dfe0f' ;

exports.handler = async function () {
  let current_color;
  let next_color;

  // get consul proj Id and token from SSM parameters
  var consulProjIdSsm = {     
    Name: `/infra/${appName}-${envType}/consul_project_id`,
    WithDecryption: false
  };
  const  consul_project_id = await ssm.getParameter(consulProjIdSsm).promise();
  console.log("consul_project_id = " + String(consul_project_id) );

  var consulHttpTokenSsm = {
    Name: `/infra/${appName}-${envType}/consul_http_token`, 
    WithDecryption: false
  };
  const  consul_token =  await ssm.getParameter(consulHttpTokenSsm).promise();
      //.then(data => data.Parameters.length ? data.Parameters[0].Value : Promise.reject(new Error(`SSM Parameter ${name} is not set.`)));;
  console.log("consul_token = " + consul_token);

  var consul = new Consul({
    host: `consul-cluster-test.consul.${consulProjId}.aws.hashicorp.cloud` ,
    // host: 'consul-cluster-test.consul.06a3e2e2-8cc2-4181-a81b-eb88cb8dfe0f.aws.hashicorp.cloud' ,
    port: 443 ,
    token: '96e58b76-3bf6-c588-9a8a-347f80a751d5'
  });
  console.log("consul = " + consul);

  await consul.get(`infra/${appName}-${envName}/current_color`)
  .then(result => {
    console.log(result.value); // the key's value; undefined if it doesn't exist
    current_color = result.value;
    console.log("current_color = " + current_color);
    console.log(result.responseStatus); // the HTTP status code of the Consul response
    console.log(result.responseBody); // the HTTP body of the Consul response
    }, rejectedErr => {
    console.log("rejectedErr = " + rejectedErr);
  });

  if ( current_color == 'green')
     next_color = 'blue';
  else
     next_color = "green";
  console.log("current_color = " + current_color);
  console.log("next_color = " + next_color);

  console.log("starting consul.set() to set or update value for a key ........")
  await consul.set(`infra/${appName}-${envName}/current_color`, next_color)
    .then(respBody => {
      console.log(respBody);
    }, rejectedErr => {
      console.log(rejectedErr);
  });
}


