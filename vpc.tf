resource "aws_vpc" "dev" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dev"
    env  = "dev"
  }
}

resource "aws_default_network_acl" "dev" {
  default_network_acl_id = aws_vpc.dev.default_network_acl_id
  subnet_ids             = [aws_subnet.dev-pub.id, aws_subnet.dev-prv.id]

  egress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }


  tags = {
    Name = "dev"
    env  = "dev"
  }
}

resource "aws_vpc_dhcp_options" "dev" {
  domain_name_servers = ["AmazonProvidedDNS"]
  tags = {
    Name = "dev"
    env  = "dev"
  }
}

resource "aws_vpc_dhcp_options_association" "dev" {
  vpc_id          = aws_vpc.dev.id
  dhcp_options_id = aws_vpc_dhcp_options.dev.id
}

resource "aws_internet_gateway" "dev" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "dev"
    env  = "dev"
  }
}

resource "aws_nat_gateway" "dev" {
  allocation_id = aws_eip.dev.id
  subnet_id     = aws_subnet.dev-pub.id

  tags = {
    Name = "dev"
    env  = "dev"
  }

  depends_on = [aws_internet_gateway.dev]
}

resource "aws_eip" "dev" {
  vpc = true
}

resource "aws_vpc_endpoint" "dev-ssm" {
  vpc_id              = aws_vpc.dev.id
  service_name        = "com.amazonaws.us-east-1.ssm"
  security_group_ids  = [aws_security_group.dev_to_dev.id]
  subnet_ids          = [aws_subnet.dev-prv.id]
  private_dns_enabled = true
  vpc_endpoint_type   = "Interface"
  tags = {
    env = "dev"
  }
}

resource "aws_vpc_endpoint" "dev-ec2messages" {
  vpc_id              = aws_vpc.dev.id
  service_name        = "com.amazonaws.us-east-1.ec2messages"
  security_group_ids  = [aws_security_group.dev_to_dev.id]
  subnet_ids          = [aws_subnet.dev-prv.id]
  private_dns_enabled = true
  vpc_endpoint_type   = "Interface"
  tags = {
    env = "dev"
  }
}

resource "aws_vpc_endpoint" "dev-ssmmessages" {
  vpc_id              = aws_vpc.dev.id
  service_name        = "com.amazonaws.us-east-1.ssmmessages"
  security_group_ids  = [aws_security_group.dev_to_dev.id]
  subnet_ids          = [aws_subnet.dev-prv.id]
  private_dns_enabled = true
  vpc_endpoint_type   = "Interface"
  tags = {
    env = "dev"
  }
}