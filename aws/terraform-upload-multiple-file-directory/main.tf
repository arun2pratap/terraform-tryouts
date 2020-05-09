#terraform {
#  required_providers {
#    aws = "2.26.0"
#  }
#  required_version = "0.12.8"
#}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "test" {
  acl           = "private"
  bucket = var.bucket_name
}

resource "aws_s3_bucket_object" "test" {
  for_each = fileset(path.module, "web-app/**")

  bucket = aws_s3_bucket.test.bucket
  key    = each.value
  source = "${path.module}/${each.value}"
}

output "fileset-results" {
  value = fileset(path.module, "web-app/**")
}