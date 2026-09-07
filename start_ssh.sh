#!/bin/bash

# 删除可能残留的 pid 文件
rm -f /var/run/docker.pid

# 下载自定义的 daemon.json（可选）
# wget https://cnb.cool/xkand/tools/-/git/raw/main/daemon.json -O /etc/docker/daemon.json || true

# 创建 MOTD 显示函数
echo "Setting up MOTD display..."
cat > /usr/local/bin/show-motd << 'EOF'
#!/bin/bash

# 获取系统信息
DOCKER_VERSION=$(docker --version 2>/dev/null | head -1 | cut -d' ' -f3 | cut -d',' -f1 || echo "未安装")
HOSTNAME=$(hostname)
SSH_PORT=${SSH_PORT:-32321}
UPTIME=$(uptime -p 2>/dev/null || echo "未知")
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5 " (" $3 "/" $2 ")"}')

# 获取容器统计
CONTAINER_COUNT=$(docker ps -q 2>/dev/null | wc -l)
IMAGE_COUNT=$(docker images -q 2>/dev/null | wc -l)

# 使用 printf 确保换行
printf '%s\n' "═══════════════════════════════════════════════════════════════"
printf '%s\n' "                    🐳 Docker 容器环境 🐳"
printf '%s\n' "              "
printf '%s\n' "              欢迎使用 Docker in Docker 容器！"
printf '%s\n' "              "
printf '%s\n' "  📋 系统信息:"
printf '%s\n' "     • 操作系统: Ubuntu"
printf '%s\n' "     • Docker 版本: $DOCKER_VERSION"
printf '%s\n' "     • SSH 端口: $SSH_PORT (容器内部端口)"
printf '%s\n' "     • 容器名称: $HOSTNAME"
printf '%s\n' "     • 运行时间: $UPTIME"
printf '%s\n' "     • 磁盘使用: $DISK_USAGE"
printf '%s\n' "              "
printf '%s\n' "  🐳 Docker 状态:"
printf '%s\n' "     • 运行中容器: $CONTAINER_COUNT 个"
printf '%s\n' "     • 可用镜像: $IMAGE_COUNT 个"
printf '%s\n' "              "
printf '%s\n' "  ⚠️  请记得定期清理不用的容器和镜像！"
printf '%s\n' "              "
printf '%s\n' "═══════════════════════════════════════════════════════════════"
printf '%s\n' ""
printf '%s\n' "最后更新时间: $(date '+%Y-%m-%d %H:%M:%S')"
EOF

chmod +x /usr/local/bin/show-motd

# 测试 MOTD 显示
echo "Testing MOTD display:"
/usr/local/bin/show-motd
echo "--- MOTD test end ---"

# 创建 .bash_profile 来显示 MOTD
cat > /root/.bash_profile << 'EOF'
# 显示 MOTD
/usr/local/bin/show-motd

# 如果存在 .bashrc 则执行
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
EOF

# 确保 .bash_profile 存在
touch /root/.bash_profile

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
