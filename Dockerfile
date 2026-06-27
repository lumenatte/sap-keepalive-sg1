FROM debian:11-slim

USER root
ENV DEBIAN_FRONTEND=noninteractive

# 1. 更新源并安装 Debian 基础依赖工具、SSH 服务及 curl
RUN apt-get update && apt-get install -y \
    wget \
    sudo \
    curl \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# 2. 精准配置 SSH 服务：创建运行目录、允许 root 登录、设置固定密码 1u352400
RUN mkdir -p /var/run/sshd
RUN echo 'root:1u352400' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 3. 下载并安装 Tailscale 内网穿透
RUN curl -fsSL https://tailscale.com/install.sh | sh

# 4. 复制并授权启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
