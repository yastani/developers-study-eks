locals {
  lb_external_web_name                      = substr(replace("${local.service_prefix}_external_web", "_", "-"), 0, 32)
  lb_external_tg_web_name                   = substr(replace("${local.service_prefix}_external_web_tg", "_", "-"), 0, 255)
  lb_external_sg_web_name                   = substr(replace("${local.service_prefix}_external_web_sg", "_", "-"), 0, 255)
  s3_bucket_lb_external_web_access_log_name = substr(replace("${local.service_prefix}_external_web_access_log", "_", "-"), 0, 255)
}

##################################################
# Data
##################################################
data "aws_elb_service_account" "current" {}

##################################################
# Security Group
##################################################
resource "aws_security_group" "lb_external_web" {
  name_prefix = local.lb_external_sg_web_name
  vpc_id      = module.vpc_main.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = local.lb_external_sg_web_name }
}

data "aws_iam_policy_document" "lb_external_web_access_logs" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.lb_external_web_access_logs.arn}/*"]

    principals {
      identifiers = [data.aws_elb_service_account.current.arn]
      type        = "AWS"
    }
  }
}

resource "aws_s3_bucket" "lb_external_web_access_logs" {
  bucket = local.s3_bucket_lb_external_web_access_log_name
  acl    = "log-delivery-write"

  tags = { Name = local.lb_external_web_name }
}

resource "aws_s3_bucket_policy" "lb_external_web_access_logs" {
  bucket = local.s3_bucket_lb_external_web_access_log_name
  policy = data.aws_iam_policy_document.lb_external_web_access_logs.json
}

resource "aws_s3_bucket_public_access_block" "lb_external_web_access_logs" {
  bucket                  = aws_s3_bucket.lb_external_web_access_logs.bucket
  ignore_public_acls      = true
  block_public_acls       = true
  restrict_public_buckets = true
  block_public_policy     = true
}

module "lb_external_web" {
  depends_on = [
    aws_s3_bucket.lb_external_web_access_logs,
    aws_s3_bucket_policy.lb_external_web_access_logs
  ]

  source  = "terraform-aws-modules/alb/aws"
  version = "6.0.0"

  name                       = local.lb_external_web_name
  load_balancer_type         = "application"
  vpc_id                     = module.vpc_main.vpc_id
  security_groups            = [aws_security_group.lb_external_web.id]
  subnets                    = module.vpc_main.public_subnets
  enable_deletion_protection = true

  access_logs = {
    bucket = local.s3_bucket_lb_external_web_access_log_name
  }

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
      action_type        = "forward"
    }
  ]

  target_groups = [
    {
      name                 = local.lb_external_tg_web_name
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "ip"
      deregistration_delay = 30
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = 200
      }
      protocol_version = "HTTP1"
    }
  ]
}
