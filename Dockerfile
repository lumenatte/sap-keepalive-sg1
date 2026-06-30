FROM debian:11-slim

USER root
ENV DEBIAN_FRONTEND=noninteractive

# 仅安装基础工具、curl、以及用于诊断的 ps (procps) 和 htop
RUN apt-get update && apt-get install -y \
    wget \
    sudo \
    curl \
    procps \
    htop \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 下载并一键安装 Tailscale 官方客户端
RUN curl -fsSL https://tailscale.com/install.sh | sh

# 提前在镜像中创建好日志文件并赋予读写权限
RUN touch /tmp/komari.log && chmod 666 /tmp/komari.log

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
