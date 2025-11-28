#!/bin/bash

# 动态生成 MOTD 文件
MOTD_FILE="/etc/motd"

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

# 生成 MOTD (无边框，避免对齐问题)
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
              
  🚀 常用命令:
     • docker ps              - 查看运行中的容器
     • docker images           - 查看镜像列表
     • docker run hello-world - 测试 Docker 环境
     • screen -S mysession     - 创建会话窗口
     • docker system prune -f - 清理无用资源
     • docker stats           - 查看容器资源使用
     • docker logs <容器名>     - 查看容器日志
     • htop                  - 进程监控工具
     • iotop                 - 磁盘I/O监控
     • jq '.key' file.json   - JSON数据处理
              
  📚 学习资源:
     • Docker 官方文档: https://docs.docker.com/
     • Docker 中文文档: https://docker.practicechina.com/
     • Compose 文档: https://docs.docker.com/compose/
     • 菜鸟教程: https://www.runoob.com/docker/
              
  ⚠️  请记得定期清理不用的容器和镜像！
              
═══════════════════════════════════════════════════════════════

最后更新时间: $(date '+%Y-%m-%d %H:%M:%S')
EOF

# 设置权限
chmod 644 "$MOTD_FILE"