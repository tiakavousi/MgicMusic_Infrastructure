resource "aws_iam_role" "fargate_pod_execution_role" {
  name                  = "eks-fargate-pod-execution-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "eks.amazonaws.com",
          "eks-fargate-pods.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution_role.name
}

##################################################################
# KUBE SYSTEM FARGATE
##################################################################
resource "aws_eks_fargate_profile" "kube-system" {
  cluster_name           = var.eks_cluster_name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = [var.subnet_ids[0], var.subnet_ids[1]]

  selector {
    namespace = "kube-system"
    labels = {
      k8s-app = "kube-dns"
    }
  }
}

#####################################################################
# PRODUCTION FARGATE
#####################################################################
resource "aws_eks_fargate_profile" "main" {
  cluster_name           = var.eks_cluster_name
  fargate_profile_name   = "main"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = [var.subnet_ids[0], var.subnet_ids[1]]

  selector {
    namespace = "magicmusic-prod"
  }
}

##################################################################
# STAGING FARGATE
##################################################################
resource "aws_eks_fargate_profile" "staging" {
  cluster_name           = var.eks_cluster_name
  fargate_profile_name   = "staging"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = [var.subnet_ids[0], var.subnet_ids[1]]

  selector {
    namespace = "magicmusic-qa"
  }
}

##################################################################
# IAM ROLE
##################################################################
data "aws_iam_policy_document" "aws_fargate_logging_policy" {
  statement {
    sid = "1"

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "aws_fargate_logging_policy" {
  name   = "aws_fargate_logging_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.aws_fargate_logging_policy.json
}

resource "aws_iam_role_policy_attachment" "aws_fargate_logging_policy_attach_role" {
  role       = aws_iam_role.fargate_pod_execution_role.name
  policy_arn = aws_iam_policy.aws_fargate_logging_policy.arn
}

