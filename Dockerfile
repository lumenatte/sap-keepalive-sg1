FROM debian:11-slim

USER root
ENV DEBIAN_FRONTEND=noninteractive

# 安装基础工具、curl、以及用于诊断的 ps (procps) 和 htop
RUN apt-get update && apt-get install -y \
    wget \
    sudo \
    curl \
    procps \
    htop \
    && rm -rf /var/lib/apt/lists/*

# 下载并一键安装 Tailscale 官方客户端
RUN curl -fsSL https://tailscale.com/install.sh | sh

# ========================================================
# 🔥 新增：下载并安装哪吒/Komari Agent (以最新稳定版 v1 架构为例)
# ========================================================
RUN curl -L https://github.com/naiba/nezha/releases/latest/download/nezha-agent_linux_amd64.zip -o /tmp/agent.zip || \
    curl -L https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip -o /tmp/agent.zip \
    && apt-get update && apt-get install -y unzip && unzip /tmp/agent.zip -d /usr/local/bin/ \
    && mv /usr/local/bin/nezha-agent /usr/local/bin/komari-agent \
    && chmod +x /usr/local/bin/komari-agent \
    && rm -f /tmp/agent.zip

# 提前在镜像中创建好日志文件并赋予读写权限
RUN touch /tmp/komari.log && chmod 666 /tmp/komari.log

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
