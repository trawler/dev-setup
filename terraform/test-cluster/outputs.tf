
output "controllers-public-dns" {
  value = aws_eip.controller-ext.*.public_dns
}

output "controllers-fqdn" {
  value = aws_route53_record.cluster-controller-record[*].fqdn
}

output "controllers-private-ips" {
  value = aws_instance.cluster-controller[*].private_dns
}

output "worker-public-dns" {
  value = aws_instance.cluster-workers.*.public_dns
}

output "workers-fqdn" {
  value = aws_route53_record.cluster-worker-record[*].fqdn
}

output "worker-external-ip" {
  value = aws_instance.cluster-workers.*.public_ip
}
