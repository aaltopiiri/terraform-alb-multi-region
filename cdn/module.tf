terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.region
  shared_credentials_file = var.shared_credentials_file
  profile                 = var.profile
}

data "aws_availability_zones" "available" {
  state             = "available"
  exclude_names = var.blacklisted_az
}


resource "aws_vpc" "main" {
  cidr_block                       = "10.41.0.0/16"
  assign_generated_ipv6_cidr_block = "true"
  enable_dns_support               = "true"
  enable_dns_hostnames             = "true"

  tags = {
    Name = "leadgen-default-${var.region}"
    //Owner = "Terraform"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "leadgen-${var.region}"
  }
lifecycle {
create_before_destroy = true
}
}

resource "aws_subnet" "public" {
  count                           = length(data.aws_availability_zones.available.names)
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index)
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  availability_zone               = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "leadgen-prod-${element(data.aws_availability_zones.available.names, count.index)}"
  }
  lifecycle {
create_before_destroy = true
}
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.default.id
  }
}

resource "aws_route_table_association" "public" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  //route_table_id = element(aws_route_table.public.*.id, count.index)
  //subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "sg" {
  name = "leadgen-http-default"
  vpc_id = aws_vpc.main.id
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

 data "aws_vpc" "default" {
 id = aws_vpc.main.id
} 

 data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
  //depends_on = [aws_vpc.main]
} 

 resource "aws_lb" "alb" {
  name            = "lgp-tds-alb-1d"
  load_balancer_type = "application"
  security_groups = [aws_security_group.sg.id]
  subnets         = data.aws_subnet_ids.all.ids
  ip_address_type = "dualstack"
  tags = {
    Name = "leadgen-alb"
  }
} 


resource "aws_lb_target_group" "group" {
  name     = "leadgen-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

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

resource "aws_lb_listener" "listener_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.group.arn
    type             = "forward"
  }
}
