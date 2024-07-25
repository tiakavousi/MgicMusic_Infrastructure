# MgicMusic_Infrastructure

This project automates the deployment of a Dockerized application to AWS ECS using AWS CodeDeploy for continuous deployment. The infrastructure is defined and managed using Terraform.

related repository : MagicMusic [link text](https://github.com/tiakavousi/MagicMusic.git)

## Architecture

The high-level architecture includes:

- **Amazon ECS:** For running Docker containers.
- **AWS CodeDeploy:** For deploying updates to the ECS service.
- **Terraform:** For defining and provisioning the infrastructure.

## Prerequisites

Before you begin, ensure you have the following:

- AWS account and IAM user with necessary permissions.
- AWS CLI installed and configured.
- Terraform installed.
- Docker installed (for building images locally).
- A Docker Hub account or other container registry.

## Setup Instructions

```sh
git clone https://github.com/yourusername/your-repo.git
cd your-repo
aws configure
cd terraform
terraform init
terraform plan
terraform apply
