# outputs.tf
output "ecs_cluster_id" {
  value = aws_ecs_cluster.ecs_cluster.id
}

output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.backend_task.arn
}

output "ecs_service_id" {
  value = aws_ecs_service.backend_service.id
}
