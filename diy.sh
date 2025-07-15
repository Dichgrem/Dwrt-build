#!/usr/bin/env bash

set -e

echo "🚀 添加自定义 feed 源..."

# feeds.conf.default 文件存在才操作
FEEDS_CONF="feeds.conf.default"
if [ -f "$FEEDS_CONF" ]; then
  # 示例：添加常见 feed（你可按需修改或注释掉）
#  grep -q '^src-git helloworld' "$FEEDS_CONF" || echo 'src-git helloworld https://github.com/fw876/helloworld' >>"$FEEDS_CONF"
#  grep -q '^src-git passwall' "$FEEDS_CONF" || echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>"$FEEDS_CONF"
fi

echo "✅ feeds 添加完成"

# 1. 默认 hostname
sed -i 's/=ImmortalWrt/=Dwrt/' package/base-files/files/bin/config_generate

# 2. 默认 IP 地址
sed -i 's/192.168.1.1/192.168.1.1/' package/base-files/files/bin/config_generate

# 3. 默认 root 密码
HASH=$(openssl passwd -1 'password')
sed -i "s|root::0:0:99999|root:${HASH}:0:0:99999|" package/base-files/files/etc/shadow

# 4. 设置默认 LuCI 主题为 argon
mkdir -p package/base-files/files/etc/uci-defaults
cat >package/base-files/files/etc/uci-defaults/99_set_theme <<'EOF'
uci set luci.main.mediaurlbase=/luci-static/argon
uci commit luci
EOF
chmod +x package/base-files/files/etc/uci-defaults/99_set_theme

# 5. 默认加载 BBR 拥塞控制算法
mkdir -p package/base-files/files/etc/sysctl.d
cat >package/base-files/files/etc/sysctl.d/99-bbr.conf <<'EOF'
net.core.default_qdisc=fq_codel
net.ipv4.tcp_congestion_control=bbr
EOF

# 6. 修改默认 shell 为 bash
sed -i "s|/bin/ash|/bin/bash|g" package/base-files/files/etc/passwd
# 你需要在 .config 中确保包含 bash，例如：
# echo 'CONFIG_PACKAGE_bash=y' >> .config

# 7. 自定义 SSH 登录横幅
mkdir -p package/base-files/files/etc
if [ -f "scripts/custom-files/banner.txt" ]; then
  cp scripts/custom-files/banner.txt package/base-files/files/etc/banner
else
  cat >package/base-files/files/etc/banner <<'EOF'
|   | _____   _____   ____________/  |______  |  |
|   |/     \ /     \ /  _ \_  __ \   __\__  \ |  |
|   |  Y Y  \  Y Y  (  <_> )  | \/|  |  / __ \|  |__
|___|__|_|  /__|_|  /\____/|__|   |__| (____  /____/
          \/      \/             By Dich    \/
-----------------------------------------------------
EOF
fi

# 8. 自定义 LuCI 概览设备型号
cat >package/base-files/files/etc/uci-defaults/99-model-fix <<'EOF'
#!/bin/sh
mkdir -p /tmp/sysinfo
echo "Myrouter" > /tmp/sysinfo/model
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-model-fix

echo "✅ diy.sh 执行完毕"
