provider "aws" {
  region = var.region
}

module "network" {
  source              = "./network"
  vpc_name            = var.vpc_name
  vpc_cidr            = var.vpc_cidr
  eks_cluster_name    = var.eks_cluster_name
  cidr_block_igw      = var.cidr_block_igw
}

module "eks_cluster" {
  source              = "./eks/eks_cluster"
  cluster_name        = var.eks_cluster_name
  public_subnets      = module.network.aws_subnets_public
  private_subnets     = module.network.aws_subnets_private
} 

module "fargate" {
  source                  = "./eks/fargate"
  eks_cluster_name        = module.eks_cluster.cluster_name
  fargate_profile_name    = var.fargate_profile_name
  subnet_ids              = module.network.aws_subnets_private
  kubernetes_namespace    = var.kubernetes_namespace
}
