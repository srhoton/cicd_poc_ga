data "aws_vpc" "cicd_poc" {
  filter {
    name = "tag:Name"
    values = ["srhoton-dev-default_vpc"]
  }
}

data "aws_subnet" "public_1" {
  vpc_id = data.aws_vpc.cicd_poc.id
  filter {
    name = "tag:Name"
    values = ["public-1"]
  }
}
data "aws_subnet" "public_2" {
  vpc_id = data.aws_vpc.cicd_poc.id
  filter {
    name = "tag:Name"
    values = ["public-2"]
  }
}
data "aws_subnet" "public_3" {
  vpc_id = data.aws_vpc.cicd_poc.id
  filter {
    name = "tag:Name"
    values = ["public-3"]
  }
}
