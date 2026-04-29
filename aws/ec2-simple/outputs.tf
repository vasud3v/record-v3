output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.goondvr.id
}

output "instance_public_ip" {
  description = "EC2 instance public IP"
  value       = aws_eip.goondvr.public_ip
}

output "instance_public_dns" {
  description = "EC2 instance public DNS"
  value       = aws_eip.goondvr.public_dns
}

output "web_url" {
  description = "GoondVR web interface URL"
  value       = "http://${aws_eip.goondvr.public_ip}:8080"
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = "ssh -i your-key.pem ubuntu@${aws_eip.goondvr.public_ip}"
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.goondvr.id
}
