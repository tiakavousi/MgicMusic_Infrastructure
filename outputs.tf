# # outputs.tf
# output "ecs_cluster_id" {
#   value = aws_ecs_cluster.ecs_cluster.id
# }

# output "vpc_id" {
#   description = "The ID of the VPC"
#   value       = aws_vpc.main.id
# }

# output "public_subnet_1_id" {
#   description = "The ID of the first public subnet"
#   value       = aws_subnet.public_subnet_1.id
# }

# output "public_subnet_2_id" {
#   description = "The ID of the second public subnet"
#   value       = aws_subnet.public_subnet_2.id
# }

# output "internet_gateway_id" {
#   description = "The ID of the Internet Gateway"
#   value       = aws_internet_gateway.igw.id
# }

# output "public_route_table_id" {
#   description = "The ID of the public route table"
#   value       = aws_route_table.public_rt.id
# }

# output "ecs_security_group_id" {
#   description = "The ID of the ECS security group"
#   value       = aws_security_group.ecs_sg.id
# }

# output "ecs_task_execution_role_arn" {
#   description = "The ARN of the ECS task execution role"
#   value       = aws_iam_role.ecs_task_execution_role.arn
# }

# output "load_balancer_arn" {
#   description = "The ARN of the load balancer"
#   value       = aws_lb.alb.arn
# }

# output "target_group_arn" {
#   description = "The ARN of the target group"
#   value       = aws_lb_target_group.frontend_target_group.arn
# }

# output "alb_dns_name" {
#   description = "The DNS name of the ALB"
#   value       = aws_lb.alb.dns_name
# }