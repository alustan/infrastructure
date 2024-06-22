###########################
#--- S3 Backend Bucket ---#
###########################

output "s3_bucket_name" {
  value = module.s3_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  value = module.s3_bucket.s3_bucket_arn
}

#############################
#--- DynamoDB State Lock ---#
#############################

output "dynamodb_name" {
  value = module.dynamodb_table.dynamodb_table_id
}

output "dynamodb_arn" {
  value = module.dynamodb_table.dynamodb_table_arn
}
