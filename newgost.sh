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

# 提示用户输入中转机端口、落地机 IP 和落地机端口
echo "请输入中转机端口:"
read -r TRANSFER_PORT
echo "请输入落地机 IP:"
read -r LANDING_IP
echo "请输入落地机端口:"
read -r LANDING_PORT

# 如果用户未输入，退出脚本
if [ -z "$TRANSFER_PORT" ] || [ -z "$LANDING_IP" ] || [ -z "$LANDING_PORT" ]; then
    echo "中转机端口、落地机 IP 或落地机端口未输入，操作失败"
    exit 1
fi

# 创建 /etc/systemd/system/gost.service 文件
SERVICE_FILE="/etc/systemd/system/gost.service"
echo "正在创建 $SERVICE_FILE 文件..."

cat <<EOL > "$SERVICE_FILE"
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/root/gost -L tcp://:$TRANSFER_PORT/$LANDING_IP:$LANDING_PORT
Restart=always

[Install]
WantedBy=multi-user.target
EOL

echo "$SERVICE_FILE 文件创建成功"

# 重新加载 systemd 配置
echo "重新加载 systemd 配置..."
systemctl daemon-reload

# 启用并启动 gost 服务
echo "启用并启动 gost 服务..."
systemctl enable gost || { echo "启用服务失败"; exit 1; }
systemctl start gost || { echo "启动服务失败"; exit 1; }

echo "gost 服务已成功启用并启动！"
