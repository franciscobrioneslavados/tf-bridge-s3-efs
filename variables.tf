
variable "aws_region" {
  description = "aws region"
}

variable "vpc_cidr" {
  description = "default CIDR range of the VPC"
}

variable "availability_zone" {
  description = "Zona de disponibilidad"
}

variable "environment" {
  description = "aws environment"
  type        = string
}

variable "force_destroy_bucket" {
  description = "force destroy bucket when deleting, use with caution, not recommended for production"
  type        = bool
}

variable "managed_by" {
  description = "value for the ManagedBy tag"
  type        = string
}

variable "owner" {
  description = "value for the Owner tag"
  type        = string
}

variable "project" {
  description = "value for the Project tag"
  type        = string
}

variable "function_name" {
  description = "Nombre de la función Lambda"
}