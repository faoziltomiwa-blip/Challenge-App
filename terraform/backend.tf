terraform {
  backend "s3" {
    bucket         = "devops-challenge-tf-state-825555019555"
    key            = "infrastructure/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "devops-challenge-tf-locks"
  }
}
