# terraform-aws-ecs-appmesh-gitflow

This modules for for gitflow of AWS ECS style applications using App Mesh

### What is this repository for? ###

* Quick summary

This module helps implement gitflow in ECS style applications that use App Mesh. 



### How do I get set up? ###

* Summary of set up

This module should be included as part of applications. Usually will be called from terraform/app/pipeline.tf files, with parameters as follows: 


**General Parameters**

`from_env`

`env_name`

`app_name`

`env_type`

`pipeline_branch`

`appmesh_owner`

`appmesh_name`

`appmesh_profile`

`namespace`

`source_repository`

`trigger_branch`

`pipeline_type`

`dockerfile_path`

`enable_jira_automation`


**ECS related parameters**


`ecr_registry_id`

`ecr_repo_name`

`ecr_repo_url`

`task_def_name`

**Testing Parameters**

`run_integration_tests`

`ecs_iam_roles_arns`

* Dependencies

For this module to provide required functionality to application that includes it, it should have teh followgn modules included: 


* ECS with appmesh
* Test Framework
* Controller
with compatible versions

***Consul Parameters***
 * infra/mesh-orc/current_color

***SSM Parameter Configuration***
  * Parameters required for accessing CONSUL: /infra/<app_name>/consul_proj_id and /infra/<app_name>/consul_token
  * /infra/<app_name>/hook_execution_id
  * /infra/<app_name>/deployment_id
  * /infra/<app_name>/merge_waiter_seconds - allows configuring wait time for merge to happen



