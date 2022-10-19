#!/bin/bash

set -eE
trap 'sudo shutdown -P now' ERR

# /dev/nvme1n1 is the source volume
sudo mkdir -p /mnt/src
sudo mount /dev/nvme1n1 /mnt/src

# Use mdadm to create a RAID-0 array of /dev/nvme2n1 and /dev/nvme3n1
# and mount it at /mnt/md0
sudo mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 /dev/nvme2n1 /dev/nvme3n1
sudo mkfs.ext4 -F /dev/md0
sudo mkdir -p /mnt/md0
sudo mount /dev/md0 /mnt/md0

# Allow any user to work in /mnt/md0 and /mnt/src
sudo chmod a+wrx /mnt/src
sudo chmod a+wrx /mnt/md0

cd /mnt/md0

mv /mnt/src/chromium-webview /mnt/md0/

cd chromium-webview

git pull origin cr-11.0

%{ for arch in architectures ~}
./build-webview.sh -a "${arch}" -s -r "${chrome_version}:${chrome_shortversion}"
[ "${arch}" '==' "x64" ] && android_arch="x86_64" || android_arch=${arch}
aws s3 cp "../prebuilt/$android_arch/webview.apk.xz" "s3://${bucket_name}/webview-${chrome_version}-${arch}.apk.xz"
%{ endfor ~}

sudo shutdown -P now