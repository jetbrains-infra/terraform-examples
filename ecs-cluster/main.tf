provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source   = "github.com/jetbrains-infra/terraform-aws-vpc-with-private-subnets-and-nat"
  project  = "my-example"
  multi_az = true
  rds      = true
}

module "bastion" {
  source = "github.com/jetbrains-infra/terraform-aws-bastion-host"
  ssh_key = "example_key"
  subnet_id = "${module.vpc.subnet_public_1}"
}

module "ecr" {
  source = "github.com/jetbrains-infra/terraform-aws-ecr"
  name = "my-example"
}

module "ecs_cluster" {
  source = "github.com/jetbrains-infra/terraform-aws-ecs-cluster"
  project = "my-example"
  vpc_id = "${module.vpc.vpc_id}"
  trusted_security_groups = "${module.vpc.default_security_group}"
}

module "ecs_nodes_in_zone_1" {
  source               = "github.com/jetbrains-infra/terraform-aws-spot-fleet"
  name                 = "UgdyzhekovsEcsCluster"
  subnet_id            = "${module.vpc.subnet_private_1}"
  security_group_ids    = "${module.ecs_cluster.security_group},${module.bastion.security_group}"
  capacity             = "2"
  type                 = "ecs_node"
  ec2_type             = "c5.large"
  ssh_key              = "example_key"
  userdata             = <<EOT
#!/bin/bash
echo ECS_CLUSTER="${module.ecs_cluster.name}" >> /etc/ecs/ecs.config

EOT
}

module "ecs_nodes_in_zone_2" {
  source               = "github.com/jetbrains-infra/terraform-aws-spot-fleet"
  name                 = "UgdyzhekovsEcsCluster"
  subnet_id            = "${module.vpc.subnet_private_2}"
  security_group_ids    = "${module.ecs_cluster.security_group},${module.bastion.security_group}"
  capacity             = "2"
  type                 = "ecs_node"
  ec2_type             = "c5.large"
  ssh_key              = "example_key"
  userdata             = <<EOT
#!/bin/bash
echo ECS_CLUSTER="${module.ecs_cluster.name}" >> /etc/ecs/ecs.config

EOT
}