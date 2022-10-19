# chromium-webview Terraform

## What is this?

This is a [Terraform](https://www.terraform.io/) configuration to run the compilation process of Chromium's webview to parallel AWS instances, then upload the outputs to AWS S3 and shutdown.

This is intended to be used in tandem with the GitHub Actions workflows in `.github/workflows` to help keep the maintenance burden of Chromium's webview binaries down.
