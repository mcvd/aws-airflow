// Definition of Terra Backend
// Resources S3 + Dynamo Table

// AWS S3
//resource "aws_s3_bucket" "terraform_state" {
//  bucket = "data-infra-state"
//  region = var.AWS_REGION
//  // Enable for Revision purposes
//  versioning {
//    enabled = true
//  }
//  // Prevent accidental deletion when "terraform destroy" on all resources
//  lifecycle {
//    prevent_destroy = true
//  }
//  // AES256 on Server Side
//  server_side_encryption_configuration {
//    rule {
//      apply_server_side_encryption_by_default {
//        sse_algorithm = "AES256"
//      }
//    }
//  }
//  tags = {
//    Name = var.TAG
//  }
//}
//
//// AWS DynamoTable
//resource "aws_dynamodb_table" "terraform_state_locks" {
//  hash_key     = "LockID"
//  name         = "infra_state"
//  billing_mode = "PAY_PER_REQUEST"
//  attribute {
//    name       = "LockID"
//    type       = "S"
//  }
//  lifecycle {
//    prevent_destroy = true
//  }
//  tags = {
//    Name = var.TAG
//  }
//}
//
