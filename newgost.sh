#!/bin/sh

# 设置默认下载链接
DEFAULT_URL="https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz"

# 提示输入下载链接
echo "请输入下载链接（留空则使用默认链接: $DEFAULT_URL）："
read -r DOWNLOAD_URL

# 如果用户未输入，使用默认链接
if [ -z "$DOWNLOAD_URL" ]; then
  DOWNLOAD_URL=$DEFAULT_URL
fi

# 下载文件
echo "正在下载文件: $DOWNLOAD_URL"
wget -O gost.tar.gz "$DOWNLOAD_URL" || { echo "下载失败！"; exit 1; }

# 解压文件并提取gost
echo "正在解压文件..."
tar -xzf gost.tar.gz gost || { echo "解压失败！"; exit 1; }

# 删除下载的压缩包
echo "删除压缩包..."
rm -f gost.tar.gz

read -p "请输入中转机端口: " FORWARD_PORT
read -p "请输入落地机IP: " DEST_IP
read -p "请输入落地机端口: " DEST_PORT

# 创建systemd服务脚本
echo "创建gost.service文件..."
cat <<EOF >/etc/systemd/system/gost.service
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/root/gost -L tcp://:$FORWARD_PORT/$DEST_IP:$DEST_PORT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd守护进程
echo "重新加载systemd守护进程..."
systemctl daemon-reload || { echo "systemctl daemon-reload 失败！"; exit 1; }

# 启用gost服务
echo "设置gost服务开机自启..."
systemctl enable gost || { echo "启用服务失败！"; exit 1; }

# 启动gost服务
echo "启动gost服务..."
systemctl start gost || { echo "启动服务失败！"; exit 1; }

echo "gost服务已配置并启动成功！"
