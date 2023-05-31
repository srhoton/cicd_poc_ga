resource "aws_ecs_cluster" "cicd_poc" {
  name = "cicd_poc"
}

resource "aws_ecs_cluster_capacity_providers" "cicd_poc_provider" {
  cluster_name = aws_ecs_cluster.cicd_poc.name
  capacity_providers = ["FARGATE"]
}

data "aws_iam_policy_document" "cicd_poc_assume_by_ecs" {
  statement {
    sid     = "AllowAssumeByEcsTasks"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cicd_poc_execution_role" {
  statement {
    sid    = "AllowECRPull"
    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:*",
    ]

    resources = [aws_ecr_repository.cicd_poc.arn]
  }

  statement {
    sid    = "AllowECRAuth"
    effect = "Allow"

    actions = ["ecr:GetAuthorizationToken"]

    resources = ["*"]
  }

  statement {
    sid    = "AllowLogging"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "cicd_poc_task_role" {
  statement {
    sid    = "AllowDescribeCluster"
    effect = "Allow"

    actions = ["ecs:DescribeClusters","ecr:*"]

    resources = [aws_ecs_cluster.cicd_poc.arn]
  }
}

resource "aws_iam_role" "cicd_poc_execution_role" {
  name               = "cicd-poc-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.cicd_poc_assume_by_ecs.json
}

resource "aws_iam_role_policy" "cicd_poc_execution_role" {
  role   = aws_iam_role.cicd_poc_execution_role.name
  policy = data.aws_iam_policy_document.cicd_poc_execution_role.json
}

resource "aws_iam_role" "cicd_poc_task_role" {
  name               = "cicd-poc-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.cicd_poc_assume_by_ecs.json
}

resource "aws_iam_role_policy" "cicd_poc_task_role" {
  role   = aws_iam_role.cicd_poc_task_role.name
  policy = data.aws_iam_policy_document.cicd_poc_task_role.json
}

resource "aws_ecs_task_definition" "cicd_poc_task_definition" {
  family = "cicd_poc_task_definition"
  network_mode = "awsvpc"
  execution_role_arn = aws_iam_role.cicd_poc_execution_role.arn
  task_role_arn = aws_iam_role.cicd_poc_task_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  container_definitions = jsonencode([
    {
      name = "cicd_poc"
      image = "sprhoto/red_machine:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort = 80
        }
      ]
    }
  ])
}

resource "aws_lb" "cicd_poc_lb" {
  name = "cicd-poc-lb"
  internal = false
  load_balancer_type = "application"
  subnets =  [data.aws_subnet.public_1.id, data.aws_subnet.public_2.id, data.aws_subnet.public_3.id]
  security_groups = [aws_security_group.cicd_poc_ecs_service.id]

  tags = {
    Name = "cicd_poc_lb"
    }
}

resource "aws_lb_target_group" "cicd_poc_target_group_one" {
  name = "cicd-poc-tg-one"
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = data.aws_vpc.cicd_poc.id
}

resource "aws_lb_target_group" "cicd_poc_target_group_two" {
  name = "cicd-poc-tg-two"
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = data.aws_vpc.cicd_poc.id
}
resource "aws_lb_listener" "cicd_poc_listener" {
  load_balancer_arn = aws_lb.cicd_poc_lb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.cicd_poc_target_group_one.arn
  }
}

resource "aws_security_group" "cicd_poc_ecs_service" {
  name = "cicd_poc_ecs_service"
  vpc_id = data.aws_vpc.cicd_poc.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "cicd_poc_ecs_service"
  }
}

resource "aws_ecs_service" "cicd_poc_service" {
  name = "cicd_poc_service"
  cluster = aws_ecs_cluster.cicd_poc.id
  task_definition = aws_ecs_task_definition.cicd_poc_task_definition.arn
  desired_count = 1
  launch_type = "FARGATE"
  network_configuration {
    subnets =  [data.aws_subnet.public_1.id, data.aws_subnet.public_2.id, data.aws_subnet.public_3.id]
    security_groups = [aws_security_group.cicd_poc_ecs_service.id]
    assign_public_ip = true
  }


  load_balancer {
    target_group_arn = aws_lb_target_group.cicd_poc_target_group_one.arn
    container_name = "cicd_poc"
    container_port = 80
  }
  deployment_controller {
      type = "ECS"
  }
}
