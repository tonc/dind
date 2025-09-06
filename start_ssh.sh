#!/bin/bash

echo "Starting Docker daemon..."
dockerd \
  --host=unix:///var/run/docker.sock \
  # --host=tcp://0.0.0.0:2375 \
  --storage-driver=vfs &

# 等待 Docker Daemon 启动，最多等待 30 秒
timeout=30
while ! docker info >/dev/null 2>&1; do
  timeout=$((timeout - 1))
  if [ $timeout -le 0 ]; then
    echo "Timeout: Failed to start Docker daemon!"
    exit 1
  fi
  sleep 1
done

echo "Docker daemon started successfully."

# 启动 SSH 服务
echo "Starting SSH service..."
sed -i "s/#Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config
echo "root:${ROOT_PASSWORD}" | chpasswd
exec /usr/sbin/sshd -D

echo "ssh started successfully."
