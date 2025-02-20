#!/bin/bash

# 提示输入下载链接
read -p "请输入下载链接（不输入则默认下载 https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz）：" download_url
if [ -z "$download_url" ]; then
    download_url="https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz"
fi

# 下载文件
echo "开始下载文件..."
wget "$download_url"
if [ $? -ne 0 ]; then
    echo "下载失败，请检查链接或网络。"
    exit 1
fi

# 获取下载的文件名
filename=$(basename "$download_url")

# 解压文件并提取 gost 文件
echo "开始解压文件..."
tar -xzf "$filename" gost
if [ $? -ne 0 ]; then
    echo "解压失败，请检查文件格式或文件完整性。"
    exit 1
fi

# 移动 gost 文件到 /root 目录
mv gost /root/

# 删除下载的压缩包
rm "$filename"

# 提示用户输入中转机端口、落地机 IP 和落地机端口
read -p "请输入中转机端口：" relay_port
read -p "请输入落地机 IP：" target_ip
read -p "请输入落地机端口：" target_port

# 生成 systemd 服务脚本
service_script="[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/root/gost -L tcp://:$relay_port/$target_ip:$target_port
Restart=always

[Install]
WantedBy=multi-user.target"

# 创建 /etc/systemd/system/gost.service 文件
echo "$service_script" > /etc/systemd/system/gost.service

# 重新加载 systemd 管理器配置
systemctl daemon-reload

# 启用并启动 gost 服务
systemctl enable gost
systemctl start gost

echo "gost 服务已成功启动。"
