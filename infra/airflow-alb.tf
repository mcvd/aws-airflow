// Resources:
// Aplication load balacner (ALB), ALB target group, ALB listener
resource "aws_alb" "airflow" {
  name               = "${var.PROJECT}-${var.ENV}"
  load_balancer_type = "application"
  subnets            = aws_subnet.public.*.id
  security_groups    = [aws_security_group.lb.id]

  tags = {
    Name = "${var.PROJECT}-alb"
    Env  = var.ENV
  }
}

resource "aws_alb_target_group" "airflow" {
  name        = var.PROJECT
  port        = var.webserver_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  // TODO: Read upon health checks
  health_check {
    interval = 20
    port = var.webserver_port
    protocol = "HTTP"
    path = "/health"
    matcher             = "200"
    timeout = 5
    healthy_threshold = 5
    unhealthy_threshold = 3
  }
}

// Forward all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.airflow.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.airflow.arn
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
// Forward all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end_ssl" {
  load_balancer_arn = aws_alb.airflow.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.certificate.arn
  default_action {
    target_group_arn = aws_alb_target_group.airflow.arn
    type             = "forward"
  }
  depends_on = [aws_acm_certificate.certificate]
}
resource "aws_lb_listener_certificate" "ssl_cert" {
  listener_arn    = aws_alb_listener.front_end_ssl.arn
  certificate_arn = aws_acm_certificate.certificate.arn
}