#!/usr/bin/env bash
set -euo pipefail

# 并行任务数，按需修改
JOBS=$(nproc)

# 目标 Defconfig
DEFCONFIG="x86_64_generic_defconfig"

# —— 1. 生成 .config ——
# 直接装载指定平台的默认配置，无需交互
make "${DEFCONFIG}"

# —— 2. 更新并安装 Feeds ——
# 拉取 feeds 并把所有包链接进来
./scripts/feeds update -a
./scripts/feeds install -a

# —— 3. 下载所有源码 ——
# 包含软件包源码 + 工具链源码
make download -j"${JOBS}"

# —— 4. 安装预编译 Toolchain ——
# 会检测 dl/ 下的 openwrt-toolchain-*.tar.zst 并直接解压
make toolchain/install -j$(nproc)

# —— 5. 全量编译 ——
# 编译主机工具、所有 package、内核、镜像等
make -j"${JOBS}"

echo
echo "🎉 完成！"
