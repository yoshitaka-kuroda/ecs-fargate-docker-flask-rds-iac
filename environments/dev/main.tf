module "vpc" {
  source               = "../../modules/vpc"
  env                  = var.env
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
}
module "alb" {
  source            = "../../modules/alb"
  env               = var.env
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}
module "ecs" {
  source                  = "../../modules/ecs"
  env                     = var.env
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  alb_sg_id               = module.alb.alb_sg_id
  target_group_arn        = module.alb.target_group_arn
  alb_listener_depends_on = module.alb.aws_lb_listener_listener  # ←これを追加！
}

resource "random_password" "db" {
  length  = 16
  special = true
}

module "rds" {
  source             = "../../modules/rds"
  env                = var.env
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_sg_id          = module.vpc.rds_sg_id
  db_username        = var.db_username
  db_password        = random_password.db.result  # ←ここで自動生成パスワードを渡す
}