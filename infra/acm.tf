// Get the data for hosted zone
data "aws_route53_zone" "zone" {
  name         = "${var.hosted_zone_name}."
  private_zone = false
}

resource "aws_acm_certificate" "certificate" {
  domain_name       = "airflow.${var.hosted_zone_name}"
  validation_method = "DNS"

  tags = {
    Name = var.PROJECT
  }
}
// Cert Validation here
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = aws_route53_record.airflow.*.fqdn
  depends_on = [aws_acm_certificate.certificate]
}

resource "aws_route53_record" "airflow" {
  name    = aws_acm_certificate.certificate.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.certificate.domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.zone.id
  records = [aws_acm_certificate.certificate.domain_validation_options.0.resource_record_value]
  ttl     = 60
  # depends_on = [aws_acm_certificate_validation.cert_validation]
}


//resource "aws_route53_record" "load_balancer" {
//  name    = "${var.project}.${var.hosted_zone_name}"
//  zone_id = data.aws_route53_zone.zone.zone_id
//  type    = "CNAME"
//
//  alias {
//    name                   = aws_alb.airflow.dns_name
//    zone_id                = aws_alb.airflow.zone_id
//    evaluate_target_health = true
//  }
//}