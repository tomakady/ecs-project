output "zone_id" {
  value       = aws_route53_zone.main.zone_id
  description = "Route53 hosted zone ID"
}

output "name_servers" {
  value       = aws_route53_zone.main.name_servers
  description = "Name servers for the hosted zone"
}

output "app_domain" {
  value       = aws_route53_record.app.fqdn
  description = "Full domain name for the app"
}
