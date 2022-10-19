// This file contains resources that are used by the CI/CD pipeline

// Create an AWS user that will be used by the CI/CD pipeline to download from the bucket
resource "aws_iam_user" "ci" {
  name = "ci-${local.resource_name}"
}

// Create an access key for the CI/CD pipeline user
resource "aws_iam_access_key" "ci" {
  user = aws_iam_user.ci.name
}

// Create a policy that allows the CI/CD pipeline user to download from the bucket
resource "aws_iam_policy" "ci" {
  name        = "ci-${local.resource_name}"
  description = "Policy for the CI/CD pipeline user"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GetObjectsInBucket",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectAttributes",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${local.bucket_name}/*",
        "arn:aws:s3:::${local.bucket_name}"
      ]
    }
  ]
}
EOF
}

// Attach the policy to the CI/CD pipeline user
resource "aws_iam_user_policy_attachment" "ci" {
  user       = aws_iam_user.ci.name
  policy_arn = aws_iam_policy.ci.arn
}
