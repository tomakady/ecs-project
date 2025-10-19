output "domain_name" {
  description = "Domain name of the A record"
  value       = aws_route53_record.main.name
}

output "fqdn" {
  description = "Fully qualified domain name"
  value       = aws_route53_record.main.fqdn
}

output "record_id" {
  description = "ID of the Route53 record"
  value       = aws_route53_record.main.id
}
