/* module "cdn-us-east-1" {
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
} */

terraform {
  required_version = ">= 0.12"
}


//Region us-east-1

provider "aws" {
  shared_credentials_file = var.shared_credentials_file
  profile                 = var.profile
  region                  = "us-east-1"
}

data "aws_availability_zones" "available_us" {
  provider                         = aws
  state         = "available"
  exclude_names = var.blacklisted_az
}

resource "aws_vpc" "main_us" {
  provider                         = aws
  cidr_block                       = "10.41.0.0/16"
  assign_generated_ipv6_cidr_block = "true"
  enable_dns_support               = "true"
  enable_dns_hostnames             = "true"

  tags = {
    Name = "leadgen-default-us-east-1"
  }
}

resource "aws_internet_gateway" "default_us" {
  provider                         = aws
  vpc_id = aws_vpc.main_us.id

  tags = {
    Name = "leadgen-us-east-1"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "public_us" {
  provider                         = aws
  count                           = length(data.aws_availability_zones.available_us.names)
  vpc_id                          = aws_vpc.main_us.id
  cidr_block                      = cidrsubnet(aws_vpc.main_us.cidr_block, 8, count.index)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main_us.ipv6_cidr_block, 8, count.index)
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  availability_zone               = element(data.aws_availability_zones.available_us.names, count.index)

  tags = {
    Name = "leadgen-prod-${element(data.aws_availability_zones.available_us.names, count.index)}"
  }
  lifecycle {
create_before_destroy = true
}
}

resource "aws_route_table" "public_us" {
  provider                         = aws
  vpc_id = aws_vpc.main_us.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default_us.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.default_us.id
  }
}

resource "aws_route_table_association" "public" {
  provider                         = aws
  count          = length(data.aws_availability_zones.available_us.names)
  subnet_id      = element(aws_subnet.public_us.*.id, count.index)
  route_table_id = aws_route_table.public_us.id
}


//Region eu-west-1

provider "aws" {
  alias                   = "eu"
  shared_credentials_file = var.shared_credentials_file
  profile                 = var.profile
  region                  = "eu-west-1"
}

data "aws_availability_zones" "available_eu" {
  provider                         = aws.eu
  state         = "available"
  exclude_names = var.blacklisted_az
}

resource "aws_vpc" "main_eu" {
  provider                         = aws.eu
  cidr_block                       = "10.41.0.0/16"
  assign_generated_ipv6_cidr_block = "true"
  enable_dns_support               = "true"
  enable_dns_hostnames             = "true"

  tags = {
    Name = "leadgen-default-eu-west-1"
  }
}

resource "aws_internet_gateway" "default_eu" {
  provider = aws.eu
  vpc_id   = aws_vpc.main_eu.id

  tags = {
    Name = "leadgen-eu-west-1"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "public_eu" {
  provider                         = aws.eu
  count                           = length(data.aws_availability_zones.available_eu.names)
  vpc_id                          = aws_vpc.main_eu.id
  cidr_block                      = cidrsubnet(aws_vpc.main_eu.cidr_block, 8, count.index)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main_eu.ipv6_cidr_block, 8, count.index)
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  availability_zone               = element(data.aws_availability_zones.available_eu.names, count.index)

  tags = {
    Name = "leadgen-prod-${element(data.aws_availability_zones.available_eu.names, count.index)}"
  }
  lifecycle {
create_before_destroy = true
}
}

resource "aws_route_table" "public_eu" {
  provider                         = aws.eu
  vpc_id = aws_vpc.main_eu.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default_eu.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.default_eu.id
  }
}

resource "aws_route_table_association" "public_eu" {
  provider                         = aws.eu
  count          = length(data.aws_availability_zones.available_eu.names)
  subnet_id      = element(aws_subnet.public_eu.*.id, count.index)
  route_table_id = aws_route_table.public_eu.id
}


//Region ap-south-1

provider "aws" {
  alias                   = "ap"
  shared_credentials_file = var.shared_credentials_file
  profile                 = var.profile
  region                  = "ap-south-1"
}

data "aws_availability_zones" "available_ap" {
  provider                         = aws.ap
  state         = "available"
  exclude_names = var.blacklisted_az
}

resource "aws_vpc" "main_ap" {
  provider                         = aws.ap
  cidr_block                       = "10.41.0.0/16"
  assign_generated_ipv6_cidr_block = "true"
  enable_dns_support               = "true"
  enable_dns_hostnames             = "true"

  tags = {
    Name = "leadgen-default-ap-south-1"
  }
}

resource "aws_internet_gateway" "default_ap" {
  provider = aws.ap
  vpc_id   = aws_vpc.main_ap.id

  tags = {
    Name = "leadgen-ap-south-1"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "public_ap" {
  provider                         = aws.ap
  count                           = length(data.aws_availability_zones.available_ap.names)
  vpc_id                          = aws_vpc.main_ap.id
  cidr_block                      = cidrsubnet(aws_vpc.main_ap.cidr_block, 8, count.index)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main_ap.ipv6_cidr_block, 8, count.index)
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  availability_zone               = element(data.aws_availability_zones.available_ap.names, count.index)

  tags = {
    Name = "leadgen-prod-${element(data.aws_availability_zones.available_ap.names, count.index)}"
  }
  lifecycle {
create_before_destroy = true
}
}

resource "aws_route_table" "public_ap" {
  provider                         = aws.ap
  vpc_id = aws_vpc.main_ap.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default_ap.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.default_ap.id
  }
}

resource "aws_route_table_association" "public_ap" {
  provider                         = aws.ap
  count          = length(data.aws_availability_zones.available_ap.names)
  subnet_id      = element(aws_subnet.public_ap.*.id, count.index)
  route_table_id = aws_route_table.public_ap.id
}
