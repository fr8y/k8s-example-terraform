data "aws_ami" "ubu-ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  // cannonical AWS ID 
  owners = ["099720109477"]
}

resource "aws_iam_instance_profile" "instance-profile" {
  name = "instance-profile"
  role = aws_iam_role.SSM-Role.name
  tags = {
    env = "dev"
  }
}

resource "aws_key_pair" "dev" {
  key_name   = "dev-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "home_to_aws" {
  name        = "home_to_aws"
  description = "Allows home ext IP to reach instance"
  vpc_id      = aws_vpc.dev.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    // replace ##.##.##.## with your own external IP address, leave /32 at end
    cidr_blocks = ["##.##.##.##/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "home_to_aws"
    env  = "dev"
  }
}

resource "aws_security_group" "dev_to_dev" {
  name        = "dev_to_dev"
  description = "Allows dev instances to communicate over any port"
  vpc_id      = aws_vpc.dev.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev_to_dev"
    env  = "dev"
  }
}

resource "aws_launch_template" "k8s-control" {
  name          = "k8s-control"
  instance_type = "t2.medium"
  key_name      = aws_key_pair.dev.key_name

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
    }
  }

  network_interfaces {
    delete_on_termination       = true
    subnet_id                   = aws_subnet.dev-pub.id
    security_groups             = [aws_security_group.home_to_aws.id, aws_security_group.dev_to_dev.id]
    associate_public_ip_address = true
  }

  monitoring {
    enabled = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.instance-profile.name
  }

  image_id  = data.aws_ami.ubu-ami.id
  user_data = filebase64("${path.module}/config.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "k8s-control"
      env  = "dev"
    }
  }
}

resource "aws_launch_template" "k8s-worker" {
  name          = "k8s-worker"
  instance_type = "t2.medium"
  key_name      = aws_key_pair.dev.key_name

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
    }
  }

  network_interfaces {
    delete_on_termination = true
    subnet_id             = aws_subnet.dev-prv.id
    security_groups       = [aws_security_group.dev_to_dev.id]
  }

  monitoring {
    enabled = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.instance-profile.name
  }

  image_id  = data.aws_ami.ubu-ami.id
  user_data = filebase64("${path.module}/config.sh")

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "k8s-worker"
      env  = "dev"
    }
  }
}

resource "aws_autoscaling_group" "k8s-worker" {
  name                = "k8s-worker"
  max_size            = 3
  min_size            = 2
  desired_capacity    = 2
  vpc_zone_identifier = [aws_subnet.dev-prv.id]

  launch_template {
    id      = aws_launch_template.dev-prv.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_group" "k8s-control" {
  name                = "k8s-control"
  max_size            = 2
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [aws_subnet.dev-pub.id]

  launch_template {
    id      = aws_launch_template.dev-pub.id
    version = "$Latest"
  }
}