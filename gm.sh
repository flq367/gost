#!/bin/sh

# 默认下载链接
DEFAULT_URL="https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz"

# 检查并安装必要依赖
install_dependencies() {
    echo "检测并安装必要的依赖..."

    # 检测当前系统是否为 Debian 或 Alpine
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo "无法检测操作系统类型，请手动安装 wget、curl 和 tar。" >&2
        exit 1
    fi

    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        echo "检测到系统为 Debian/Ubuntu..."
        sudo apt update
        sudo apt install -y wget curl tar
    elif [ "$OS" = "alpine" ]; then
        echo "检测到系统为 Alpine..."
        apk update
        apk add --no-cache wget curl tar
    else
        echo "不支持的操作系统：$OS，请手动安装 wget、curl 和 tar。" >&2
        exit 1
    fi
}

# 检查依赖是否存在
check_dependencies() {
    for cmd in wget curl tar; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "缺少依赖：$cmd"
            install_dependencies
            break
        fi
    done
}

# 检查当前目录是否已存在 gost 文件
check_gost_file() {
    if [ -f ./gost ]; then
        echo "当前目录中已存在 gost 文件，跳过下载和解压过程。"
        return 0
    else
        return 1
    fi
}

# 下载并解压 gost 文件
download_and_extract_gost() {
    echo "请输入下载链接（按回车使用默认链接）："
    read -r DOWNLOAD_URL

    # 如果用户未输入，则使用默认链接
    if [ -z "$DOWNLOAD_URL" ]; then
        DOWNLOAD_URL=$DEFAULT_URL
    fi

    echo "使用下载链接: $DOWNLOAD_URL"

    # 临时文件名
    TEMP_FILE="gost_temp.tar.gz"

    # 下载文件
    echo "正在下载文件..."
    if command -v wget >/dev/null 2>&1; then
        wget -O "$TEMP_FILE" "$DOWNLOAD_URL"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$TEMP_FILE" "$DOWNLOAD_URL"
    else
        echo "错误：未找到 wget 或 curl，请先安装其中一个工具。" >&2
        exit 1
    fi

    # 检查下载是否成功
    if [ $? -ne 0 ]; then
        echo "下载失败，请检查链接是否正确。" >&2
        exit 1
    fi

    echo "下载完成。"

    # 解压文件
    echo "正在解压文件..."
    mkdir -p gost_extracted
    tar -xzf "$TEMP_FILE" -C gost_extracted

    # 检查解压是否成功
    if [ $? -ne 0 ]; then
        echo "解压失败，请检查文件是否为有效的 tar.gz 压缩包。" >&2
        rm -f "$TEMP_FILE"
        exit 1
    fi

    # 查找并移动 gost 文件
    echo "提取 gost 文件..."
    if [ -f gost_extracted/gost ]; then
        mv gost_extracted/gost .
        chmod +x gost
        echo "gost 文件已提取到当前目录。"
    else
        echo "未找到 gost 文件，请检查压缩包内容。" >&2
        rm -rf gost_extracted "$TEMP_FILE"
        exit 1
    fi

    # 清理多余文件
    echo "清理临时文件..."
    rm -rf gost_extracted "$TEMP_FILE"

    echo "gost 文件准备完成！"
}

# 配置并运行 gost 服务
configure_and_run_gost() {
    # 输入中转机端口
    echo "请输入中转机端口（例如 8080）："
    read -r TRANSFER_PORT

    # 输入落地机 IP
    echo "请输入落地机 IP（例如 192.168.1.100）："
    read -r DESTINATION_IP

    # 输入落地机端口
    echo "请输入落地机端口（例如 80）："
    read -r DESTINATION_PORT

    # 检查输入是否完整
    if [ -z "$TRANSFER_PORT" ] || [ -z "$DESTINATION_IP" ] || [ -z "$DESTINATION_PORT" ]; then
        echo "错误：中转机端口、落地机 IP 和落地机端口均不能为空。" >&2
        exit 1
    fi

    # 执行 gost 命令
    echo "正在启动 gost 服务..."
    ./gost -L tcp://:"$TRANSFER_PORT"/"$DESTINATION_IP":"$DESTINATION_PORT"

    if [ $? -ne 0 ]; then
        echo "gost 服务启动失败，请检查配置。" >&2
        exit 1
    fi

    echo "gost 服务已启动，监听端口 $TRANSFER_PORT，转发至 $DESTINATION_IP:$DESTINATION_PORT"
}

# 主程序入口
main() {
    check_dependencies
    if ! check_gost_file; then
        download_and_extract_gost
    fi
    configure_and_run_gost
}

main
