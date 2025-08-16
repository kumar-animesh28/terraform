output "public_ip" {
  value       = aws_instance.app.public_ip
  description = "EC2 public IP"
}

output "app_url" {
  value       = "http://${aws_instance.app.public_ip}/"
  description = "Main App URL"
}

output "api_url" {
  value       = "http://${aws_instance.app.public_ip}/api/"
  description = "Backend API URL"
}