terraform {
  backend "s3" {
    bucket         = "cloud-shop-terraform-state"
    key            = "cloud-shop/eks/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "cloud-shop-terraform-locks"
  }
}
