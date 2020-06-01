// Main provider file
// Note 1. init for everything !!!Comment out the Backend Config, 2. init for terraform backend setup

provider "aws" {}

terraform {
  backend "s3" {
    bucket         = "data-infra-state"
    key            = "global/s3/airflow.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "infra_state"
    encrypt        = true
  }
}