#!/bin/bash

# 1. 在后台拉起 Tailscale 核心守护进程（使用用户态网络，并开启 1055 代理端口）
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 &

# 2. 等待 2 秒让守护进程稳固运行
sleep 2

# 3. 🔥 自动登录并加入网络，同时开启 --ssh 托管服务！
tailscale up --authkey=tskey-auth-k4NxQajnBn11CNTRL-reF78AJCe6NiLxd48rgf7NnJAVaExqGrD --accept-routes=true --ssh=true &

# 4. 保持容器前台挂起
tail -f /dev/null
