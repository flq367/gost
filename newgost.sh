#!/bin/sh

# 默认下载链接
DEFAULT_URL="https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz"

# 提示用户输入下载链接
echo "请输入下载链接 (默认: $DEFAULT_URL):"
read -r DOWNLOAD_URL

# 如果用户未输入，则使用默认链接
if [ -z "$DOWNLOAD_URL" ]; then
    DOWNLOAD_URL="$DEFAULT_URL"
fi

# 文件名定义
TEMP_DIR=$(mktemp -d) # 创建临时目录
ARCHIVE_FILE="$TEMP_DIR/gost.tar.gz"

# 下载文件
echo "正在下载文件: $DOWNLOAD_URL"
wget -O "$ARCHIVE_FILE" "$DOWNLOAD_URL" || { echo "下载失败"; exit 1; }

# 解压文件并提取 'gost'
echo "正在解压文件..."
tar -xzvf "$ARCHIVE_FILE" -C "$TEMP_DIR" || { echo "解压失败"; exit 1; }

# 查找解压后的 'gost' 文件
GOST_FILE=$(find "$TEMP_DIR" -type f -name "gost")

if [ -f "$GOST_FILE" ]; then
    # 将 'gost' 文件移动到当前目录
    mv "$GOST_FILE" ./gost
    chmod +x ./gost
    echo "文件已提取并保存为 ./gost"
else
    echo "未找到 'gost' 文件，操作失败"
    exit 1
fi

# 清理临时文件
echo "正在清理临时文件..."
rm -rf "$TEMP_DIR"

# 创建 /etc/systemd/system/gost.service 文件
SERVICE_FILE="/etc/systemd/system/gost.service"
echo "正在创建 systemd 服务文件: $SERVICE_FILE"

cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/root/gost
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "服务和依赖已安装"
