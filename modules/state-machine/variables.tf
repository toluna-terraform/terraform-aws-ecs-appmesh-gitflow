variable "env_name" {
  type = string
}

variable "env_type" {
  type = string
}

variable "app_name" {
  type = string
}

variable "appmesh_owner" {
    type = string
}

variable "appmesh_name" {
    type = string
}

variable "run_integration_tests" {
    type = bool
    default = false
}

variable "run_stress_tests" {
    type = bool
    default = false
}
