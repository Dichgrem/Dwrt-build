#!/bin/bash

# ========== 基本变量 ==========
REPO="${OPENWRT_SOURCE_REPO:-unknown}" # 可通过环境变量传入（GitHub Actions 可以自动注入）
DATE=$(TZ=UTC-8 date "+%Y.%m.%d")

# ========== 修改默认 IP ==========
echo "[DIY] 修改默认 IP 地址为 192.168.2.1"
sed -i 's/192\.168\.1\.1/192.168.2.1/g' package/base-files/files/bin/config_generate 2>/dev/null || echo "⚠️ 修改默认 IP 失败（可能路径不存在）"

# ========== 修改主机名 + 增加编译者信息 ==========
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
  echo "[DIY] 检测到 lean/lede 源，修改 zzz-default-settings"

  sed -i "/uci commit system/i uci set system.@system[0].hostname='OpenWrt'" package/lean/default-settings/files/zzz-default-settings

  sed -i "s/OpenWrt /smith build ${DATE} @ OpenWrt /g" package/lean/default-settings/files/zzz-default-settings

elif [ -f "package/emortal/default-settings/files/99-default-settings" ]; then
  echo "[DIY] 检测到 immortalwrt 源，修改 99-default-settings"

  sed -i "/uci commit system/i uci set system.@system[0].hostname='OpenWrt'" package/emortal/default-settings/files/99-default-settings

  sed -i "s/OpenWrt /smith build ${DATE} @ OpenWrt /g" package/emortal/default-settings/files/99-default-settings

elif grep -q "DISTRIB_DESCRIPTION=" package/base-files/files/etc/openwrt_release 2>/dev/null; then
  echo "[DIY] 检测到 openwrt 类源，仅打印版本信息"

  sed -i "s/DISTRIB_DESCRIPTION=.*/DISTRIB_DESCRIPTION='smith build ${DATE} @ OpenWrt'/" package/base-files/files/etc/openwrt_release

else
  echo "⚠️ 未检测到已知的 default-settings 路径，仅执行基础修改"
fi

# ========== 添加更多个性化修改请写在这里 ==========
# echo "执行其他自定义命令"
