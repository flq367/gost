#!/bin/sh

# 提示用户输入下载链接，若未输入则使用默认链接
echo "请输入下载链接，若不输入则默认下载 https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz"
read download_link
if [ -z "$download_link" ]; then
    download_link="https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz"
fi

# 下载文件
echo "开始下载文件..."
package_name=$(basename "$download_link")
if command -v wget >/dev/null 2>&1; then
    wget "$download_link"
elif command -v curl >/dev/null 2>&1; then
    curl -O "$download_link"
else
    echo "系统中未找到 wget 或 curl 工具，请先安装。"
    exit 1
fi

# 检查下载是否成功
if [ ! -f "$package_name" ]; then
    echo "文件下载失败，请检查网络或链接是否正确。"
    exit 1
fi

# 解压文件并提取 gost 文件
echo "开始解压文件..."
tar -xzf "$package_name" gost
mv gost /root/gost

# 删除下载的压缩包和其他不必要的文件
rm -f "$package_name"

# 提示用户输入中转机端口、落地机 IP 和落地机端口
echo "请输入中转机端口："
read transit_port
echo "请输入落地机 IP："
read target_ip
echo "请输入落地机端口："
read target_port

# 生成 gost.service 文件
service_content="[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/root/gost -L tcp://:$transit_port/$target_ip:$target_port
Restart=always

[Install]
WantedBy=multi-user.target"

echo "$service_content" > /etc/systemd/system/gost.service

# 启用并启动 gost 服务
systemctl enable gost
systemctl start gost

echo "gost 服务已成功设置为开机自启并启动。"
