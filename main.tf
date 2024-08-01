provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "ecs_vpc"
  }
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# SUBNETS
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_1_cidr
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true
  tags = {
    Name = "public1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_2_cidr
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = true

  tags = {
    Name = "public2"
  }
}

# SECURITY GROUP
resource "aws_security_group" "ecs_sg" {
  name        = "ecs_sg"
  description = "Allow traffic to ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-sg"
  }
}

# CLOUDWATCH LOGS
resource "aws_cloudwatch_log_group" "ecs_backend" {
  name = "/ecs/backend"
}

resource "aws_cloudwatch_log_group" "ecs_frontend" {
  name = "/ecs/frontend"
}

resource "aws_cloudwatch_log_group" "ecs_db" {
  name = "/ecs/db"
}

# ECS CLUSTER
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "My_ecs-cluster"
}

# ECS IAM ROLE
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_task_execution_policy" {
  name       = "ecs-task-execution-policy"
  roles      = [aws_iam_role.ecs_task_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS TASK DEFINITIONS
resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name         = "db"
      image        = var.db_container_image
      essential    = true
      portMappings = [{
        containerPort = 3306
      }]
      environment = [
        {
          name  = "MYSQL_ROOT_PASSWORD"
          value = var.mysql_root_password
        },
        {
          name  = "MYSQL_USER"
          value = var.mysql_user
        },
        {
          name  = "MYSQL_PASSWORD"
          value = var.mysql_password
        },
        {
          name  = "MYSQL_DATABASE"
          value = var.mysql_database
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_db.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name         = "backend"
      image        = var.backend_container_image
      essential    = true
      portMappings = [{
        containerPort = 5000
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name         = "frontend"
      image        = var.frontend_container_image
      essential    = true
      portMappings = [{
        containerPort = 3000
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
  depends_on = [
    aws_cloudwatch_log_group.ecs_backend,
    aws_cloudwatch_log_group.ecs_frontend,
    aws_cloudwatch_log_group.ecs_db
  ]
}

# APPLICATION LOAD BALANCER
resource "aws_lb" "alb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]
}

resource "aws_lb_target_group" "frontend_target_group" {
  name     = "frontend-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"
}


resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_target_group.arn
  }
}

# ECS SERVICES
resource "aws_ecs_service" "my_app_service" {
  name            = "my-app-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [
      aws_subnet.public_subnet_1.id,
      aws_subnet.public_subnet_2.id
    ]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.frontend_service.arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_target_group.arn
    container_name   = "frontend"
    container_port   = 3000
  }
  deployment_controller {
    type = "CODE_DEPLOY"
  }
}

resource "aws_ecs_service" "backend-db_service" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.backend-db_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [
      aws_subnet.public_subnet_1.id,
      aws_subnet.public_subnet_2.id
    ]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
  
  deployment_controller {
    type = "CODE_DEPLOY"
  }
}

######################################################################
# AWS CODEDEPLOY
######################################################################

resource "aws_codedeploy_app" "my_app" {
  name = "my-app"
  compute_platform = "ECS"
}

# CODEDEPLOY IAM ROLE
resource "aws_iam_role" "codedeploy_role" {
  name = "CodeDeployRole"

  assume_role_policy = jsonencode( {
   "Version": "2012-10-17",
   "Statement": [
     {
       "Sid": "",
       "Effect": "Allow",
       "Principal": {
         "Service": [
           "codedeploy.amazonaws.com"
         ]
       },
       "Action": "sts:AssumeRole"
     }
   ]
 })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role     = aws_iam_role.codedeploy_role.name
}
resource "aws_iam_policy_attachment" "codedeploy_ecs_read_only_policy" {
  name       = "codedeploy-ecs-read-only-policy"
  roles      = [aws_iam_role.codedeploy_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_policy" "codedeploy_ecs_policy" {
  name        = "CodeDeployECSPolicy"
  description = "Policy for CodeDeploy to describe ECS services"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:DescribeServices",
          "ecs:ListServices"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "codedeploy_ecs_policy_attachment" {
  name       = "codedeploy-ecs-policy-attachment"
  roles      = [aws_iam_role.codedeploy_role.name]
  policy_arn = aws_iam_policy.codedeploy_ecs_policy.arn
}

# CODEDEPLOY DEPLOYMENT GROUP FOR FRONTEND
resource "aws_codedeploy_deployment_group" "frontend_deployment_group" {
  app_name              = aws_codedeploy_app.my_app.name
  deployment_group_name = "frontend-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeploy.ECSBlueGreen"
  
  ecs_service {
    cluster_name = aws_ecs_cluster.ecs_cluster.name
    service_name = aws_ecs_service.frontend_service.name
  }

  # deployment_style {
  #   deployment_type = "BLUE_GREEN"
  #   deployment_option = "WITH_TRAFFIC_CONTROL"
  # }

  # auto_rollback_configuration {
  #   enabled = true
  #   events  = ["DEPLOYMENT_FAILURE"]
  # }

  # blue_green_deployment_config {
  #   deployment_ready_option {
  #     action_on_timeout = "CONTINUE_DEPLOYMENT"
  #   }

  #   terminate_blue_instances_on_deployment_success {
  #     action                           = "TERMINATE"
  #     termination_wait_time_in_minutes = 5
  #   }
  # }

  load_balancer_info {
    elb_info {
      name = aws_lb.alb.name
    }
  }

  tags = {
    Name = "frontend-deployment-group"
  }
}

# CODEDEPLOY CODEDEPLOYMENT GROUP FOR BACKEND-DB
# resource "aws_codedeploy_deployment_group" "backend_db_deployment_group" {
#   app_name              = aws_codedeploy_app.my_app.name
#   deployment_group_name = "backend-db-deployment-group"
#   service_role_arn      = aws_iam_role.codedeploy_role.arn
#   deployment_config_name = "CodeDeploy.ECSBlueGreen"
  
#   ecs_service {
#     cluster_name = aws_ecs_cluster.ecs_cluster.name
#     service_name = aws_ecs_service.backend-db_service.name
#   }

#   deployment_style {
#     deployment_type = "BLUE_GREEN"
#     deployment_option = "WITH_TRAFFIC_CONTROL"
#   }

#   auto_rollback_configuration {
#     enabled = true
#     events  = ["DEPLOYMENT_FAILURE"]
#   }

#   blue_green_deployment_config {
#     deployment_ready_option {
#       action_on_timeout = "CONTINUE_DEPLOYMENT"
#     }

#     terminate_blue_instances_on_deployment_success {
#       action                           = "TERMINATE"
#       termination_wait_time_in_minutes = 5
#     }
#   }

#   tags = {
#     Name = "backend-db-deployment-group"
#   }
# }

# resource "aws_codedeploy_deployment_config" "blue_green" {
#   deployment_config_name = "CodeDeploy.ECSBlueGreen"
#   minimum_healthy_hosts {
#     type  = "HOST_COUNT"
#     value = 1
#   }
# }
