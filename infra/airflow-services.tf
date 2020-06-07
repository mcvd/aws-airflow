// ECS resources
// Defined in the topological order:
// CLUSTER -> SERVICE -> TASK -> CONTAINER

data "aws_ecr_repository" "airflow" {
  name = var.PROJECT
}

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
    security_groups  = [aws_security_group.ecs_tasks.id, aws_security_group.allow_outbound.id, aws_security_group.lb.id]
    subnets          = aws_subnet.public.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.airflow.arn
    container_name   = var.PROJECT
    container_port   = var.webserver_port
  }

  depends_on = [aws_alb_listener.front_end_ssl, aws_db_instance.postgresql, aws_elasticache_cluster.redis]
}

resource "aws_ecs_service" "scheduler_service" {
    name            = "${var.PROJECT}-${var.ENV}-scheduler"
    cluster         = aws_ecs_cluster.airflow.id
    task_definition = aws_ecs_task_definition.scheduler.arn
    desired_count   = 1
    launch_type     = "FARGATE"

    network_configuration {
      security_groups = [aws_security_group.allow_outbound.id]
      subnets         = aws_subnet.private.*.id
    }

    depends_on = [aws_db_instance.postgresql, aws_elasticache_cluster.redis]
}

resource "aws_ecs_service" "workers" {
    name            = "${var.PROJECT}-${var.ENV}-workers"
    cluster         = aws_ecs_cluster.airflow.id
    task_definition = aws_ecs_task_definition.workers.arn
    desired_count   = 2
    launch_type     = "FARGATE"

    network_configuration {
      security_groups = [aws_security_group.allow_outbound.id, aws_security_group.workers.id]
      subnets         = aws_subnet.private.*.id
    }

  depends_on = [aws_db_instance.postgresql, aws_elasticache_cluster.redis]
}

resource "aws_ecs_service" "flower_service" {
    name            = "${var.PROJECT}-${var.ENV}-flower"
    cluster         = aws_ecs_cluster.airflow.id
    task_definition = aws_ecs_task_definition.flower.arn
    desired_count   = 1
    launch_type     = "FARGATE"

    network_configuration {
      security_groups = [aws_security_group.allow_outbound.id, aws_security_group.flower.id]
      subnets         = aws_subnet.private.*.id
    }

  depends_on = [aws_db_instance.postgresql, aws_elasticache_cluster.redis]
}