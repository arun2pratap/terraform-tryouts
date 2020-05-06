variable "no_of_buckets" {
  default = 1
}
resource "aws_s3_bucket" "my_bucket_002" {
  count = var.no_of_buckets != 0 ? var.no_of_buckets : 1
  bucket = "arun-ternary-tf-7989-e2467"
}

variable "users" {
  default = [
    "batman",
    "neo",
    "naruto"]
}

resource "aws_iam_user" "users" {
  for_each = toset(var.users)
  name = each.value
}

variable "asg_tags" {
  type = map(string)
  default = {
    Name = "ASG_ec2"
    Type = "t2.micro"
    Team = "demo"
  }
}

//Error: One of `launch_configuration`, `launch_template`, or `mixed_instances_policy` must be set for an autoscaling group
resource "aws_autoscaling_group" "dem_auto_scaling_group" {
  max_size = 0
  min_size = 0
  dynamic "tag" {
    for_each = var.asg_tags
    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
    }
  }
}

output "uppercase_heroes" {
  value = [for hero in var.users : upper(hero) if length(hero) < 9]
}

//output "my_s3_bucket" {
//  value = aws_s3_bucket
//}

