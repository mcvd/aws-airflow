// ECS resources
// Defined in the topological order:
// CLUSTER -> SERVICE -> TASK -> CONTAINER

resource "aws_ecs_cluster" "airflow" {
  name = "${var.PROJECT}-${var.ENV}"
}

// https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service_definition_parameters.html
resource "aws_ecs_service" "webserver" {
  name             = var.PROJECT
  cluster          = aws_ecs_cluster.airflow.id
  task_definition  = aws_ecs_task_definition.webserver.arn
  desired_count    = var.webserver_count
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.public.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.airflow.arn
    container_name   = var.PROJECT
    container_port   = var.webserver_port
  }

  depends_on = [aws_alb_listener.front_end_ssl]
}