resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Action = [
        "sts:AssumeRole"
      ]

      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role" "eks_node" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = var.tags
}

resource "aws_iam_role" "vpc_cni" {
  name = "${var.cluster_name}-vpc-cni-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })

  tags = var.tags
}

resource "aws_iam_role" "platform_admin" {
  name = "${var.cluster_name}-platform-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sts:AssumeRole"
      ]
      Principal = {
        AWS = var.cluster_admin_arn
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "node_ecr_pull_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.eks_node.name
}



resource "aws_eks_cluster" "vprofile_eks_cluster" {
    name = var.cluster_name
    
    access_config {
        authentication_mode = "API"
    }

    role_arn = aws_iam_role.eks_cluster.arn
    version = var.k8s_version
    tags = var.tags

    vpc_config {
        subnet_ids = var.private_app_subnet_ids
        endpoint_public_access = var.public_api_endpoint_access
        endpoint_private_access = var.private_api_endpoint_access
        public_access_cidrs = var.public_api_access_allowed_cidrs
    }

    depends_on = [
        aws_iam_role_policy_attachment.eks_cluster_policy
    ]
}

resource "aws_eks_node_group" "vprofile_node_group" {
  cluster_name    = aws_eks_cluster.vprofile_eks_cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = var.private_app_subnet_ids

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_capacity
    max_size     = var.node_max_capacity
    min_size     = var.node_min_capacity
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_ecr_pull_policy,
  ]

  tags = var.tags
}

resource "aws_eks_pod_identity_association" "vpc_cni" {
  cluster_name    = aws_eks_cluster.vprofile_eks_cluster.name
  namespace       = "kube-system"
  service_account = "aws-node"
  role_arn        = aws_iam_role.vpc_cni.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_eks_addon.vpc_cni,
    aws_iam_role_policy_attachment.vpc_cni
  ]
}

resource "aws_eks_addon" "pod_identity_agent" {
    cluster_name = aws_eks_cluster.vprofile_eks_cluster.name
    addon_name = "eks-pod-identity-agent"
}

resource "aws_eks_addon" "vpc_cni" {
    cluster_name = aws_eks_cluster.vprofile_eks_cluster.name
    addon_name = "vpc-cni"
}

resource "aws_eks_addon" "coredns" {
    cluster_name = aws_eks_cluster.vprofile_eks_cluster.name
    addon_name = "coredns"

    depends_on = [
        aws_eks_node_group.vprofile_node_group
    ]
}

resource "aws_eks_addon" "kube_proxy" {
    cluster_name = aws_eks_cluster.vprofile_eks_cluster.name
    addon_name = "kube-proxy"
}

# Give platform admin role access to cluster
resource "aws_eks_access_entry" "platform_admin" {
  cluster_name      = aws_eks_cluster.vprofile_eks_cluster.name
  principal_arn     = aws_iam_role.platform_admin.arn
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "cluster_admin" {
  cluster_name  = aws_eks_cluster.vprofile_eks_cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.platform_admin.arn

  access_scope {
    type       = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.platform_admin
  ]
}


