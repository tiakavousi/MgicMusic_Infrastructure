resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

##################################################################
# EKS CLUSTER
##################################################################
resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.cluster_name}-${terraform.workspace}"
  enabled_cluster_log_types = ["api", "audit", "authenticator","controllerManager","scheduler"]
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    #endpoint_private_access = true
    # NEW PARTS
    endpoint_private_access = false
    endpoint_public_access  = true
    # END
    subnet_ids               = [var.public_subnets[0], var.public_subnets[1]]
  }

  tags = {
    Name = "eks_cluster_${terraform.workspace}"
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy
  ]
}


resource "aws_eks_addon" "cni" {

  addon_name        = "vpc-cni"
  addon_version     = "v1.18.3-eksbuild.1"
  cluster_name      = "eks_cluster-default"
  resolve_conflicts = "OVERWRITE"

  configuration_values = "{\"env\": {\"AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG\": \"true\",}}"
   depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}