output "ecs_service_name" {
  value = aws_ecs_service.nginx.name
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.this.id
}
