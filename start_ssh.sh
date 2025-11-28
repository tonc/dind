#!/bin/bash

# 删除可能残留的 pid 文件
rm -f /var/run/docker.pid

# 下载自定义的 daemon.json（可选）
# wget https://cnb.cool/xkand/tools/-/git/raw/main/daemon.json -O /etc/docker/daemon.json || true

# 生成 SSH Banner (直接生成到 banner 文件)
echo "Generating SSH Banner..."
MOTD_FILE="/etc/ssh/banner.txt"

# 获取系统信息
DOCKER_VERSION=$(docker --version 2>/dev/null | head -1 | cut -d' ' -f3 | cut -d',' -f1 || echo "未安装")
HOSTNAME=$(hostname)
SSH_PORT=${SSH_PORT:-32321}
LAST_LOGIN=$(date)
UPTIME=$(uptime -p 2>/dev/null || echo "未知")
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5 " (" $3 "/" $2 ")"}')

# 获取容器统计
CONTAINER_COUNT=$(docker ps -q 2>/dev/null | wc -l)
IMAGE_COUNT=$(docker images -q 2>/dev/null | wc -l)

# 生成 Banner (无边框，避免对齐问题)
cat > "$MOTD_FILE" << EOF
═══════════════════════════════════════════════════════════════
                    🐳 Docker 容器环境 🐳
              
              欢迎使用 Docker in Docker 容器！
              
  📋 系统信息:
     • 操作系统: Ubuntu
     • Docker 版本: $DOCKER_VERSION
     • SSH 端口: $SSH_PORT
     • 容器名称: $HOSTNAME
     • 运行时间: $UPTIME
     • 磁盘使用: $DISK_USAGE
              
  🐳 Docker 状态:
     • 运行中容器: $CONTAINER_COUNT 个
     • 可用镜像: $IMAGE_COUNT 个
              
  ⚠️  请记得定期清理不用的容器和镜像！
              
═══════════════════════════════════════════════════════════════

最后更新时间: $(date '+%Y-%m-%d %H:%M:%S')
EOF

chmod 644 "$MOTD_FILE"
chown root:root "$MOTD_FILE"

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
sed -i "s/#Banner none/Banner \/etc\/ssh\/banner.txt/" /etc/ssh/sshd_config
echo "root:${ROOT_PASSWORD}" | chpasswd



exec /usr/sbin/sshd -D

echo "ssh started successfully."
