# --- Variables ---
variable "cluster_name" {
  default = "staging-altsch_project"
  type    = string
}

variable "region" {
  default = "eu-west-2"
  type    = string
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster is deployed"
  type        = string
}

variable "oidc_provider_arn" {
  description = "Existing OIDC provider ARN for EKS cluster"
  type        = string
}

variable "oidc_provider_url" {
  description = "Existing OIDC provider URL (without https://)"
  type        = string
}

# --- IAM Policy for ALB Controller ---
resource "aws_iam_policy" "alb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("iam-policy.json") # same JSON from AWS docs
}

# --- IAM Role + SA + Helm for kube-system namespace ---
resource "aws_iam_role" "alb_controller_kube_system" {
  name = "alb-controller-role-kube-system"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach_kube_system" {
  role       = aws_iam_role.alb_controller_kube_system.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "kubernetes_service_account" "alb_controller_sa_kube_system" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller_kube_system.arn
    }
  }
}

resource "helm_release" "aws_lb_controller_kube_system" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  values = [
    yamlencode({
      clusterName    = var.cluster_name
      serviceAccount = { create = false, name = kubernetes_service_account.alb_controller_sa_kube_system.metadata[0].name }
      region         = var.region
      vpcId          = var.vpc_id
    })
  ]

  depends_on = [kubernetes_service_account.alb_controller_sa_kube_system]
}

# --- IAM Role + SA + Helm for retail-dev namespace ---
resource "aws_iam_role" "alb_controller_retail_dev" {
  name = "alb-controller-role-retail-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:retail-dev:aws-load-balancer-controller"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach_retail_dev" {
  role       = aws_iam_role.alb_controller_retail_dev.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "kubernetes_service_account" "alb_controller_sa_retail_dev" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "retail-dev"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller_retail_dev.arn
    }
  }
}

resource "helm_release" "aws_lb_controller_retail_dev" {
  name       = "aws-load-balancer-controller-retail-dev"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "retail-dev"

  values = [
    yamlencode({
      clusterName    = var.cluster_name
      serviceAccount = { create = false, name = kubernetes_service_account.alb_controller_sa_retail_dev.metadata[0].name }
      region         = var.region
      vpcId          = var.vpc_id
    })
  ]

  depends_on = [kubernetes_service_account.alb_controller_sa_retail_dev]
}
