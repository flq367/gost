#!/bin/sh

set -e

# 检查root权限
if [ "$(id -u)" -ne 0 ]; then
    echo "请以root用户运行此脚本"
    exit 1
fi

# 检测systemd支持
if ! command -v systemctl >/dev/null 2>&1; then
    echo "错误：该系统不支持systemd"
    exit 1
fi

# 设置默认下载链接
default_url="https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz"

# 提示输入下载链接
printf "请输入下载链接（留空使用默认）: "
read url
url="${url:-$default_url}"

# 安装curl或wget（如需要）
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    if [ -f /etc/alpine-release ]; then
        apk add --no-cache curl
    else
        apt-get update && apt-get install -y curl
    fi
fi

# 下载文件
echo "正在下载文件..."
if command -v curl >/dev/null 2>&1; then
    curl -L -o gost.tar.gz "$url"
else
    wget -O gost.tar.gz "$url"
fi

# 解压并提取gost文件
echo "解压文件中..."
mkdir -p temp_dir
tar xzf gost.tar.gz -C temp_dir
find temp_dir -type f -name gost -exec mv {} . \;
rm -rf gost.tar.gz temp_dir

# 移动文件并设置权限
mv gost /root/gost
chmod +x /root/gost

# 获取用户输入
printf "请输入中转机端口: "
read relay_port
printf "请输入落地机IP: "
read target_ip
printf "请输入落地机端口: "
read target_port

# 创建systemd服务
echo "创建服务文件..."
cat > /etc/systemd/system/gost.service <<EOF
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/root/gost -L tcp://:$relay_port/$target_ip:$target_port
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动服务
echo "启用服务..."
systemctl daemon-reload
systemctl enable gost
systemctl start gost

echo "安装完成！"
