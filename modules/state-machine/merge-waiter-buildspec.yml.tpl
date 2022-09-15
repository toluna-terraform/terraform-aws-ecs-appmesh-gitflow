version: 0.2

phases:
  pre_build:
    commands:
      - yum update -y
      - python3 -V
      - pip3 -V
      - pip3 show boto3
      - aws --version
      - aws s3 cp s3://s3-${APP_NAME}-${ENV_TYPE}/${APP_NAME}-${ENV_NAME}-merge-waiter.py .
      - echo "installation and copy of sources completed."
  build:
    commands:
      - python3 ${APP_NAME}-${ENV_NAME}-merge-waiter.py
      - echo "return_code = " $?
      - echo "merge-waiter script executed."
  post_build:
    commands:
      - echo "post_build commands completed."