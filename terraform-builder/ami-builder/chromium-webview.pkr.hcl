packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "chromium-webview-cr11-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  instance_type = "c5ad.16xlarge"
  region        = "us-east-2"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"

  launch_block_device_mappings {
    device_name = "/dev/xvda"
    volume_size = 100
    volume_type = "gp2"
  }

  ena_support = true
  ami_virtualization_type = "hvm"
}

build {
  name = "chromium-webview-cr11"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    inline = [
      "set -xe",
      "sleep 30",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get -y -o DPkg::Lock::Timeout=300 update",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get -y -o DPkg::Lock::Timeout=300 upgrade",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get -y -o DPkg::Lock::Timeout=300 install --no-install-recommends git awscli",
      "git config --global user.name 'CarbonROM Webview CI Bot'",
      "git config --global user.email 'carbonrom_webview_ci_bot@mcswain.dev'",
      "sudo mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/nvme2n1 /dev/nvme3n1",
      "sudo mkfs.ext4 -F /dev/md0",
      "sudo mkfs.ext4 -F /dev/nvme1n1",
      "sudo mkdir -p /mnt/src",
      "sudo mkdir -p /mnt/md0",
      "sudo mount /dev/nvme1n1 /mnt/src",
      "sudo mount /dev/md0 /mnt/md0",
      "sudo chmod 777 /mnt/src",
      "sudo chmod 777 /mnt/md0",
      "git clone --progress https://github.com/CarbonROM/android_external_chromium-webview.git -b cr-11.0 /mnt/md0/chromium-webview 2>&1",
      "cd /mnt/md0/chromium-webview && ./build-webview.sh -s -b",
      "mv /mnt/md0/chromium-webview /mnt/src/chromium-webview",
      "sync"
    ]
  }
}
