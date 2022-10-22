variable "chrome_version" {
  type        = string
  description = "The version of Chrome to build"
  default     = "106.0.5249.126"
}

variable "architectures_to_build" {
  type        = list(string)
  description = "The architectures to build"
  default     = ["arm", "arm64", "x86", "x64"]
}

variable "instance_type" {
  type        = string
  description = "The instance type to use for the build"
  default     = "c5ad.16xlarge"
}

variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket to use for the build output"
  default     = "carbonrom-webview-out"
}

variable "parallel" {
  type        = bool
  description = "Whether to build in parallel"
  default     = true
}

variable "region" {
  type        = string
  description = "The region to use for the builder"
  default     = "us-east-2"
}
