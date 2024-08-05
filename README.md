# MgicMusic_Infrastructure

This project IS THE infrastructure and deployment of a Dockerized application to AWS EKS. The infrastructure is defined and managed using Terraform.

related repository : MagicMusic [https://github.com/tiakavousi/MagicMusic.git](https://github.com/tiakavousi/MagicMusic.git)

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

export AWS_SECRET_ACCESS_KEY="XXXXXX"

export AWS_ACCESS_KEY_ID="XXXXXX"


terraform apply -auto-approve -var-file=production.tfvars

aws eks describe-cluster --name eks_cluster-default

kubectl apply -f configmap.yaml
kubectl apply -f magicmusic-deployment-prod.yaml
kubectl apply -f magicmusic-deployment-qa.yaml

terraform destroy -var-file=production.tfvars

```