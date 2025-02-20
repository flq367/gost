#!/bin/sh

# 提示输入下载链接
read -p "请输入下载链接（按回车使用默认链接）: " download_link
download_link=${download_link:-https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz}

# 下载文件
echo "正在下载 $download_link ..."
curl -L -o gost.tar.gz "$download_link"

# 解压并提取gost文件
echo "正在解压文件 ..."
tar -xzf gost.tar.gz --strip-components=1 gost
rm gost.tar.gz

# 提示用户输入中转机端口、落地机ip、落地机端口
read -p "请输入中转机端口: " relay_port
read -p "请输入落地机IP: " destination_ip
read -p "请输入落地机端口: " destination_port

# 创建systemd服务文件
cat <<EOL > /etc/systemd/system/gost.service
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/root/gost -L tcp://:$relay_port/$destination_ip:$destination_port
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# 启用并启动服务
echo "正在启用和启动gost服务 ..."
systemctl enable gost
systemctl start gost

echo "gost服务已成功安装并启动！"
