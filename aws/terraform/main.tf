terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC and Networking
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-2"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "goondvr" {
  name        = "${var.project_name}-sg"
  description = "Security group for GoondVR"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# EFS for persistent storage
resource "aws_efs_file_system" "goondvr" {
  creation_token = "${var.project_name}-efs"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${var.project_name}-efs"
  }
}

resource "aws_efs_mount_target" "goondvr_1" {
  file_system_id  = aws_efs_file_system.goondvr.id
  subnet_id       = aws_subnet.public_1.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "goondvr_2" {
  file_system_id  = aws_efs_file_system.goondvr.id
  subnet_id       = aws_subnet.public_2.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "efs" {
  name        = "${var.project_name}-efs-sg"
  description = "Security group for EFS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "NFS from ECS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.goondvr.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-efs-sg"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = var.project_name
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "goondvr" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = var.project_name
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Secrets Manager for sensitive configuration
resource "aws_secretsmanager_secret" "goondvr_config" {
  name        = "${var.project_name}-config"
  description = "GoondVR configuration secrets"

  tags = {
    Name = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "goondvr_config" {
  secret_id = aws_secretsmanager_secret.goondvr_config.id
  secret_string = jsonencode({
    gofile_api_token = var.gofile_api_token
    gofile_folder_id = var.gofile_folder_id
    admin_username   = var.admin_username
    admin_password   = var.admin_password
    supabase_url     = var.supabase_url
    supabase_api_key = var.supabase_api_key
  })
}

resource "aws_iam_role_policy" "ecs_task_secrets" {
  name = "${var.project_name}-secrets-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.goondvr_config.arn
        ]
      }
    ]
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "goondvr" {
  family                   = var.project_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "goondvr"
      image     = var.docker_image
      essential = true

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "GOFILE_ENABLED"
          value = "true"
        },
        {
          name  = "GOFILE_DELETE_AFTER_UPLOAD"
          value = "true"
        },
        {
          name  = "SUPABASE_ENABLED"
          value = tostring(var.supabase_enabled)
        },
        {
          name  = "SUPABASE_TABLE_NAME"
          value = var.supabase_table_name
        }
      ]

      secrets = [
        {
          name      = "GOFILE_API_TOKEN"
          valueFrom = "${aws_secretsmanager_secret.goondvr_config.arn}:gofile_api_token::"
        },
        {
          name      = "GOFILE_FOLDER_ID"
          valueFrom = "${aws_secretsmanager_secret.goondvr_config.arn}:gofile_folder_id::"
        },
        {
          name      = "ADMIN_USERNAME"
          valueFrom = "${aws_secretsmanager_secret.goondvr_config.arn}:admin_username::"
        },
        {
          name      = "ADMIN_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.goondvr_config.arn}:admin_password::"
        },
        {
          name      = "SUPABASE_URL"
          valueFrom = "${aws_secretsmanager_secret.goondvr_config.arn}:supabase_url::"
        },
        {
          name      = "SUPABASE_API_KEY"
          valueFrom = "${aws_secretsmanager_secret.goondvr_config.arn}:supabase_api_key::"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "videos"
          containerPath = "/usr/src/app/videos"
        },
        {
          sourceVolume  = "conf"
          containerPath = "/usr/src/app/conf"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.goondvr.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  volume {
    name = "videos"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.goondvr.id
      root_directory     = "/videos"
      transit_encryption = "ENABLED"
    }
  }

  volume {
    name = "conf"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.goondvr.id
      root_directory     = "/conf"
      transit_encryption = "ENABLED"
    }
  }

  tags = {
    Name = var.project_name
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# ECS Service
resource "aws_ecs_service" "goondvr" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.goondvr.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.goondvr.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "goondvr"
    container_port   = 8080
  }

  depends_on = [
    aws_lb_listener.main,
    aws_efs_mount_target.goondvr_1,
    aws_efs_mount_target.goondvr_2
  ]

  tags = {
    Name = var.project_name
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
