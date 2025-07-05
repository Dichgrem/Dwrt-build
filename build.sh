#!/usr/bin/env bash
set -euo pipefail

# 并行任务数
JOBS=$(nproc)
CONFIG_FILE="myconfig"
STAMP_DIR=".stamps"

# 初始化戳记目录
mkdir -p "${STAMP_DIR}"

# 1. .config
if [[ ! -f .config ]]; then
  if [[ -f "${CONFIG_FILE}" ]]; then
    echo "📋 复制 ${CONFIG_FILE} → .config"
    cp "${CONFIG_FILE}" .config
    echo "🔄 生成默认配置 (make defconfig)"
    make defconfig
  else
    echo "❌ 找不到配置文件 ${CONFIG_FILE}"
    exit 1
  fi
else
  echo "✅ 已存在 .config，跳过"
fi

# 2. feeds
if [[ ! -f "${STAMP_DIR}/feeds_done" ]]; then
  echo "📦 更新 & 安装 feeds"
  ./scripts/feeds update -a
  ./scripts/feeds install -a
  touch "${STAMP_DIR}/feeds_done"
else
  echo "✅ feeds 已完成，跳过"
fi

# 3. download
if [[ ! -f "${STAMP_DIR}/download_done" ]]; then
  echo "⬇️ 下载所有源码包 (包括预编译工具链)"
  make download -j"${JOBS}"
  touch "${STAMP_DIR}/download_done"
else
  echo "✅ 源码包已下载，跳过"
fi

# 4. 自动检测工具链包并安装
if [[ ! -f "${STAMP_DIR}/toolchain_done" ]]; then
  echo "🔍 查找预编译工具链包…"
  # 寻找 dl 下第一个匹配的 .tar.xz 或 .tar.zst
  TOOLCHAIN_ARCHIVE=$(find dl -maxdepth 1 -type f \
    \( -name 'toolchain-*-gcc-*.tar.xz' -o -name 'toolchain-*-gcc-*.tar.zst' \) |
    head -1 || true)

  if [[ -z "${TOOLCHAIN_ARCHIVE}" ]]; then
    echo "❌ dl/ 下未发现 toolchain-*-gcc-*.tar.{xz,zst} 包"
    echo "   请先放入官方预编译工具链文件"
    exit 1
  fi

  # 根据后缀设置格式变量
  case "${TOOLCHAIN_ARCHIVE##*.}" in
  xz) FMT="tar.xz" ;;
  zst) FMT="tar.zst" ;;
  *)
    echo "❌ 无法识别文件格式: ${TOOLCHAIN_ARCHIVE}"
    exit 1
    ;;
  esac

  echo "📦 使用工具链包：${TOOLCHAIN_ARCHIVE##*/}"
  echo "🔧 安装（解包）预编译工具链…"
  make toolchain/install V=s TOOLCHAIN_ARCHIVE_FORMAT="${FMT}" -j"${JOBS}"
  touch "${STAMP_DIR}/toolchain_done"
else
  echo "✅ 工具链已安装，跳过"
fi

# 5. 全量编译并记录日志与时间
echo "🚀 开始 全量编译 (make world)"
BUILD_START=$(date "+%Y-%m-%d %H:%M:%S")
echo "⏱️ 开始时间：${BUILD_START}"

LOG_WORLD="${STAMP_DIR}/world_build.log"
if ! time make world -j"${JOBS}" 2>&1 | tee "${LOG_WORLD}"; then
  echo "❌ 全量编译失败，错误日志如下："
  echo "----- 👇 日志输出开始 (${LOG_WORLD}) 👇 -----"
  tail -n 100 "${LOG_WORLD}" | sed 's/^/    /'
  echo "----- ☝ 日志输出结束 ☝ -----"
  exit 1
fi

BUILD_END=$(date "+%Y-%m-%d %H:%M:%S")
echo "✅ 全量编译成功"
echo "⏱️ 开始时间：${BUILD_START}"
echo "⏱️ 结束时间：${BUILD_END}"
echo
echo "📂 输出示例 (bin/targets):"
find bin/targets -type f \( -name '*.img*' -o -name '*.bin' \) | head -10
