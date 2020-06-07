// Security groups
// lb
resource "aws_security_group" "lb" {
  name        = "${var.PROJECT}-${var.ENV}-alb"
  description = "Allows 443 inbound route & All outgoing"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// ECS task allows all outgoing, only 3000TCP incoming via ALB
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.PROJECT}-${var.ENV}-ecs"
  description = "Allow inbound route from the ALB & All outgoing"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = var.webserver_port
    to_port         = var.webserver_port
    security_groups = [aws_security_group.lb.id]
  }
  egress {
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

// Allows incoming traffic from airflow instance
resource "aws_security_group" "postgres" {
  name        = "${var.PROJECT}-${var.ENV}-postgres"
  description = "Security group which allows inbound only access from public subnet"
  vpc_id      = aws_vpc.main.id

 ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = aws_subnet.public[*].cidr_block
  }
  tags = {
    Name        = var.PROJECT
  }
}

resource "aws_security_group" "redis" {
    name        = "${var.PROJECT}-${var.ENV}-redis"
    description = "Allow all inbound traffic"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port   = 6379
        to_port     = 6379
        protocol    = "tcp"
        cidr_blocks = [var.IP_RANGE]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

}

resource "aws_security_group" "allow_outbound" {
  name        = "${var.PROJECT}-${var.ENV}-allow-outbound"
  description = "Security group which allows inbound only access from public subnet"
  vpc_id      = aws_vpc.main.id

  egress {
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    cidr_blocks     = ["0.0.0.0/0"]
  }

}


resource "aws_security_group" "workers" {
    name        = "${var.PROJECT}-${var.ENV}-workers"
    description = "Workers security group"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port = 8793
        to_port = 8793
        protocol = "tcp"
        cidr_blocks = [var.IP_RANGE]
    }

}


resource "aws_security_group" "flower" {
    name        = "${var.PROJECT}-${var.ENV}-flower"
    description = "Allow inbound traffic for Flower"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port = 5555
        to_port = 5555
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}