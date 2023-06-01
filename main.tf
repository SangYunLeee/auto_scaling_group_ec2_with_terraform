terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "ap-northeast-2"
}

# 현재 호출자, ID 값을 가져오기 위한 데이터
data "aws_caller_identity" "current" {}

# EC2 템플릿 설정
resource "aws_launch_configuration" "as_conf" {
  name_prefix   = "terraform-ec2"
  image_id      = "ami-0970cc54a3aa77466"
  instance_type = "t2.nano"
  # 퍼블릭 IP 생성
  associate_public_ip_address = true
  key_name = var.pair_key
	user_data = <<-EOT
    #!/bin/bash
    echo "Hello, World" > index.html
    sudo apt update
    sudo apt install stress
    nohup busybox httpd -f -p 80 &
  EOT
  security_groups = [aws_security_group.ec2.id]
}

# 오토스케일링 그룹
resource "aws_autoscaling_group" "example" {
  launch_configuration      = aws_launch_configuration.as_conf.name
  vpc_zone_identifier       = module.vpc.public_subnets
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 1
}

# 오토스케일링 정책
resource "aws_autoscaling_policy" "example" {
  name                   = "example-policy"
  # 오토스케일링 그룹 대상
  autoscaling_group_name = aws_autoscaling_group.example.name
  # 정책 타입
  policy_type = "TargetTrackingScaling"

  # 정책 세부 방식
    # 알림: 자동으로 aws_cloudwatch_metric_alarm  리소스가 생성됨
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# SNS Topic 정의
resource "aws_sns_topic" "example" {
  name = "example-topic"
}

# SNS 구독 정의 (이메일 알림)
resource "aws_sns_topic_subscription" "example" {
  topic_arn = aws_sns_topic.example.arn
  protocol  = "email"
  endpoint  = var.email  # 이메일 주소 입력
}

# 오토스케일링 그룹의 상태 정보를 SNS 에 알림
resource "aws_autoscaling_notification" "example_notifications" {
  group_names = [
    aws_autoscaling_group.example.name
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.example.arn
}
