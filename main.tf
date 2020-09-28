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

resource "aws_route_table_association" "public_us" {
  provider                         = aws
  count          = length(data.aws_availability_zones.available_us.names)
  subnet_id      = element(aws_subnet.public_us.*.id, count.index)
  route_table_id = aws_route_table.public_us.id
}

resource "aws_security_group" "sg_us" {
  provider                         = aws
  name = "leadgen-http-default"
  vpc_id = aws_vpc.main_us.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    ipv6_cidr_blocks     = ["::/0"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    ipv6_cidr_blocks     = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    ipv6_cidr_blocks     = ["::/0"]
  }

  tags = {
    Name = "leadgen-http-default"
  }
}

 data "aws_vpc" "default_us" {
 provider                         = aws  
 id = aws_vpc.main_us.id
} 

 data "aws_subnet_ids" "all_us" {
  provider                         = aws
  vpc_id = data.aws_vpc.default_us.id
  //depends_on = [aws_vpc.main]
} 

 resource "aws_lb" "alb_us" {
  provider                         = aws 
  name            = "lgp-tds-alb-1d"
  load_balancer_type = "application"
  security_groups = [aws_security_group.sg_us.id]
  subnets         = data.aws_subnet_ids.all_us.ids
  ip_address_type = "dualstack"
  tags = {
    Name = "leadgen-alb"
  }
} 


resource "aws_lb_target_group" "group_us" {
  provider                         = aws
  name     = "leadgen-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_us.id

  health_check {
    enabled             = true
    interval            = 30  
    path = "/"
    port = 80
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    protocol            = "HTTP"
  }
}

resource "aws_lb_listener" "listener_http_us" {
  provider                         = aws
  load_balancer_arn = aws_lb.alb_us.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.group_us.arn
    type             = "forward"
  }
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

resource "aws_security_group" "sg_eu" {
  provider                         = aws.eu
  name = "leadgen-http-default"
  vpc_id = aws_vpc.main_eu.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    ipv6_cidr_blocks     = ["::/0"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    ipv6_cidr_blocks     = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    ipv6_cidr_blocks     = ["::/0"]
  }

  tags = {
    Name = "leadgen-http-default"
  }
}

 data "aws_vpc" "default_eu" {
 provider                         = aws.eu  
 id = aws_vpc.main_eu.id
} 

 data "aws_subnet_ids" "all_eu" {
  provider                         = aws.eu
  vpc_id = data.aws_vpc.default_eu.id
  //depends_on = [aws_vpc.main]
} 

 resource "aws_lb" "alb_eu" {
  provider                         = aws.eu
  name            = "lgp-tds-alb-1d"
  load_balancer_type = "application"
  security_groups = [aws_security_group.sg_eu.id]
  subnets         = data.aws_subnet_ids.all_eu.ids
  ip_address_type = "dualstack"
  tags = {
    Name = "leadgen-alb"
  }
} 


resource "aws_lb_target_group" "group_eu" {
  provider                         = aws.eu
  name     = "leadgen-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_eu.id

  health_check {
    enabled             = true
    interval            = 30  
    path = "/"
    port = 80
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    protocol            = "HTTP"
  }
}

resource "aws_lb_listener" "listener_http_eu" {
  provider                         = aws.eu
  load_balancer_arn = aws_lb.alb_eu.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.group_eu.arn
    type             = "forward"
  }
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

resource "aws_security_group" "sg_ap" {
  provider                         = aws.ap
  name = "leadgen-http-default"
  vpc_id = aws_vpc.main_ap.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    ipv6_cidr_blocks     = ["::/0"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    ipv6_cidr_blocks     = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    ipv6_cidr_blocks     = ["::/0"]
  }

  tags = {
    Name = "leadgen-http-default"
  }
}

 data "aws_vpc" "default_ap" {
 provider                         = aws.ap  
 id = aws_vpc.main_ap.id
} 

 data "aws_subnet_ids" "all_ap" {
  provider                         = aws.ap
  vpc_id = data.aws_vpc.default_ap.id
  //depends_on = [aws_vpc.main]
} 

 resource "aws_lb" "alb_ap" {
  provider                         = aws.ap 
  name            = "lgp-tds-alb-1d"
  load_balancer_type = "application"
  security_groups = [aws_security_group.sg_ap.id]
  subnets         = data.aws_subnet_ids.all_ap.ids
  ip_address_type = "dualstack"
  tags = {
    Name = "leadgen-alb"
  }
} 


resource "aws_lb_target_group" "group_ap" {
  provider                         = aws.ap
  name     = "leadgen-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_ap.id

  health_check {
    enabled             = true
    interval            = 30  
    path = "/"
    port = 80
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    protocol            = "HTTP"
  }
}

resource "aws_lb_listener" "listener_http_ap" {
  provider                         = aws.ap
  load_balancer_arn = aws_lb.alb_ap.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.group_ap.arn
    type             = "forward"
  }
}