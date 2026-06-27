FROM ubuntu:latest

USER root
ENV DEBIAN_FRONTEND=noninteractive

# 安装基础工具、SSH 和 用于安装 Tailscale 的 curl
RUN apt-get update && apt-get install -y \
    wget \
    sudo \
    curl \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# 配置 SSH：允许 root 登录并设置固定密码 lu352400
RUN mkdir /var/run/sshd && \
    echo 'root:lu352400' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 安装 Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# 复制待会儿要创建的启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
