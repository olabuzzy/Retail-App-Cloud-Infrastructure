locals {
  k8s_aws_lb_service_account_namespace = "kube-system"
  k8s_aws_lb_service_account_name      = "aws-load-balancer-controller"
}

resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS Load Balancer Controller Policy"
  policy      = file("iam-policy.json")


  tags = {
    Terraform   = "true"
    Environment = local.env
  }

}

module "iam_assumable_role_aws_lb" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.6.0"
  create_role                   = true
  role_name                     = "AWSLoadBalancerControllerIAMRole"
  provider_url                  = "oidc.eks.eu-west-2.amazonaws.com/id/E74E4B1A5FD9A4982C1E2B929D44F1F5"
  role_policy_arns              = [aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_aws_lb_service_account_namespace}:${local.k8s_aws_lb_service_account_name}"]

  tags = {
    Terraform   = "true"
    Environment = local.env
  }

}