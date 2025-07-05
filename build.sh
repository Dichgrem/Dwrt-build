#!/usr/bin/env bash
set -euo pipefail

# 配置参数
JOBS=$(nproc)
CONFIG_FILE="myconfig"

# 构建系统路径
STAGING_DIR="staging_dir"
BUILD_DIR="build_dir"
TOOLCHAIN_BUILD_DIR="${STAGING_DIR}/toolchain-x86_64_gcc-13.3.0_musl"

echo "📁 当前目录：$(pwd)"
echo "🔧 使用 ${JOBS} 个并行任务"

# 环境检查
if [ ! -f Makefile ] || [ ! -d scripts ]; then
  echo "❌ 错误：请在 OpenWrt 源码根目录下运行此脚本"
  exit 1
fi

# 1. 清理旧的构建标记（可选，用于强制重新构建）
cleanup_build_flags() {
  if [ "${1:-}" = "--clean" ]; then
    echo "🧹 清理构建标记文件..."
    rm -f .feeds_done .download_done .tools_done .toolchain_done
    echo "✅ 构建标记已清理"
  fi
}

# 检查命令行参数
cleanup_build_flags "$@"

# 2. 使用 myconfig 作为编译配置
if [ ! -f .config ]; then
  if [ -f "${CONFIG_FILE}" ]; then
    echo "📋 使用配置文件：${CONFIG_FILE}"
    cp "${CONFIG_FILE}" .config
    echo "🔄 同步配置..."
    make defconfig
    echo "✅ 配置已生成"
  else
    echo "❌ 错误：找不到配置文件 ${CONFIG_FILE}"
    echo "请将您的配置文件复制到当前目录并命名为 'myconfig'"
    exit 1
  fi
else
  echo "ℹ️ 已检测到 .config，跳过配置"
fi

# 3. 更新和安装 feeds（只运行一次）
if [ ! -f .feeds_done ]; then
  echo "🔄 更新 & 安装 feeds..."
  ./scripts/feeds update -a
  ./scripts/feeds install -a
  touch .feeds_done
  echo "✅ Feeds 安装完成"
else
  echo "✅ Feeds 已安装，跳过"
fi

# 4. 下载源码包（只运行一次）
if [ ! -f .download_done ]; then
  echo "⬇️ 下载所有源码包..."
  make download -j"${JOBS}"
  touch .download_done
  echo "✅ 源码包下载完成"
else
  echo "✅ 所有源码已下载，跳过"
fi

# 5. 构建主机工具
if [ ! -f .tools_done ]; then
  echo "🔧 构建主机工具 (tools)..."
  make tools/install -j"${JOBS}"
  touch .tools_done
  echo "✅ 主机工具构建完成"
else
  echo "✅ 主机工具已构建，跳过"
fi

# 6. 工具链处理
handle_toolchain() {
  # 检查是否有预解压的工具链
  if [ -d "${TOOLCHAIN_BUILD_DIR}" ] && [ -x "${TOOLCHAIN_BUILD_DIR}/bin/x86_64-openwrt-linux-musl-gcc" ]; then
    echo "🔍 检测到预解压的工具链：${TOOLCHAIN_BUILD_DIR}"

    # 检查工具链是否已经被 OpenWrt 构建系统识别
    TOOLCHAIN_STAMP_DIR="${STAGING_DIR}/toolchain-x86_64_gcc-13.3.0_musl"
    if [ ! -f "${TOOLCHAIN_STAMP_DIR}/.built" ]; then
      echo "📌 标记工具链为已构建状态"
      mkdir -p "${TOOLCHAIN_STAMP_DIR}"
      touch "${TOOLCHAIN_STAMP_DIR}/.built"
    fi

    # 确保工具链目录软链接正确
    TARGET_TOOLCHAIN_DIR="${STAGING_DIR}/toolchain-x86_64_gcc-13.3.0_musl"
    if [ ! -L "${TARGET_TOOLCHAIN_DIR}" ] && [ ! -d "${TARGET_TOOLCHAIN_DIR}" ]; then
      echo "🔗 创建工具链软链接"
      ln -sf "$(realpath ${TOOLCHAIN_BUILD_DIR})" "${TARGET_TOOLCHAIN_DIR}"
    fi

    echo "✅ 使用预解压的工具链"
    return 0
  fi

  # 如果没有预解压的工具链，则构建
  if [ ! -f .toolchain_done ]; then
    echo "⚙️ 构建交叉编译工具链..."
    make toolchain/install -j"${JOBS}"
    touch .toolchain_done
    echo "✅ 工具链构建完成"
  else
    echo "✅ 工具链已构建，跳过"
  fi
}

handle_toolchain

# 7. 验证工具链
verify_toolchain() {
  local gcc_path
  # 查找 GCC 编译器
  gcc_path=$(find "${STAGING_DIR}" -name "*-openwrt-linux-*-gcc" -type f -executable 2>/dev/null | head -1)

  if [ -n "${gcc_path}" ] && [ -x "${gcc_path}" ]; then
    echo "🎯 工具链验证成功：${gcc_path}"
    echo "📋 GCC 版本：$(${gcc_path} --version | head -1)"
    return 0
  else
    echo "❌ 工具链验证失败：找不到可执行的 GCC"
    return 1
  fi
}

if ! verify_toolchain; then
  echo "❌ 工具链验证失败，停止构建"
  exit 1
fi

# 8. 全量编译
echo "🚀 开始构建 OpenWrt 系统..."
echo "⏰ 开始时间：$(date)"

# 使用 time 命令记录编译时间
if ! time make -j"${JOBS}"; then
  echo "❌ 编译失败！"
  echo "💡 建议："
  echo "   1. 检查构建日志中的错误信息"
  echo "   2. 尝试使用 make -j1 V=s 获取详细日志"
  echo "   3. 清理后重新构建：make clean && $0"
  exit 1
fi

echo "⏰ 完成时间：$(date)"
echo -e "\n🎉 编译完成！"
echo "📦 输出文件位置："
echo "   - 固件镜像：bin/targets/"
echo "   - 软件包：bin/packages/"

# 显示生成的镜像文件
if [ -d bin/targets ]; then
  echo -e "\n📋 生成的镜像文件："
  find bin/targets -name "*.img*" -o -name "*.bin" -o -name "*.vmdk" | head -10
fi
