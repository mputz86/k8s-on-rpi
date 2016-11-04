#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"

apt-get install -y bridge-utils glusterfs-client nfs-common dnsutils

echo "Copying kubernetes service configuration files"
mkdir /etc/kubernetes
cp -f ./rootfs/etc/kubernetes/k8s.conf /etc/kubernetes/k8s.conf
cp -f ./rootfs/lib/systemd/system/docker-bootstrap.service /lib/systemd/system/docker-bootstrap.service
cp -f ./rootfs/lib/systemd/system/docker-bootstrap.socket /lib/systemd/system/docker-bootstrap.socket
cp -f ./rootfs/lib/systemd/system/k8s-flannel.service /lib/systemd/system/k8s-flannel.service
cp -f ./rootfs/lib/systemd/system/docker.service /lib/systemd/system/docker.service
cp -f ./rootfs/lib/systemd/system/docker.socket /lib/systemd/system/docker.socket
cp -f ./rootfs/lib/systemd/system/k8s-worker.service /lib/systemd/system/k8s-worker.service

echo "Reloading the system service configuration"
systemctl daemon-reload

echo "Stopping the docker service"
systemctl stop docker.service

echo "Enabling the new services"
systemctl enable docker-bootstrap.service k8s-flannel.service k8s-worker.service

echo "Starting the docker bootstrap service"
systemctl start docker-bootstrap.service

echo "Pulling necessary flannel Docker image"
docker -H unix:///var/run/docker-bootstrap.sock pull gcr.io/google_containers/flannel-arm:0.5.5
echo "Starting the flannel service"
systemctl start k8s-flannel.service

echo "Starting the docker service"
systemctl start docker.service

echo "Pulling necessary hyperkube Docker image"
docker pull gcr.io/google_containers/hyperkube-arm:v1.3.3
echo "Starting the kubernetes worker service"
systemctl start k8s-worker.service

curl -fsSL -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.3.3/bin/linux/arm/kubectl
chmod a+x /usr/bin/kubectl

