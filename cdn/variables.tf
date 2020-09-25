variable "region" {
}
variable "shared_credentials_file" {
  type    = string
  default = "~/.aws/credentials"
}
variable "profile" {
  type    = string
  default = "default"
}
variable "blacklisted_az" {
  default = ["us-east-1c","us-east-1d","us-east-1f","us-east-1e", "eu-west-1c", "ap-south-1c"]
}
