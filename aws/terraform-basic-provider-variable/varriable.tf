variable "bucket_name" {
//  default = "random-bucket-var-demo"  //if not provided will be prompt in execution,or run plan with tfwars, or directly pass the value in plan
  description = "Bucket name for S3"
}

resource "aws_s3_bucket" "variable_s3_bucket" {
//  interpolation syntax
  bucket = var.bucket_name == "" ? "sfsawer": "${var.bucket_name}-23423498920"
}

locals {
  instance_name ="randam"
  instance_type = "t2.micro"
}

//resource "aws_instance" "demo-instance" {
//  ami = "123-adf34"
//  instance_type = local.instance_type
//  tags {
//    Name=local.instance_name
//  }
//}