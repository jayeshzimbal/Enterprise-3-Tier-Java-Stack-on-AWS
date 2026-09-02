# 1. Dynamically retrieve the latest Amazon Linux 2023 AMI via SSM
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# 2. Add an IAM Role & Profile for instance management (SSM / CloudWatch)
resource "aws_iam_role" "ec2_role" {
  name_prefix = "${var.environment}-ec2-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "main" {
  name_prefix = "${var.environment}-ec2-profile-"
  role        = aws_iam_role.ec2_role.name
}

# 3. Updated Launch Template
resource "aws_launch_template" "main" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile {
    arn = aws_iam_instance_profile.main.arn
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y java-11-amazon-corretto tomcat
              systemctl enable --now tomcat
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-web-instance"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 4. Auto Scaling Group using launch_template version tracking
resource "aws_autoscaling_group" "main" {
  name_prefix         = "${var.environment}-asg-"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = var.target_group_arns
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.main.id
    version = aws_launch_template.main.latest_version
  }

  # Cleaned up inline tags (managed by launch_template.tag_specifications instead)
  dynamic "tag" {
    for_each = {
      Name        = "${var.environment}-web-instance"
      Environment = var.environment
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}
