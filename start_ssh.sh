#!/bin/bash

# 删除可能残留的 pid 文件
rm -f /var/run/docker.pid

# 下载自定义的 daemon.json（可选）
# wget https://cnb.cool/xkand/tools/-/git/raw/main/daemon.json -O /etc/docker/daemon.json || true

echo "Starting Docker daemon..."
dockerd \
  --host=unix:///var/run/docker.sock \
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
