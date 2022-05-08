provider "aws"{
    region = "ap-south-1"
}

//create sqs
resource "aws_sqs_queue" "terraform_sqs_queue" {
  name                      = "terraform-queue"
  max_message_size          = 2048
  message_retention_seconds = 86400
  tags = {
    environment = "test"
    name="terraform-queue"
  }
}
//create lambda from code given
data "archive_file" "first_archieve_file" {
  type        = "zip"
  source_file = "${path.module}/lambda_code/first_lambda.py"
  output_path = "${path.module}/lambda_code/first_lambda.zip"
}

resource "aws_lambda_function" "teraform-python-lambda" {
  function_name = "terraform-python-lambda"
  filename      = data.archive_file.first_archieve_file.output_path
  role          = aws_iam_role.first_lambda_role.arn
  handler       = "first_lambda.lambda_handler"
  source_code_hash = data.archive_file.first_archieve_file.output_base64sha256
  runtime       = "python3.9"

  environment {
    variables = {
      "key" = "value"
    }
  }
}

//create execution role
resource "aws_iam_role" "first_lambda_role" {
  name = "first_lambda_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "first_lambda_execution_role" {
  name        = "first_lambda_execution_role"
  description = "IAM policy for executing lambda from SQS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:*"
    },
    {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "*"
            ]
    },
    {
            "Effect": "Allow",
            "Action": [
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
    }

  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role" {
  role       = aws_iam_role.first_lambda_role.name
  policy_arn = aws_iam_policy.first_lambda_execution_role.arn
}

//create trigger
resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  batch_size        = 1
  event_source_arn  = "${aws_sqs_queue.terraform_sqs_queue.arn}"
  enabled           = true
  function_name     = "${aws_lambda_function.teraform-python-lambda.arn}"
}