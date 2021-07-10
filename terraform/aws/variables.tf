locals {
  service_prefix = "${var.project_name}-${var.env}"
}

variable "project_name" {
  type    = string
  default = "yastani"
}

variable "env" {
  type    = string
  default = "example"
}

variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
