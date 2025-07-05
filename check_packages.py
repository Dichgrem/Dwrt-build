import subprocess

# 要检查和安装的软件包列表
packages = [
    "build-essential",  # 基础构建工具包
    "clang",  # LLVM C/C++ 编译器
    "flex",  # 词法分析器生成器
    "bison",  # 语法分析器生成器
    "g++",  # GNU C++ 编译器
    "gawk",  # GNU AWK 文本处理工具
    "gettext",  # 国际化支持工具
    "git",  # 版本控制系统
    "libncurses-dev",  # ncurses 开发库（新版）
    "libssl-dev",  # OpenSSL 开发库
    "python3",  # Python 3 解释器
    "python3-dev",  # Python 3 开发库
    "python3-setuptools",  # Python 3 setuptools
    "rsync",  # 文件同步工具
    "unzip",  # 解压缩工具
    "zlib1g-dev",  # zlib 压缩库开发包
    "file",  # 文件类型识别工具
    "wget",  # 网络下载工具
    "curl",  # 网络传输工具
    # 压缩和解压工具
    "gzip",  # Gzip 压缩工具
    "tar",  # Tar 打包工具
    "zip",  # Zip 压缩工具
    "xz-utils",  # XZ 压缩工具
    "bzip2",  # Bzip2 压缩工具
    "zstd",  # Zstandard 压缩工具
    # 构建相关工具
    "make",  # Make 构建工具
    "cmake",  # CMake 构建系统
    "autoconf",  # Autoconf 自动配置工具
    "automake",  # Automake 构建工具
    "libtool",  # Libtool 库工具
    "patch",  # 补丁应用工具
    "diffutils",  # 文件差异工具
    "findutils",  # 文件查找工具
    "grep",  # 文本搜索工具
    "sed",  # 流编辑器
    # 文档和帮助工具
    "help2man",  # 手册页生成工具
    "texinfo",  # Texinfo 文档系统
    # 开发库
    "libelf-dev",  # ELF 处理库
    "libfuse-dev",  # FUSE 文件系统开发库
    "liblzma-dev",  # LZMA 开发库
    "libxml2-dev",  # XML2 开发库
    "libyaml-dev",  # YAML 开发库
    "uuid-dev",  # UUID 开发库
    "device-tree-compiler",  # 设备树编译器
    "antlr3",  # ANTLR3 解析器生成器
    "gperf",  # GNU 完美哈希函数生成器
    # 网络和系统工具
    "time",  # 时间测量工具
    "bc",  # 任意精度计算器，内核 Makefile 中常用于数学计算
    "jq",  # JSON 处理器
    "xxd",  # 十六进制查看器
    "swig",  # SWIG 接口生成器
    "upx-ucl",  # UPX 压缩工具
    "ccache",  # 编译缓存工具
    "ecj",  # Eclipse Java 编译器
    "fastjar",  # Fast JAR 工具
    "imagemagick",  # ImageMagick 图像处理
]


def is_installed(pkg_name):
    """检查软件包是否已安装"""
    try:
        subprocess.run(
            ["dpkg", "-s", pkg_name],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True
    except subprocess.CalledProcessError:
        return False


def main():
    print("检查并安装缺失的软件包...")
    missing_packages = []

    for pkg in packages:
        if is_installed(pkg):
            print(f"✅ 已安装：{pkg}")
        else:
            print(f"❌ 未安装：{pkg}")
            missing_packages.append(pkg)

    if missing_packages:
        print("\n🔄 正在执行 apt-get update ...")
        try:
            subprocess.run(["sudo", "apt-get", "update"], check=True)
        except subprocess.CalledProcessError:
            print("❌ apt-get update 失败，请检查网络连接或源设置。")
            return

        print("\n⬇️ 开始安装以下缺失的软件包：")
        print(" ".join(missing_packages))
        try:
            subprocess.run(
                ["sudo", "apt-get", "install", "-y"] + missing_packages, check=True
            )
        except subprocess.CalledProcessError:
            print("❌ 安装部分软件包失败，请手动检查。")
    else:
        print("\n✅ 所有软件包已安装，无需操作。")

    print("✅ 所有软件包检查完毕。")


if __name__ == "__main__":
    main()
