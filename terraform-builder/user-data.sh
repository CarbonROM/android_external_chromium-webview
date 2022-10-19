#!/bin/bash

set -e

# Ensure git and aws-cli is installed
sudo apt-get -y -o DPkg::Lock::Timeout=300 update
sudo apt-get -y -o DPkg::Lock::Timeout=300 install --no-install-recommends git awscli

# Use mdadm to create a RAID-0 array of /dev/nvme1n1 and /dev/nvme2n1
# and mount it at /mnt/md0
sudo mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 /dev/nvme1n1 /dev/nvme2n1
sudo mkfs.ext4 -F /dev/md0
sudo mkdir -p /mnt/md0
sudo mount /dev/md0 /mnt/md0

# Allow any user to work in /mnt/md0
sudo chmod a+wrx /mnt/md0

cd /mnt/md0

# Obtain CarbonROM/android_external_chromium-webview at the cr-11.0 branch
git clone https://github.com/CarbonROM/android_external_chromium-webview.git -b cr-11.0 chromium-webview

cd chromium-webview

%{ for arch in architectures ~}
./build-webview.sh -a "${arch}" -s -r "${chrome_version}:${chrome_shortversion}"
[ "${arch}" '==' "x64" ] && android_arch="x86_64" || android_arch=${arch}
aws s3 cp "../prebuilt/$android_arch/webview.apk.xz" "s3://${bucket_name}/webview-${chrome_version}-${arch}.apk.xz"
%{ endfor ~}

sudo shutdown -P now
