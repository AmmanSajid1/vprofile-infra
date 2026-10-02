                               INTERNET
                                  │
                                  │ HTTPS
                                  ▼
                         app.ammandevops.xyz
                                  │
                              Route 53
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │ Internet-facing ALB     │
                    │ TLS termination (ACM)   │
                    └────────────┬────────────┘
                                 │
                  ┌──────────────┴──────────────┐
                  │                             │
               AZ-A                           AZ-B
         ┌────────────────┐             ┌────────────────┐
         │ Public Subnet  │             │ Public Subnet  │
         │                │             │                │
         │ ALB            │             │ ALB            │
         │ NAT Gateway    │             │ NAT Gateway    │
         └───────┬────────┘             └───────┬────────┘
                 │                              │
         ┌───────▼────────┐             ┌───────▼────────┐
         │ Private App    │             │ Private App    │
         │ Subnet         │             │ Subnet         │
         │                │             │                │
         │   EKS Nodes    │             │   EKS Nodes    │
         └───────┬────────┘             └────────┬───────┘
                 │                               │
                 └──────────────┬────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │      EKS Cluster      │
                    │                       │
                    │ vProfile / Tomcat     │
                    │ Memcached             │
                    │ RabbitMQ              │
                    │ Argo CD               │
                    │ AWS LB Controller     │
                    └───────────┬───────────┘
                                │
                                │ MySQL :3306
                                ▼
              ┌─────────────────────────────────┐
              │          Private DB Tier        │
              │                                 │
              │ DB Subnet A       DB Subnet B   │
              │        \             /          │
              │         \           /           │
              │          RDS MySQL              │
              │      Multi-AZ (production)      │
              └─────────────────────────────────┘


       DELIVERY / CONTROL PLANE

 GitHub ──► GitHub Actions ──► Amazon ECR
   │                              │
   │                              │ image pull
   │                              ▼
   │                         EKS workloads
   │
   └──► GitOps Repository
              │
              │ watched/reconciled
              ▼
           Argo CD
              │
              ▼
             EKS