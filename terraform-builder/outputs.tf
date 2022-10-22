output "ssh_private_key" {
  sensitive = true
  value     = tls_private_key.build_key.private_key_pem
}

output "ssh_public_key" {
  value = tls_private_key.build_key.public_key_pem
}

output "instance_ips" {
  sensitive = true
  value = [
    for inst in aws_instance.builder : inst.public_ip
  ]
}

output "s3_outputs" {
  value = [
    for arch in var.architectures_to_build : "webview-${var.chrome_version}-${arch}.apk.xz"
  ]
}

output "ci_aws_access_key_id" {
  sensitive = true
  value     = aws_iam_access_key.ci.id
}

output "ci_aws_secret_access_key" {
  sensitive = true
  value     = aws_iam_access_key.ci.secret
}

output "bucket_name" {
  value = local.bucket_name
}

output "chrome_version" {
  value = var.chrome_version
}

output "aws_region" {
  value = var.region
}
