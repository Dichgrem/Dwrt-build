#!/usr/bin/env bash

set -e

echo "🚀 添加自定义 feed 源..."

# feeds.conf.default 文件存在才操作
#FEEDS_CONF="feeds.conf.default"
#if [ -f "$FEEDS_CONF" ]; then
# 示例：添加常见 feed（你可按需修改或注释掉）
#  grep -q '^src-git helloworld' "$FEEDS_CONF" || echo 'src-git helloworld https://github.com/fw876/helloworld' >>"$FEEDS_CONF"
#  grep -q '^src-git passwall' "$FEEDS_CONF" || echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>"$FEEDS_CONF"
#fi

echo "✅ feeds 添加完成"

# 检测项目类型（OpenWrt 或 ImmortalWrt）
DETECT_TARGET_FILE="package/base-files/files/etc/openwrt_release"
if [ -f "$DETECT_TARGET_FILE" ]; then
  if grep -qi "immortalwrt" "$DETECT_TARGET_FILE"; then
    TARGET_TYPE="ImmortalWrt"
  elif grep -qi "openwrt" "$DETECT_TARGET_FILE"; then
    TARGET_TYPE="OpenWrt"
  else
    TARGET_TYPE="OpenWrt"
  fi
else
  # 如果检测文件不存在，通过其他方式判断
  if [ -d "feeds/packages" ]; then
    TARGET_TYPE="ImmortalWrt"
  else
    TARGET_TYPE="OpenWrt"
  fi
fi

echo "📋 检测到目标类型：$TARGET_TYPE"

# 1. 默认 hostname
CONFIG_GEN_FILE="package/base-files/files/bin/config_generate"
if [ -f "$CONFIG_GEN_FILE" ]; then
  if [ "$TARGET_TYPE" = "ImmortalWrt" ]; then
    sed -i "s/ImmortalWrt/Dwrt/g" "$CONFIG_GEN_FILE"
  else
    sed -i "s/OpenWrt/Dwrt/g" "$CONFIG_GEN_FILE"
  fi
  echo "✅ Hostname 已修改为 Dwrt"
else
  echo "⚠️  $CONFIG_GEN_FILE 不存在，跳过 hostname 修改"
fi

# 2. 默认 IP 地址
if [ -f "$CONFIG_GEN_FILE" ]; then
  if grep -q "192.168.2.1" "$CONFIG_GEN_FILE"; then
    sed -i 's/192.168.2.1/192.168.1.1/' "$CONFIG_GEN_FILE"
    echo "✅ 默认 IP 已修改为 192.168.1.1"
  elif grep -q "192.168.1.1" "$CONFIG_GEN_FILE"; then
    echo "✅ 默认 IP 已经是 192.168.1.1"
  else
    echo "⚠️  $CONFIG_GEN_FILE 中未找到默认 IP 地址"
  fi
fi

# 3. 默认 root 密码
SHADOW_FILE="package/base-files/files/etc/shadow"
if [ -f "$SHADOW_FILE" ]; then
  HASH=$(openssl passwd -1 'password')
  if grep -q "^root::" "$SHADOW_FILE"; then
    sed -i "s|root::0:0:99999|root:${HASH}:0:0:99999|" "$SHADOW_FILE"
    echo "✅ root 密码已设置"
  elif grep -q "^root:" "$SHADOW_FILE"; then
    echo "⚠️  root 账户已设置密码，跳过"
  else
    echo "⚠️  $SHADOW_FILE 中未找到 root 账户"
  fi
else
  echo "⚠️  $SHADOW_FILE 不存在，跳过 root 密码设置"
fi

# 4. 设置默认 LuCI 主题为 argon
mkdir -p package/base-files/files/etc/uci-defaults
cat >package/base-files/files/etc/uci-defaults/99_set_theme <<'EOF'
uci set luci.main.mediaurlbase=/luci-static/argon
uci commit luci
EOF
chmod +x package/base-files/files/etc/uci-defaults/99_set_theme
echo "✅ LuCI 主题已设置为 argon"

# 5. 默认加载 BBR 拥塞控制算法
mkdir -p package/base-files/files/etc/sysctl.d
cat >package/base-files/files/etc/sysctl.d/99-bbr.conf <<'EOF'
net.core.default_qdisc=fq_codel
net.ipv4.tcp_congestion_control=bbr
EOF
echo "✅ BBR 拥塞控制算法已启用"

# 6. 修改默认 shell 为 bash
PASSWD_FILE="package/base-files/files/etc/passwd"
if [ -f "$PASSWD_FILE" ]; then
  if grep -q "/bin/ash" "$PASSWD_FILE"; then
    sed -i "s|/bin/ash|/bin/bash|g" "$PASSWD_FILE"
    echo "✅ 默认 shell 已修改为 bash"
  elif grep -q "/bin/bash" "$PASSWD_FILE"; then
    echo "✅ 默认 shell 已经是 bash"
  else
    echo "⚠️  $PASSWD_FILE 中未找到 ash 或 bash"
  fi
else
  echo "⚠️  $PASSWD_FILE 不存在，跳过 shell 修改"
fi

# 7. 自定义 SSH 登录横幅
mkdir -p package/base-files/files/etc
if [ -f "scripts/custom-files/banner.txt" ]; then
  cp scripts/custom-files/banner.txt package/base-files/files/etc/banner
  echo "✅ 使用自定义 banner"
else
  cat >package/base-files/files/etc/banner <<'EOF'
|   | _____   _____   ____________/  |______  |  |
|   |/     \ /     \ /  _ \_  __ \   __\__  \ |  |
|   |  Y Y  \  Y Y  (  <_> )  | \/|  |  / __ \|  |__
|___|__|_|  /__|_|  /\____/|__|   |__| (____  /____/
          \/      \/             By Dich    \/
-----------------------------------------------------
EOF
  echo "✅ 默认 banner 已设置"
fi

# 8. 自定义 LuCI 概览设备型号
#cat >package/base-files/files/etc/uci-defaults/99-model-fix <<'EOF'
#!/bin/sh
#mkdir -p /tmp/sysinfo
#echo "Myrouter" > /tmp/sysinfo/model
#exit 0
#EOF
#chmod +x package/base-files/files/etc/uci-defaults/99-model-fix

echo "✅ diy.sh 执行完毕"
