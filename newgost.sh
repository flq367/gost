#!/bin/sh

# 提示输入下载链接，如不输入则使用默认链接
read -p "请输入下载链接（默认：https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz）：" DOWNLOAD_URL
DOWNLOAD_URL=${DOWNLOAD_URL:-"https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz"}

# 下载压缩包
echo "正在下载压缩包..."
wget -O gost.tar.gz "$DOWNLOAD_URL"

# 解压压缩包并只提取gost文件
echo "正在解压并提取gost文件..."
tar -xzf gost.tar.gz gost
rm -f gost.tar.gz

# 移动gost文件到/root目录
mv gost /root/gost
chmod +x /root/gost

# 提示用户输入中转机端口、落地机ip、落地机端口
read -p "请输入中转机端口：" LOCAL_PORT
read -p "请输入落地机IP：" REMOTE_IP
read -p "请输入落地机端口：" REMOTE_PORT

# 创建gost.service文件
echo "正在创建gost.service文件..."
cat <<EOF > /etc/systemd/system/gost.service
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/root/gost -L tcp://:$LOCAL_PORT/$REMOTE_IP:$REMOTE_PORT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动gost服务
echo "正在启用并启动gost服务..."
systemctl enable gost
systemctl start gost

echo "gost服务已成功配置并启动！"
