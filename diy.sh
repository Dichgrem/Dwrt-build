#!/usr/bin/env bash
set -eux

# 修改默认 IP 地址
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# 修改 Hostname
sed -i "/uci commit system/i uci set system.@system[0].hostname='OpenWrt'" \
  package/lean/default-settings/files/zzz-default-settings

# 加入编译信息和时间
sed -i \
  "s#OpenWrt #smith build $(TZ=UTC-8 date '+%Y.%m.%d') @ OpenWrt #g" \
  package/lean/default-settings/files/zzz-default-settings
