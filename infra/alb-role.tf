# locals {
#   k8s_aws_lb_service_account_namespace = "kube-system"
#   k8s_aws_lb_service_account_name      = "aws-load-balancer-controller"
# }

# resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
#   name        = "AWSLoadBalancerControllerIAMPolicy"
#   path        = "/"
#   description = "AWS Load Balancer Controller Policy"
#   policy      = file("iam-policy.json")


#   tags = {
#     Terraform   = "true"
#     Environment = local.env
#   }

# }

# module "iam_assumable_role_aws_lb" {
#   source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#   version                       = "3.6.0"
#   create_role                   = true
#   role_name                     = "AWSLoadBalancerControllerIAMRole"
#   provider_url                  = "oidc.eks.eu-west-2.amazonaws.com/id/E74E4B1A5FD9A4982C1E2B929D44F1F5"
#   role_policy_arns              = [aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn]
#   oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_aws_lb_service_account_namespace}:${local.k8s_aws_lb_service_account_name}"]

#   tags = {
#     Terraform   = "true"
#     Environment = local.env
#   }

# }




locals {
  kube_system_namespace    = "kube-system"
  alb_service_account_name = "alb-controller"
  efs_service_account_name = "efs-controller"
  system_service_accounts = [
    "${local.kube_system_namespace}:${local.alb_service_account_name}"
  ]
}

resource "kubernetes_service_account" "alb" {
  metadata {
    name      = local.alb_service_account_name
    namespace = local.kube_system_namespace
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.vpc_cni_irsa.iam_role_arn
    }
  }
}

module "vpc_cni_irsa" {

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.12"

  role_name_prefix = "vpc-cni-irsa-"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = "arn:aws:iam::733110823125:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/E74E4B1A5FD9A4982C1E2B929D44F1F5"
      namespace_service_accounts = local.system_service_accounts
    }
  }

}
