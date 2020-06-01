// Variables for Apache Airflow Deployment

variable "AWS_REGION" {}
variable "hosted_zone_name" {}
//variable "AWS_AVAILABILITY_ZONES" {}

variable "PROJECT" {
  type        = string
  default     = "airflow"
  description = "Default IaC Airflow Tag"
}

variable "TAG" {
  type        = string
  default     = "airflow"
  description = "Default IaC Airflow Tag"
}

variable "ENV" {
  type        = string
  default     = "dev"
  description = "Environment name"
}

variable "IP_RANGE" {
  type        = string
  default     = "10.0.0.0/16"
  description = "The default VPC's ip range"
}

// ECS service vars
variable "webserver_count" {
  default = 1
  type = number
  description = "Webserver service count"
}

variable "webserver_port" {
  default = 8080
  type = number
  description = "Webserver service count"
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "1024"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "2048"
}