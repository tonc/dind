# 使用 ubuntu 镜像作为基础
FROM ubuntu

# 设置环境变量，避免交互式提示，并设置时区环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 替换为中科大国内源（可选）
RUN sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list.d/ubuntu.sources && \
    sed -i 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/ubuntu.sources

# 更新包索引并安装 openssh-server 和 tzdata，然后清理缓存
RUN apt-get update && \
    apt-get install -y openssh-server tzdata iputils-ping curl wget nano vim net-tools git git-lfs screen && \
    mkdir -p /var/run/sshd /etc/docker && \
    wget https://cnb.cool/xkand/tools/-/git/raw/main/daemon.json -O /etc/docker/daemon.json && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    curl -fsSL https://gitee.com/tech-shrimp/docker_installer/releases/download/latest/linux.sh| bash -s docker --mirror Aliyun && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 复制启动脚本
COPY start_ssh.sh /usr/local/bin/start_ssh.sh
RUN chmod +x /usr/local/bin/start_ssh.sh

# 设置 root 密码默认值（运行时会被覆盖）
ENV ROOT_PASSWORD=123456

# 设置 SSH 服务默认端口
ENV SSH_PORT=32321

# 使用脚本启动 SSH 服务
ENTRYPOINT ["start_ssh.sh"]
