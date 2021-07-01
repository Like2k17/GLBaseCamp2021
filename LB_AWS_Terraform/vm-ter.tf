provider "aws" {
  access_key = "xxxxxxxxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  region     = "eu-central-1"
}

/**************************************************/
#       Create Virtual Machines
/**************************************************/

resource "aws_instance" "ubuntu_linux-vm1" {
  ami               = "ami-05f7491af5eef733a"
  instance_type     = "t2.micro"
  availability_zone = "eu-central-1a"
  security_groups   = ["${aws_security_group.ter-vm-sg.name}"]
  key_name          = "frankfurt-vm"
  user_data         = file("script_data.sh")

  tags = {
    Name = "terraform-vm1"
  }
}

resource "aws_instance" "ubuntu_linux-vm2" {
  ami               = "ami-05f7491af5eef733a"
  instance_type     = "t2.micro"
  availability_zone = "eu-central-1b"
  security_groups   = ["${aws_security_group.ter-vm-sg.name}"]
  key_name          = "frankfurt-vm"
  user_data         = file("script_data2.sh")

  tags = {
    Name = "terraform-vm2"
  }
}

/**************************************************/
#       Create Security Group
/**************************************************/

resource "aws_security_group" "ter-vm-sg" {
  name        = "ter-vm-sg"
  description = "Allow access to VMs from Terraform"
  vpc_id      = "vpc-e44ed48e"

  dynamic "ingress" {
    for_each = ["22", "80"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "egress" {
    for_each = ["22", "80"]
    content {
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

/**************************************************/
#       Create Load Balancer
/**************************************************/

#aws_alb_target_group
resource "aws_lb_target_group" "target-lb-tf" {
  name     = "tf-lb-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = "vpc-e44ed48e"
}

# aws_lb
resource "aws_lb" "lb-tf" {
  name               = "terraform-lb"
  internal           = false
  load_balancer_type = "network"

  subnets = ["subnet-85105def", "subnet-4cc27a30"]

  tags = {
    Environment = "Terraform-LB"
  }
}

# aws_lb_listener
resource "aws_lb_listener" "lb-tf" {
  load_balancer_arn = aws_lb.lb-tf.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.target-lb-tf.arn}"
    type             = "forward"
  }
}

# aws_lb_target_group_attachment
resource "aws_lb_target_group_attachment" "ec2-attach" {
  target_group_arn = aws_lb_target_group.target-lb-tf.arn
  port             = 80
  target_id        = "${aws_instance.ubuntu_linux-vm1.id}"
}

resource "aws_lb_target_group_attachment" "ec2-attach2" {
  target_group_arn = aws_lb_target_group.target-lb-tf.arn
  port             = 80
  target_id        = "${aws_instance.ubuntu_linux-vm2.id}"
}
