module "default_network" {
  source = "github.com/srhoton/tf-module-network"
  env_name = var.env_name
  base_cidr_block = var.base_cidr_block
  enable_nat_gateway = false
}
