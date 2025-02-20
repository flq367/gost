#!/bin/sh

set -e

default_url="https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz"

echo "请输入下载链接 (留空使用默认链接):"
read url
url=${url:-$default_url}

echo "正在下载 $url ..."
wget -O gost.tar.gz "$url"

echo "正在解压..."
tar -xzf gost.tar.gz gost
rm -f gost.tar.gz

chmod +x gost
mv gost /root/gost

echo "请输入中转机端口:"
read relay_port

echo "请输入落地机 IP:"
read dest_ip

echo "请输入落地机端口:"
read dest_port

service_file="/etc/systemd/system/gost.service"
echo "创建 Systemd 服务文件..."
cat <<EOF > "$service_file"
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/root/gost -L tcp://:$relay_port/$dest_ip:$dest_port
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "启动并启用服务..."
systemctl enable gost
systemctl start gost

echo "GOST 已成功安装并运行！"
