// https://github.com/aws-samples/aws-containers-task-definitions
resource "aws_ecs_task_definition" "webserver" {
  family                   = var.PROJECT
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_task.arn
  depends_on               = [aws_db_instance.postgresql]
  container_definitions    = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${data.aws_ecr_repository.airflow.repository_url}:latest",
    "memory": ${var.fargate_memory},
    "name": "${var.PROJECT}",
    "networkMode": "awsvpc",
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/${var.PROJECT}/${var.ENV}",
        "awslogs-region": "${var.AWS_REGION}",
        "awslogs-stream-prefix": "ecs-webserver"
      }
    },
    "command": [ "webserver"],
    "environment": [
      {"name": "REDIS_HOST",
      "value": "${aws_elasticache_cluster.redis.cache_nodes.0.address}"},

      {"name": "REDIS_PORT",
      "value": "6379"},

      {"name":"POSTGRES_DB",
      "value":"airflow"},

      {"name":"POSTGRES_PORT",
      "value":"${aws_db_instance.postgresql.port}"},

      {"name":"POSTGRES_USER",
      "value":"${aws_db_instance.postgresql.username}"},

      {"name":"POSTGRES_PASSWORD",
      "value":"${random_password.password.result}"},

      {"name":"POSTGRES_HOST",
      "value":"${aws_db_instance.postgresql.address}"},

      {"name": "FERNET_KEY",
      "value": "oe_LWeTnrbbbLX9pIYNjpGTPQUy7uYu0OxEqP16fvu4="},

      {"name": "AIRFLOW_BASE_URL",
      "value": "http://localhost:8080"},

      {"name": "ENABLE_REMOTE_LOGGING",
      "value": "False"},

      {"name": "STAGE",
      "value": "${var.ENV}"}
      ],
    "portMappings": [
      {
        "containerPort": ${var.webserver_port},
        "hostPort": ${var.webserver_port}
      }
    ],
    "ulimits": [
      {
        "name": "nofile",
        "softLimit": 32000,
        "hardLimit": 32000
      }
    ]
  }
]
DEFINITION
}


resource "aws_ecs_task_definition" "scheduler" {
  family                   = "${var.PROJECT}-${var.ENV}-scheduler"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = <<EOF
[
  {
    "name": "scheduler",
    "image": "${data.aws_ecr_repository.airflow.repository_url}:latest",
    "essential": true,
    "command": ["scheduler"],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/${var.PROJECT}/${var.ENV}",
        "awslogs-region": "${var.AWS_REGION}",
        "awslogs-stream-prefix": "scheduler"
      }
    },
    "environment": [
      {"name": "REDIS_HOST",
      "value": "${aws_elasticache_cluster.redis.cache_nodes.0.address}"},

      {"name": "REDIS_PORT",
      "value": "6379"},

      {"name":"POSTGRES_DB",
      "value":"airflow"},

      {"name":"POSTGRES_PORT",
      "value":"${aws_db_instance.postgresql.port}"},

      {"name":"POSTGRES_USER",
      "value":"${aws_db_instance.postgresql.username}"},

      {"name":"POSTGRES_PASSWORD",
      "value":"${random_password.password.result}"},

      {"name":"POSTGRES_HOST",
      "value":"${aws_db_instance.postgresql.address}"},

      {"name": "FERNET_KEY",
      "value": "oe_LWeTnrbbbLX9pIYNjpGTPQUy7uYu0OxEqP16fvu4="},

      {"name": "AIRFLOW_BASE_URL",
      "value": "http://localhost:8080"},

      {"name": "ENABLE_REMOTE_LOGGING",
      "value": "False"},

      {"name": "ENV",
      "value": "${var.ENV}"}
      ]
  }
]
EOF
}

resource "aws_ecs_task_definition" "workers" {
  family                   = "${var.PROJECT}-${var.ENV}-workers"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions = <<EOF
[
  {
    "name": "workers",
    "image": "${data.aws_ecr_repository.airflow.repository_url}:latest",
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/${var.PROJECT}/${var.ENV}",
        "awslogs-region": "${var.AWS_REGION}",
        "awslogs-stream-prefix": "workers"
      }
    },
    "portMappings": [
      {"containerPort": 8793,
       "hostPort"     : 8793}
    ],
    "command": ["worker"],
    "environment": [
      {"name": "REDIS_HOST",
      "value": "${aws_elasticache_cluster.redis.cache_nodes.0.a}"},

      {"name": "REDIS_PORT",
      "value": "6379"},

      {"name":"POSTGRES_DB",
      "value":"airflow"},

      {"name":"POSTGRES_PORT",
      "value":"${aws_db_instance.postgresql.port}"},

      {"name":"POSTGRES_USER",
      "value":"${aws_db_instance.postgresql.username}"},

      {"name":"POSTGRES_PASSWORD",
      "value":"${random_password.password.result}"},

      {"name":"POSTGRES_HOST",
      "value":"${aws_db_instance.postgresql.address}"},

      {"name": "FERNET_KEY",
      "value": "oe_LWeTnrbbbLX9pIYNjpGTPQUy7uYu0OxEqP16fvu4="},

      {"name": "AIRFLOW_BASE_URL",
      "value": "http://localhost:8080"},

      {"name": "ENABLE_REMOTE_LOGGING",
      "value": "False"},

      {"name": "ENV",
      "value": "${var.ENV}"}
      ]
  }
]
EOF
}

resource "aws_ecs_task_definition" "flower" {
  family                   = "${var.PROJECT}-${var.ENV}-flower"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions = <<EOF
[
  {
    "name": "flower",
    "image": "${data.aws_ecr_repository.airflow.repository_url}:latest",
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/${var.PROJECT}/${var.ENV}",
        "awslogs-region": "${var.AWS_REGION}",
        "awslogs-stream-prefix": "flower"
      }
    },
    "portMappings": [
      {"containerPort": 5555,
       "hostPort"     : 5555}
    ],
    "command": ["flower"],
    "environment": [
      {"name": "REDIS_HOST",
      "value": "${aws_elasticache_cluster.redis.cache_nodes.0.address}"},

      {"name": "REDIS_PORT",
      "value": "6379"},

      {"name":"POSTGRES_DB",
      "value":"airflow"},

      {"name":"POSTGRES_PORT",
      "value":"${aws_db_instance.postgresql.port}"},

      {"name":"POSTGRES_USER",
      "value":"${aws_db_instance.postgresql.username}"},

      {"name":"POSTGRES_PASSWORD",
      "value":"${random_password.password.result}"},

      {"name":"POSTGRES_HOST",
      "value":"${aws_db_instance.postgresql.address}"},

      {"name": "FERNET_KEY",
      "value": "oe_LWeTnrbbbLX9pIYNjpGTPQUy7uYu0OxEqP16fvu4="},

      {"name": "AIRFLOW_BASE_URL",
      "value": "http://localhost:8080"},

      {"name": "ENABLE_REMOTE_LOGGING",
      "value": "False"},

      {"name": "ENV",
      "value": "${var.ENV}"}
      ]
  }
]
EOF
}