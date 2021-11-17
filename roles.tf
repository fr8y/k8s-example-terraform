data "aws_iam_policy_document" "ec2-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ssm-pol" {
  name = "AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "cw-pol" {
  name = "CloudWatchAgentServerPolicy"
}


resource "aws_iam_role" "SSM-Role" {
  name                = "SSM-Role"
  assume_role_policy  = data.aws_iam_policy_document.ec2-assume-role-policy.json
  managed_policy_arns = [data.aws_iam_policy.ssm-pol.arn, data.aws_iam_policy.cw-pol.arn]
  tags = {
    Name = "SSM-Role"
    env  = "dev"
  }
}