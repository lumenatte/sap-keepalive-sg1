FROM debian:11-slim

USER root
ENV DEBIAN_FRONTEND=noninteractive

# 安装基础工具、curl 
RUN apt-get update && apt-get install -y \
    wget \
    sudo \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 下载并一键安装 Tailscale 官方客户端
RUN curl -fsSL https://tailscale.com/install.sh | sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
