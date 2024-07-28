variable "aws_access_key" {
    description = "The IAM public access key"
}

variable "aws_secret_key" {
    description = "IAM secret access key"
}

variable "aws_region" {
    description = "The AWS region things are created in"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnet_1_cidr" {
  description = "CIDR block for the first public subnet"
  type        = string
}

variable "subnet_2_cidr" {
  description = "CIDR block for the first public subnet"
  type        = string
}

variable "availability_zone_1" {
  description = "Availability zone for the first public subnet"
  type        = string
  
}

variable "availability_zone_2" {
  description = "Availability zone for the second public subnet"
  type        = string
}

variable "backend_container_image" {
  description = "Docker image for the backend container"
  type        = string
}

variable "frontend_container_image" {
  description = "Docker image for the frontend container"
  type        = string
}

variable "db_container_image" {
  description = "Docker image for the database container"
  type        = string
}

# variable "sqlalchemy_database_uri" {
#   description = "Database connection string for SQLAlchemy"
#   type        = string
# }

variable "mysql_root_password" {
  description = "Root password for the MySQL database"
  type        = string
}

variable "mysql_user" {
  description = "User for the MySQL database"
  type        = string
}

variable "mysql_password" {
  description = "Password for the MySQL database user"
  type        = string
}

variable "mysql_database" {
  description = "Database name for the MySQL database"
  type        = string
}

