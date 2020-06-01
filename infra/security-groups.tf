// Security groups
// lb
resource "aws_security_group" "lb" {
  name        = "${var.PROJECT}-${var.ENV}"
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
  name        = "${var.PROJECT}-${var.ENV}"
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
  name        = "db"
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
