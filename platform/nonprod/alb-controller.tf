resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.6.0"
  namespace  = "kube-system"

  values = [
    yamlencode({
      clusterName = var.cluster_name
      region      = var.aws_region
      vpcId       = data.aws_eks_cluster.this.vpc_config[0].vpc_id
      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
      }
    })
  ]

  wait    = true
  timeout = 300

}