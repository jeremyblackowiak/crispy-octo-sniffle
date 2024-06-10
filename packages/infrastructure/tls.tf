# resource "aws_route53_zone" "main" {
#   name = "example.com"
# }

# resource "aws_acm_certificate" "cert" {
#   domain_name       = "example.com"
#   validation_method = "DNS"
# }

# resource "aws_route53_record" "validation" {
#   name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
#   type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
#   zone_id = "${aws_route53_zone.main.zone_id}"
#   records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
#   ttl     = 60
# }

# resource "aws_acm_certificate_validation" "cert" {
#   certificate_arn         = "${aws_acm_certificate.cert.arn}"
#   validation_record_fqdns = ["${aws_route53_record.validation.fqdn}"]
# }