#!/bin/bash

# 1. 在后台拉起 SSH 服务（指定 2222 端口，绕过 1024 特权端口限制）
/usr/sbin/sshd -p 2222 &

# 2. 后台启动 Tailscale 核心守护进程
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 &

# 3. 让容器自动登录并加入你的 Tailscale 网络（请把下面换成你网页上生成的真实 key）
tailscale up --authkey=tskey-auth-kygKur9rqq11CNTRL-VVrQK84W2N8bCyn6yb4qN8D31oskTH94 --accept-routes=true &

# 4. 保持容器在后台持续运行不退出
tail -f /dev/null
