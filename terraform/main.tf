module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
}

module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
}

module "alb" {
  source         = "./modules/alb"
  project_name   = var.project_name
  vpc_id         = module.networking.vpc_id
  public_subnets = module.networking.public_subnets
  alb_sg_id      = module.security.alb_sg_id
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

module "ecs" {
  source             = "./modules/ecs"
  project_name       = var.project_name
  aws_region         = var.aws_region
  public_subnets     = module.networking.public_subnets
  ecs_sg_id          = module.security.ecs_sg_id
  target_group_arn   = module.alb.target_group_arn
  ecr_repository_url = module.ecr.repository_url
}

module "jenkins" {
  source           = "./modules/jenkins"
  project_name     = var.project_name
  public_subnet_id = module.networking.public_subnets[0]
  jenkins_sg_id    = module.security.jenkins_sg_id
}
