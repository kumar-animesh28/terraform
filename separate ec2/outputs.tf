# Backend instance outputs
output "backend_public_ip" {
  value       = aws_instance.backend.public_ip
  description = "Backend EC2 public IP"
}

# Frontend instance outputs
output "frontend_public_ip" {
  value       = aws_instance.frontend.public_ip
  description = "Frontend EC2 public IP"
}

output "frontend_url" {
  value       = "http://${aws_instance.frontend.public_ip}/"
  description = "Frontend App URL"
}