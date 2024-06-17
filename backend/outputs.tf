###########################
#--- S3 Backend Bucket ---#
###########################

output "s3_bucket_name" {
  value = module.remote-state-s3-dynamodb-backend.tf_state_s3_bucket_name
}

output "s3_bucket_arn" {
  value = module.remote-state-s3-dynamodb-backend.tf_state_s3_bucket_arn
}

#############################
#--- DynamoDB State Lock ---#
#############################

output "dynamodb_name" {
  value = module.remote-state-s3-dynamodb-backend.tf_state_dynamodb_name
}

output "dynamodb_arn" {
  value =  module.remote-state-s3-dynamodb-backend.tf_state_dynamodb_arn
}