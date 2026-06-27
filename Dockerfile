FROM debian:11-slim

USER root
ENV DEBIAN_FRONTEND=noninteractive

# 1. 更新源并安装基础工具、SSH 服务及 curl
RUN apt-get update && apt-get install -y \
    wget \
    sudo \
    curl \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# 2. 精准配置 SSH 服务：将端口改为 2222，创建运行目录
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config

# 3. 创建一个普通用户 lumen，密码设为 1u352400，并赋予免密 sudo 权限（防止 root 登录被平台死锁）
RUN useradd -m -s /bin/bash lumen && \
    echo 'lumen:1u352400' | chpasswd && \
    echo 'lumen ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# 4. 🔥【这次没忘！】下载并一键安装 Tailscale 官方客户端
RUN curl -fsSL https://tailscale.com/install.sh | sh

# 5. 复制并授权启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
