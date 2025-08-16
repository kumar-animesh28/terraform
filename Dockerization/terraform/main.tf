data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "alb_sg" {
  vpc_id = data.aws_vpc.default.id
  name   = "alb-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = data.aws_vpc.default.id
  name   = "ecs-sg"

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "main" {
  name = "main-cluster"
}

resource "aws_lb" "alb" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "flask_tg" {
  name        = "flask-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
}

resource "aws_lb_target_group" "express_tg" {
  name        = "express-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "flask_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "express_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.express_tg.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_ecs_task_definition" "flask" {
  family                   = "flask-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::805149719871:role/ecsTaskExecutionRole"  # replace with yourclear role ARN

  container_definitions = jsonencode([
    {
      name      = "flask"
      image     = "805149719871.dkr.ecr.ap-south-1.amazonaws.com/flask-backend:latest" # replace with your image
      portMappings = [{ containerPort = 5000, hostPort = 5000 }]
    }
  ])
}

resource "aws_ecs_task_definition" "express" {
  family                   = "express-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::805149719871:role/ecsTaskExecutionRole"  # replace with yourclear role ARN

  container_definitions = jsonencode([
    {
      name      = "express"
      image     = "805149719871.dkr.ecr.ap-south-1.amazonaws.com/express-frontend:latest" # replace with your image
      portMappings = [{ containerPort = 3000, hostPort = 3000 }]
    }
  ])
}

resource "aws_ecs_service" "flask" {
  name            = "flask-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.flask.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.flask_tg.arn
    container_name   = "flask"
    container_port   = 5000
  }
}

resource "aws_ecs_service" "express" {
  name            = "express-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.express.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.express_tg.arn
    container_name   = "express"
    container_port   = 3000
  }
}
