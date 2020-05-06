provider "aws" {
  region = "us-east-1"
//  version = ""
}

//create S3 bucket to be used for state manamement
//resource "aws_s3_bucket" "terraform_remote_state_bucket" {
//  bucket = "tf-bucket-neo-23-19-87"
//  region = "us-east-1"
//}
//

// state is saved in remote file

terraform {
  backend "s3" {
    bucket = "tf-bucket-neo-23-19-87"
    key = "tf_remote_state.tfstates"
    region = "us-east-1"
  }
}

resource "aws_security_group" "public_security_group" {
  ingress {
    from_port = 22
    protocol = "TCP"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 22
    protocol = "TCP"
    to_port = 22
    cidr_blocks = ["170.14.14.14/32"]
  }
  tags = {
    name= "tf_aws_sg"
  }
}