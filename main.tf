module "cdn-us-east-1" {
  source = "./cdn"
  region = "us-east-1"
}

module "cdn-eu-west-1" {
  source = "./cdn"
  region = "eu-west-1"
}

module "cdn-ap-south-1" {
  source = "./cdn"
  region = "ap-south-1"
}