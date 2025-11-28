# Docker In Docker (DinD)

一个基于 Ubuntu 的 Docker 容器，支持在容器内运行 Docker 命令和 SSH 访问。

## 🚀 特性

- ✅ **Docker in Docker**: 在容器内运行完整的 Docker 环境
- ✅ **SSH 访问**: 通过 SSH 远程访问容器
- ✅ **自动版本更新**: 每小时检查并自动更新 Docker CLI 版本
- ✅ **多架构支持**: 支持 amd64 和 arm64 架构
- ✅ **国内源优化**: 使用中科大镜像源加速包安装（支持 amd64/arm64），Docker 使用 Aliyun 镜像源
- ✅ **预装工具**: 包含常用开发工具

## 📦 镜像信息

- **镜像名称**: `xkand/dind`
- **标签**: `latest`, `v{version}`
- **基础镜像**: Ubuntu
- **当前 Docker CLI 版本**: 查看 [version](./version) 文件获取最新版本

## 🛠️ 快速开始

### 使用 Docker Compose (推荐)

```bash
# 启动容器
docker compose up -d

# 查看日志
docker compose logs -f

# 停止容器
docker compose down
```

### 使用 Docker 命令

```bash
# 启动容器
docker run -d \
  --name dind \
  --privileged \
  -- hostname dind \
  -p 32231:32321 \
  -e ROOT_PASSWORD=123456 \
  -e SSH_PORT=32321 \
  xkand/dind:latest
```

## 🔧 配置说明

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `ROOT_PASSWORD` | `123456` | SSH root 用户密码 |
| `SSH_PORT` | `32321` | SSH 服务端口 |

### 数据卷

| 容器路径 | 说明 |
|----------|------|
| `/var/lib/docker` | Docker 数据目录 |
| `/root/docker` | Docker 用户数据 |

### 网络模式

支持两种网络模式：

1. **Host 模式 (默认)**: `network_mode: host`
   - 容器直接使用主机网络
   - SSH 端口直接映射到主机

2. **Bridge 模式**: 需要手动端口映射
   ```yaml
   ports:
     - 32321:32321
   ```

## 🔌 SSH 连接

```bash
# 使用密码连接
ssh root@localhost -p 32321
# 输入密码: 123456

# 或者使用密钥连接
ssh -i ~/.ssh/id_rsa root@localhost -p 32321
```

## 📁 项目结构

```
.
├── Dockerfile              # Docker 镜像构建文件
├── docker-compose.yml      # Docker Compose 配置
├── start_ssh.sh           # SSH 和 Docker 启动脚本
├── update-motd.sh         # 动态 MOTD 生成脚本
├── motd                   # 登录欢迎信息模板
├── version                # Docker CLI 版本记录
└── .github/workflows/
    └── dind.yml           # GitHub Actions 自动构建工作流
```

## 🔄 自动更新机制

项目使用 GitHub Actions 实现自动版本管理：

1. **版本检查**: 每小时从 GitHub API 获取最新 Docker CLI 稳定版本
2. **版本比较**: 与 `version` 文件中的当前版本对比
3. **自动构建**: 检测到新版本时自动构建并推送 Docker 镜像
4. **版本更新**: 构建成功后更新 `version` 文件

### 触发条件

工作流会在以下情况下触发：
- **定时检查**: 每小时自动检查版本更新
- **手动触发**: 可在 GitHub Actions 页面手动运行
- **文件变更**: 当 `Dockerfile` 或 `start_ssh.sh` 文件被修改时

### 手动检查版本

```bash
# 查看当前版本
cat version

# 获取最新稳定版本
curl -s "https://api.github.com/repos/docker/cli/tags" | \
  jq -r '.[] | select(.name | contains("rc") | not) | .name' | head -1
```

### 手动触发构建

1. 访问 [GitHub Actions 页面](https://github.com/xkand/dind/actions)
2. 选择 "Docker In Docker Build" 工作流
3. 点击 "Run workflow" 按钮手动触发构建

## 🛠️ 预装工具

容器内预装了以下开发工具：

- **Docker**: 完整的 Docker CLI 和守护进程
- **SSH**: OpenSSH 服务器，支持 MOTD 欢迎信息
- **网络工具**: `curl`, `wget`, `ping`, `net-tools`
- **编辑器**: `nano`, `vim`
- **开发工具**: `git`, `git-lfs`, `screen`, `tree`, `jq`, `less`
- **系统监控**: `htop`, `iotop` 
- **网络工具**: `dnsutils` (dig, nslookup)
- **文件工具**: `unzip`
- **系统工具**: `iputils-ping`

## 🎨 MOTD 登录欢迎信息

每次 SSH 登录时会显示中文动态系统信息，包括：

- 🐳 Docker 版本和运行状态
- 📊 系统资源使用情况（磁盘、运行时间）
- 🚀 常用 Docker 命令中文说明
- 📚 中文学习资源链接
- ⚠️ 温馨提示

**自定义 MOTD**: 修改 `motd` 文件可以自定义欢迎信息样式和内容。

## 🔧 自定义配置

### 修改 Docker 配置

可以自定义 Docker 守护进程配置：

```bash
# 在容器内修改 /etc/docker/daemon.json
vim /etc/docker/daemon.json

# 重启 Docker 服务
systemctl restart docker
```

### 添加 SSH 密钥

```bash
# 在容器内添加 SSH 公钥
mkdir -p ~/.ssh
echo "your-ssh-public-key" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

## 🐛 故障排除

### Docker 启动失败

```bash
# 检查 Docker 状态
systemctl status docker

# 查看 Docker 日志
journalctl -u docker -f
```

### SSH 连接失败

```bash
# 检查 SSH 状态
systemctl status ssh

# 查看 SSH 日志
journalctl -u ssh -f
```

### 权限问题

确保容器以 `--privileged` 模式运行，这是 Docker in Docker 的必要条件。

## 📄 许可证

本项目采用 MIT 许可证。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 🔗 相关链接

- [Docker 官方文档](https://docs.docker.com/)
- [GitHub Actions 工作流](https://github.com/xkand/dind/actions)
- [Docker Hub 镜像](https://hub.docker.com/r/xkand/dind)