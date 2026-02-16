# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name_prefix            = "${local.env}-eks-cluster"
  vpc_id                 = aws_vpc.main.id
  description            = "Security group for EKS cluster control plane"
  revoke_rules_on_delete = true

  tags = {
    Name = "${local.env}-eks-cluster-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Cluster SG: Ingress from self (required by AWS - recreated if removed)
resource "aws_vpc_security_group_ingress_rule" "cluster_ingress_self" {
  security_group_id            = aws_security_group.eks_cluster.id
  referenced_security_group_id = aws_security_group.eks_cluster.id
  ip_protocol                  = "-1"
  description                  = "Allow cluster security group to communicate with itself"
}

# Cluster SG: Ingress from nodes for API server
resource "aws_vpc_security_group_ingress_rule" "cluster_ingress_nodes_https" {
  security_group_id            = aws_security_group.eks_cluster.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow worker nodes to communicate with cluster API server"
}

# Cluster SG: Egress to nodes for kubelet
resource "aws_vpc_security_group_egress_rule" "cluster_egress_nodes_kubelet" {
  security_group_id            = aws_security_group.eks_cluster.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  from_port                    = 10250
  to_port                      = 10250
  ip_protocol                  = "tcp"
  description                  = "Allow cluster control plane to communicate with node kubelets"
}

# Cluster SG: Egress to nodes for HTTPS (extension API servers, webhooks)
resource "aws_vpc_security_group_egress_rule" "cluster_egress_nodes_https" {
  security_group_id            = aws_security_group.eks_cluster.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow cluster control plane to communicate with pods running extension API servers"
}

# Cluster SG: Egress to nodes for high ports (webhooks, metrics)
resource "aws_vpc_security_group_egress_rule" "cluster_egress_nodes_highports" {
  security_group_id            = aws_security_group.eks_cluster.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  from_port                    = 1025
  to_port                      = 65535
  ip_protocol                  = "tcp"
  description                  = "Allow cluster control plane to communicate with worker nodes on high ports"
}

resource "aws_security_group" "eks_nodes" {
  name_prefix            = "${local.env}-eks-nodes"
  vpc_id                 = aws_vpc.main.id
  description            = "Security group for EKS worker nodes"
  revoke_rules_on_delete = true

  tags = {
    Name = "${local.env}-eks-nodes-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Node SG: Ingress from self (node-to-node communication)
resource "aws_vpc_security_group_ingress_rule" "nodes_ingress_self" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  ip_protocol                  = "-1"
  description                  = "Allow nodes to communicate with each other"
}

# Node SG: Ingress from cluster for kubelet
resource "aws_vpc_security_group_ingress_rule" "nodes_ingress_cluster_kubelet" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_cluster.id
  from_port                    = 10250
  to_port                      = 10250
  ip_protocol                  = "tcp"
  description                  = "Allow cluster control plane to communicate with node kubelets"
}

# Node SG: Ingress from cluster for HTTPS (extension API servers)
resource "aws_vpc_security_group_ingress_rule" "nodes_ingress_cluster_https" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_cluster.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow pods running extension API servers to receive communication from cluster control plane"
}

# Node SG: Ingress from cluster for high ports (webhooks, metrics)
resource "aws_vpc_security_group_ingress_rule" "nodes_ingress_cluster_highports" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_cluster.id
  from_port                    = 1025
  to_port                      = 65535
  ip_protocol                  = "tcp"
  description                  = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
}

# Node SG: Egress to cluster API server
resource "aws_vpc_security_group_egress_rule" "nodes_egress_cluster_https" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_cluster.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow nodes to communicate with cluster API server"
}

# Node SG: Egress to self (node-to-node communication)
resource "aws_vpc_security_group_egress_rule" "nodes_egress_self" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  ip_protocol                  = "-1"
  description                  = "Allow nodes to communicate with each other"
}

# Node SG: Egress for DNS (TCP)
resource "aws_vpc_security_group_egress_rule" "nodes_egress_dns_tcp" {
  security_group_id = aws_security_group.eks_nodes.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
  description       = "Allow DNS resolution (TCP)"
}

# Node SG: Egress for DNS (UDP)
resource "aws_vpc_security_group_egress_rule" "nodes_egress_dns_udp" {
  security_group_id = aws_security_group.eks_nodes.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  description       = "Allow DNS resolution (UDP)"
}

# Node SG: Egress for HTTPS to AWS services (ECR, EKS API, S3, etc.)
resource "aws_vpc_security_group_egress_rule" "nodes_egress_https" {
  security_group_id = aws_security_group.eks_nodes.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow HTTPS to AWS APIs (EKS, ECR, S3, STS)"
}

# Node SG: Ingress from ALB
resource "aws_vpc_security_group_ingress_rule" "nodes_ingress_alb_pods" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  description                  = "Allow ALB to reach pods via IP target mode"
}

resource "aws_security_group" "alb" {
  name_prefix            = "${local.env}-alb-"
  vpc_id                 = aws_vpc.main.id
  description            = "Security group for ALB ingress"
  revoke_rules_on_delete = true

  tags = {
    Name = "${local.env}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ALB SG: Ingress HTTP from internet
resource "aws_vpc_security_group_ingress_rule" "alb_ingress_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow HTTP from internet"
}

# ALB SG: Ingress HTTPS from internet
resource "aws_vpc_security_group_ingress_rule" "alb_ingress_https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow HTTPS from internet"
}

# ALB SG: Ingress traffic to application
resource "aws_vpc_security_group_egress_rule" "alb_egress_nodes_pods" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.eks_nodes.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  description                  = "Allow ALB to communicate with pods via IP target mode"
}
