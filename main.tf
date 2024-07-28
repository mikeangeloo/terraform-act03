provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "app_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1c"
}

resource "aws_subnet" "db_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_security_group" "app_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "db_instance" {
  ami                         = "ami-04a81a99f5ec58529" # AMI de Ubuntu
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.db_subnet.id
  vpc_security_group_ids      = [aws_security_group.db_sg.id]
  associate_public_ip_address = true
  key_name                    = "UNIR-DEVOPS"

  tags = {
    Name = "mean-db"
  }
}

resource "aws_instance" "app_instance" {
  ami                         = "ami-04a81a99f5ec58529" # AMI de Ubuntu
  instance_type               = "t3a.small"
  subnet_id                   = aws_subnet.app_subnet.id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true
  key_name                    = "UNIR-DEVOPS"

  tags = {
    Name = "mean-app"
  }

  depends_on = [aws_instance.db_instance]
}
resource "null_resource" "db_setup" {
  # Crear el directorio de destino en la máquina remota antes de copiar el archivo
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ubuntu/code/scripts"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/UNIR-DEVOPS.pem")
      host        = aws_instance.db_instance.public_ip
      timeout     = "5m"
      agent       = false
    }
  }

  # Copiar el archivo de script a la máquina remota
  provisioner "file" {
    source      = "${path.module}/scripts/mongodb-setup.sh"
    destination = "/home/ubuntu/code/scripts/mongodb-setup.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/UNIR-DEVOPS.pem")
      host        = aws_instance.db_instance.public_ip
      timeout     = "5m"
      agent       = false
    }
  }

  # Ejecutar el script remoto
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/code/scripts/mongodb-setup.sh",
      "/home/ubuntu/code/scripts/mongodb-setup.sh"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/UNIR-DEVOPS.pem")
      host        = aws_instance.db_instance.public_ip
      timeout     = "5m"
      agent       = false
    }
  }

  depends_on = [
    aws_instance.db_instance
  ]
}
resource "null_resource" "app_setup" {

   provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ubuntu/code/scripts"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/UNIR-DEVOPS.pem")
      host        = aws_instance.app_instance.public_ip
      timeout     = "1m"
      agent       = false
    }
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/app-setup.sh.tpl", {
      db_host = aws_instance.db_instance.private_ip
    })
    destination = "/home/ubuntu/code/scripts/app-setup.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/UNIR-DEVOPS.pem")
      host        = aws_instance.app_instance.public_ip
      timeout     = "4m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/code/scripts/app-setup.sh",
      "/home/ubuntu/code/scripts/app-setup.sh"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/UNIR-DEVOPS.pem")
      host        = aws_instance.app_instance.public_ip
      timeout     = "8m"
    }
  }

  depends_on = [
    aws_instance.app_instance,
    null_resource.db_setup
  ]
}

### Balanceador de carga
# Creamos el target group para asociar las instancias EC2
resource "aws_lb_target_group" "app_target_group" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance"

  health_check {
    interval            = 30
    path                = "/"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# Creamos el load balancer
resource "aws_lb" "app_lb" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_sg.id]
  subnets            = [aws_subnet.app_subnet.id, aws_subnet.db_subnet.id]

  enable_deletion_protection = false
  idle_timeout = 60
}

# Creamos el listener
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

# Asociamos las intancias EC2 al target group
resource "aws_lb_target_group_attachment" "app_instance_attachment" {
  target_group_arn = aws_lb_target_group.app_target_group.arn
  target_id        = aws_instance.app_instance.id
  port             = 80
}

