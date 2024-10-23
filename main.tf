# Launch Template to replace Launch Configuration
resource "aws_launch_template" "web_server_as" {
  name_prefix   = "web-server-"
  image_id      = "ami-0175bdd48fdb0973b"
  instance_type = "t2.micro"
  key_name      = "california"

  network_interfaces {
    security_groups           = [aws_security_group.web_server.id]
    associate_public_ip_address = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "web-server-instance"
    }
  }
}

# Elastic Load Balancer (ELB)
resource "aws_elb" "web_server_lb" {
  name            = "web-server-lb"
  security_groups = [aws_security_group.web_server.id]
  subnets         = ["subnet-0fece32cecb74aa32", "subnet-036eddaf95a3706c8"]

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    target              = "HTTP:8000/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "terraform-elb"
  }
}

# Auto Scaling Group using Launch Template
resource "aws_autoscaling_group" "web_server_asg" {
  name                 = "web-server-asg"
  max_size             = 3
  min_size             = 1
  desired_capacity     = 2
  health_check_type    = "EC2"
  health_check_grace_period = 300
  load_balancers       = [aws_elb.web_server_lb.name]
  availability_zones   = ["us-west-1a", "us-west-1c"]

  launch_template {
    id      = aws_launch_template.web_server_as.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web-server-instance"
    propagate_at_launch = true
  }
}
