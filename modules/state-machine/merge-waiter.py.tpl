import json
import boto3

appName = ${APP_NAME}
envName = ${ENV_NAME}

# ---- receive message from SQS
sqsClient = boto3.client('sqs')
message = sqsClient.receive_message(
	QueueUrl="https://sqs.us-east-1.amazonaws.com/603106382807/{app}_{env}_merge_waiter_queue".format(app = appName, env = envName),
	AttributeNames=[ 'All'],
	MessageAttributeNames=[
		'string',
	],
	MaxNumberOfMessages=1,
	VisibilityTimeout=120,
	WaitTimeSeconds=10,
	ReceiveRequestAttemptId='string'
)

# get body from message
bodyStr = message["Messages"][0]["Body"]
print ("bodyStr = ", bodyStr)

# get token from body
receivedTaskToken = json.loads(bodyStr)["TaskToken"]
print ("token =", receivedTaskToken)

# ---- callback SF step
sfClient = boto3.client( "stepfunctions" )
sfCallbackResponse = sfClient.send_task_success(
		taskToken = receivedTaskToken,
		output  = '{ "msg" : "success from lambda" }'
)
print ("SF call back response = ", sfCallbackResponse)