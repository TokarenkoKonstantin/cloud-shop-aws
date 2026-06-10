# cloud-shop-aws ☁️

> **Production-grade AWS infrastructure for an e-commerce platform — 100% Terraform.**
> EKS · RDS · ECR · VPC, deployed through a GitHub Actions plan/apply pipeline.
>
> Облачная версия [cloud-shop](https://github.com/TokarenkoKonstantin/cloud-shop): та же платформа, но на managed-сервисах AWS, целиком описанная кодом.

![Terraform](https://img.shields.io/badge/Terraform-1.6-7B42BC?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-EKS%20%C2%B7%20RDS%20%C2%B7%20ECR%20%C2%B7%20VPC-FF9900?logo=amazonwebservices&logoColor=white)
![CI](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## Why this repo exists

My [cloud-shop](https://github.com/TokarenkoKonstantin/cloud-shop) runs on **bare-metal Kubernetes built by hand with kubeadm** (5 VMs, Calico, MetalLB, CloudNativePG).
This repo is the **same platform re-architected for AWS managed services** — to show both real-world approaches side by side:

| | cloud-shop (bare-metal) | cloud-shop-aws (this repo) |
|---|---|---|
| Cluster | kubeadm, 5 VMs | **EKS** + managed node group |
| Database | CloudNativePG (HA, 3 nodes) | **RDS** PostgreSQL |
| Registry | GHCR | **ECR** |
| Load balancing | MetalLB | AWS ELB |
| Network | Calico on VM bridge | **VPC**: public/private subnets, NAT |
| Provisioning | Terraform + Ansible | **Terraform only** |

## Architecture

```
                        ┌──────────────────────────── VPC 10.0.0.0/16 ────────────────────────────┐
                        │                                                                          │
  GitHub Actions ──────▶│  public subnets (×2 AZ)              private subnets (×2 AZ)             │
  terraform plan/apply  │  ┌──────────────┐                    ┌──────────────────────────┐        │
                        │  │  NAT / ELB   │ ◀───────────────── │  EKS managed node group  │        │
                        │  └──────────────┘                    │  (IRSA via OIDC provider)│        │
                        │                                      └────────────┬─────────────┘        │
                        │                                                   │ SG-restricted        │
                        │                                      ┌────────────▼─────────────┐        │
                        │                                      │  RDS PostgreSQL          │        │
                        │                                      └──────────────────────────┘        │
                        └──────────────────────────────────────────────────────────────────────────┘
        Terraform state ─▶ S3 (versioned, encrypted) + DynamoDB lock table
```

## What's inside

```
terraform/
├── main.tf                  # root module: state bucket, lock table, module wiring
├── variables.tf             # all inputs with sane defaults (eu-central-1, 2 AZ)
├── modules/
│   ├── vpc/                 # VPC, public/private subnets across 2 AZ, NAT, routing
│   ├── eks/                 # EKS cluster, managed node group, OIDC provider → IRSA
│   ├── rds/                 # PostgreSQL in private subnets, SG allows only EKS nodes
│   └── ecr/                 # container registries for app images
└── environments/dev/        # tfvars example
.github/workflows/
└── terraform.yml            # fmt → validate → plan on PR, apply on merge to main
```

**Key decisions**

- 🔐 **IRSA (IAM Roles for Service Accounts)** — pods get IAM permissions through the EKS OIDC provider, no node-wide credentials
- 🗄️ **Remote state done right** — S3 with versioning + SSE, DynamoDB locking, `prevent_destroy` on the state bucket
- 🌐 **Private by default** — EKS nodes and RDS live in private subnets; only ELB/NAT face the internet
- 🛡️ **DB security group** allows traffic exclusively from the EKS cluster security group
- 🔄 **Plan on PR, apply on merge** — no manual `terraform apply` from laptops; secrets injected from GitHub Secrets

## Deploy

```bash
cd terraform
terraform init
terraform plan -var="db_password=..."
terraform apply
```

> ⚠️ Spins up real billable AWS resources (EKS control plane ≈ $0.10/h, NAT, RDS).
> Tear down with `terraform destroy` when done.

## Application layer

Workloads are deployed onto the cluster via **GitOps (ArgoCD)** — manifests and the CI pipeline that builds the images live in [cloud-shop](https://github.com/TokarenkoKonstantin/cloud-shop).

---

## Author

**Konstantin Tokarenko** — DevOps Engineer · Open to work
[Telegram](https://t.me/KonstantinTokar) · [GitHub](https://github.com/TokarenkoKonstantin)

MIT © 2026
