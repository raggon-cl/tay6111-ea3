# variables.tf

variable "aws_region" {
  description = "Región de AWS para desplegar la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Bloque CIDR para la VPC principal"
  type        = string
  default     = "10.100.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Lista de bloques CIDR para las subnets públicas"
  type        = list(string)
  default     = ["10.100.1.0/24", "10.100.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Lista de bloques CIDR para las subnets privadas"
  type        = list(string)
  default     = ["10.100.101.0/24", "10.100.102.0/24"]
}

variable "availability_zones" {
  description = "Lista de Zonas de Disponibilidad a utilizar"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "Tipo de instancia para el servidor web"
  type        = string
  default     = "t2.micro"
}

variable "ebs_volume_size_gb" {
  description = "Tamaño del volumen EBS en GiB"
  type        = number
  default     = 8
}
