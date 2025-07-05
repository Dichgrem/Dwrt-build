#!/usr/bin/env bash
set -euo pipefail

# —— 用户可定制 ——
TOOLCHAIN_FILE="openwrt-toolchain-24.10.2-x86-64_gcc-13.3.0_musl.Linux-x86_64.tar.zst"
TOOLCHAIN_URL="https://downloads.openwrt.org/releases/24.10.2/targets/x86/64/$TOOLCHAIN_FILE"
TOOLCHAIN_PATH="staging_dir/toolchain-x86_64_gcc-13.3.0_musl"

# 示例交叉编译器路径，用于解压检测
TC_CHECK_BIN="$TOOLCHAIN_PATH/bin/x86_64-openwrt-linux-musl-gcc"

# —— 1. 检测是否在 OpenWrt 根目录 ——
if [ ! -f Makefile ] || [ ! -d scripts ]; then
  echo "❌ 错误：请在 OpenWrt 源码根目录下运行此脚本（缺少 Makefile 或 scripts/）"
  exit 1
fi

# —— 2. 确保 dl/ 存在 ——
mkdir -p dl

# —— 3. 下载工具链（如未下载过） ——
if [ -f "dl/$TOOLCHAIN_FILE" ]; then
  echo "ℹ️ 已检测到工具链压缩包 dl/$TOOLCHAIN_FILE，跳过下载"
else
  echo "⬇️ 正在下载工具链：$TOOLCHAIN_URL"
  wget -c "$TOOLCHAIN_URL" -P dl
fi

# —— 4. 再次校验压缩包存在性 ——
if [ ! -f "dl/$TOOLCHAIN_FILE" ]; then
  echo "❌ Toolchain 文件不存在: dl/$TOOLCHAIN_FILE"
  exit 1
fi

# —— 5. 解压工具链（如未解压过） ——
if [ -x "$TC_CHECK_BIN" ]; then
  echo "ℹ️ 已检测到已解压的工具链在 $TC_CHECK_BIN，跳过解压"
else
  echo "📦 正在解压工具链到 $TOOLCHAIN_PATH"

  # 创建目标目录
  mkdir -p "$TOOLCHAIN_PATH"

  # 方法1：简单直接，使用 --strip-components=2 跳过双层目录
  echo "🔄 正在解压工具链（跳过双层目录）..."
  tar --use-compress-program=unzstd \
    -xf "dl/$TOOLCHAIN_FILE" \
    -C "$TOOLCHAIN_PATH" \
    --strip-components=2

  # 如果方法1失败，尝试方法2（自适应解压）
  if [ ! -d "$TOOLCHAIN_PATH/bin" ]; then
    echo "⚠️ 简单解压失败，尝试自适应解压..."

    # 清空目标目录
    rm -rf "$TOOLCHAIN_PATH"
    mkdir -p "$TOOLCHAIN_PATH"

    # 使用临时目录进行自适应解压
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    echo "🔄 正在解压到临时目录..."
    tar --use-compress-program=unzstd \
      -xf "dl/$TOOLCHAIN_FILE" \
      -C "$TEMP_DIR"

    # 查找实际的工具链目录（处理可能的嵌套）
    ACTUAL_TOOLCHAIN_DIR=$(find "$TEMP_DIR" -name "bin" -type d | head -1 | xargs dirname)

    if [ -z "$ACTUAL_TOOLCHAIN_DIR" ]; then
      echo "❌ 错误：在解压内容中找不到工具链目录"
      exit 1
    fi

    echo "🚀 正在移动工具链内容到目标目录..."
    # 移动实际内容到目标目录
    mv "$ACTUAL_TOOLCHAIN_DIR"/* "$TOOLCHAIN_PATH"/
  fi

  echo "✅ 工具链已解压至: $TOOLCHAIN_PATH"
fi

# —— 6. 验证工具链是否正确解压 ——
if [ -x "$TC_CHECK_BIN" ]; then
  echo "🎉 工具链验证成功！"
  echo "📍 GCC 路径: $TC_CHECK_BIN"
  echo "📋 GCC 版本信息:"
  "$TC_CHECK_BIN" --version | head -1
else
  echo "❌ 工具链验证失败：找不到 $TC_CHECK_BIN"
  exit 1
fi
