# 使用 ubuntu 镜像作为基础
FROM ubuntu

# 镜像标签信息
LABEL maintainer="xkand <tonc@163.com>" \
      org.opencontainers.image.authors="xkand" \
      org.opencontainers.image.title="Docker in Docker" \
      org.opencontainers.image.description="Ubuntu with Docker and SSH for Chinese users" \
      org.opencontainers.image.source="https://github.com/xkand/dind" \
      org.opencontainers.image.licenses="MIT"

# 设置环境变量，避免交互式提示，并设置时区环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 替换为中科大国内源（支持 amd64 和 arm64）
RUN sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list.d/ubuntu.sources && \
    sed -i 's@//.*ports.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list.d/ubuntu.sources && \
    sed -i 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/ubuntu.sources

# 更新包索引并安装 openssh-server 和 tzdata，然后清理缓存
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y openssh-server tzdata iputils-ping curl wget nano vim net-tools rsync git git-lfs screen tree htop iotop dnsutils unzip jq less && \
    mkdir -p /var/run/sshd /etc/docker && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    curl -fsSL https://gitee.com/tech-shrimp/docker_installer/releases/download/latest/linux.sh| bash -s docker --mirror Aliyun && \
    wget https://cnb.cool/xkand/tools/-/git/raw/main/daemon.json -O /etc/docker/daemon.json || true && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 复制启动脚本
COPY start_ssh.sh /usr/local/bin/start_ssh.sh
RUN chmod +x /usr/local/bin/start_ssh.sh

# 彻底禁用所有 MOTD 机制
RUN rm -rf /etc/update-motd.d/* && \
    rm -f /etc/motd && \
    sed -i '/pam_motd.so/d' /etc/pam.d/sshd && \
    sed -i '/pam_motd.so/d' /etc/pam.d/login && \
    sed -i '/pam_motd.so/d' /etc/pam.d/common-session

# 设置 root 密码默认值（运行时会被覆盖）
ENV ROOT_PASSWORD=123456

# 设置 SSH 服务默认端口（容器内部）
ENV SSH_PORT=32321

# 使用脚本启动 SSH 服务
ENTRYPOINT ["start_ssh.sh"]
