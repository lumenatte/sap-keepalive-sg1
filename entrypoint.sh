#!/bin/bash

# 1. 后台启动 SSH 服务
/usr/sbin/sshd -D &

# 2. 后台启动 Tailscale 核心守护进程
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 &

# 3. 让容器自动登录并加入你的 Tailscale 网络（请把下面换成你网页上生成的真实 key）
tailscale up --authkey=tskey-auth-kygKur9rqq11CNTRL-VVrQK84W2N8bCyn6yb4qN8D31oskTH94 --accept-routes=true &

# 4. 保持容器在后台持续运行不退出
tail -f /dev/null
