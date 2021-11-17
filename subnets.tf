resource "aws_subnet" "dev-prv" {
  vpc_id     = aws_vpc.dev.id
  cidr_block = "10.0.0.0/26"

  tags = {
    Name = "dev-prv"
    env  = "dev"
  }
}

resource "aws_subnet" "dev-pub" {
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = "10.0.0.64/26"
  map_public_ip_on_launch = true

  tags = {
    Name = "dev-pub"
    env  = "dev"
  }
}

resource "aws_route_table" "dev-pub" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev.id
  }

  tags = {
    Name = "dev-pub"
    env  = "dev"
  }
}

resource "aws_route_table" "dev-prv" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.dev.id
  }

  tags = {
    Name = "dev-prv"
    env  = "dev"
  }

  depends_on = [aws_nat_gateway.dev]
}

resource "aws_route_table_association" "dev-pub" {
  subnet_id      = aws_subnet.dev-pub.id
  route_table_id = aws_route_table.dev-pub.id
}

resource "aws_route_table_association" "dev-prv" {
  subnet_id      = aws_subnet.dev-prv.id
  route_table_id = aws_route_table.dev-prv.id
}
