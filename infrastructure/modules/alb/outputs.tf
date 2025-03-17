output "alb_arn" {
  value       = aws_lb.grocery_alb.arn
  description = "ARN of the ALB"
}

output "target_group_arn" {
  value       = aws_lb_target_group.grocery_alb_tg.arn
  description = "ARN of the Target Group"
}

output "alb_dns_name" {
  value       = aws_lb.grocery_alb.dns_name
  description = "DNS name of the ALB"
}