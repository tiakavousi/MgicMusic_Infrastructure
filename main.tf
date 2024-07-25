
provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "main-public-rt"
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

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "main-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.11.0/24" 
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "main-public-subnet-2"
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs_sg"
  description = "Allow traffic to ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
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

# resource "aws_lb" "app_lb" {
#   name               = "app-lb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.lb_sg.id]
#   subnets            = [
#     aws_subnet.public_subnet_1.id,
#     aws_subnet.public_subnet_2.id
#   ]
# }

# resource "aws_lb_target_group" "backend_tg" {
#   name     = "backend-tg"
#   port     = 5000
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.main.id
#   target_type = "ip"

#   health_check {
#     path                = "/"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     matcher             = "200-299"
#   }
# }

# resource "aws_lb_listener" "frontend_listener" {
#   load_balancer_arn = aws_lb.app_lb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.backend_tg.arn
#   }
# }

resource "aws_cloudwatch_log_group" "ecs_backend" {
  name = "/ecs/backend"

  tags = {
    Name = "ecs-backend-log-group"
  }
}

resource "aws_cloudwatch_log_group" "ecs_frontend" {
  name = "/ecs/frontend"

  tags = {
    Name = "ecs-frontend-log-group"
  }
}

resource "aws_cloudwatch_log_group" "ecs_db" {
  name = "/ecs/db"

  tags = {
    Name = "ecs-db-log-group"
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "my-ecs-cluster"

  tags = {
    Name = "ecs-cluster"
  }
}

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

  tags = {
    Name = "ecs-task-execution-role"
  }
}

resource "aws_iam_policy_attachment" "ecs_task_execution_policy" {
  name       = "ecs-task-execution-policy"
  roles      = [aws_iam_role.ecs_task_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_ecs_task_definition" "backend_task" {
  family                   = "backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "docker.io/tayebe/magicmusic-be:main"
      essential = false
      portMappings = [{
        containerPort = 5000
      }]
      environment = [
        {
          name  = "SQLALCHEMY_DATABASE_URI"
          value = "mysql+pymysql://user:password@127.0.0.1:3306/musics_db"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      dependsOn = [
        {
          containerName = "db"
          condition     = "START"
        }
      ]
    },
    {
      name      = "frontend"
      image     = "docker.io/tayebe/magicmusic-fe:main"
      essential = false
      portMappings = [{
        containerPort = 3000
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name      = "db"
      image     = "docker.io/mysql:8.0"
      essential = true
      portMappings = [{
        containerPort = 3306
      }]
      environment = [
        {
          name  = "MYSQL_ROOT_PASSWORD"
          value = "rootpassword"
        },
        {
          name  = "MYSQL_USER"
          value = "user"
        },
        {
          name  = "MYSQL_PASSWORD"
          value = "password"
        },
        {
          name  = "MYSQL_DATABASE"
          value = "musics_db"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_db.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "backend-task"
  }
  depends_on = [
    aws_cloudwatch_log_group.ecs_backend,
    aws_cloudwatch_log_group.ecs_frontend,
    aws_cloudwatch_log_group.ecs_db
  ]
}


resource "aws_ecs_service" "backend_service" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.backend_task.arn
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

  tags = {
    Name = "backend-service"
  }

  # load_balancer {
  #   target_group_arn = aws_lb_target_group.backend_tg.arn
  #   container_name   = "backend"
  #   container_port   = 5000
  # }

  # depends_on = [
  #   aws_lb.app_lb,
  #   aws_lb_listener.frontend_listener
  # ]
}











