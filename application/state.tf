terraform {
  backend "s3" {
    bucket = "b2c-tfstate"
    key    = "b2c/cicd_poc_app.tfstate"
    region = "us-west-2"
  }
}
