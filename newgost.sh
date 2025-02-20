#!/bin/sh

# 确保脚本以 root 用户身份运行
if [ "$(id -u)" -ne 0 ]; then
    echo "请以 root 用户身份运行此脚本。"
    exit 1
fi

# 提示用户输入下载链接
echo "请输入下载链接（默认为 https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz）："
read -r download_link
if [ -z "$download_link" ]; then
    download_link="https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz"
fi

# 下载文件
echo "正在下载文件..."
wget -O gost.tar.gz "$download_link" || { echo "下载失败，请检查链接是否正确。"; exit 1; }

# 创建临时目录并解压文件
echo "正在解压文件..."
mkdir -p /tmp/gost_install
tar -xzf gost.tar.gz -C /tmp/gost_install || { echo "解压失败。"; exit 1; }

# 查找并移动 gost 文件
if [ -f /tmp/gost_install/gost ]; then
    mv /tmp/gost_install/gost /root/gost
    chmod +x /root/gost
else
    echo "未找到 gost 可执行文件，安装中止。"
    rm -rf /tmp/gost_install gost.tar.gz
    exit 1
fi

# 清理临时文件
rm -rf /tmp/gost_install gost.tar.gz

# 提示用户输入中转机端口、落地机 IP 和落地机端口
echo "请输入中转机端口："
read -r relay_port
echo "请输入落地机 IP："
read -r landing_ip
echo "请输入落地机端口："
read -r landing_port

# 创建 systemd 服务配置文件
echo "正在创建 systemd 服务文件..."
cat <<EOF > /etc/systemd/system/gost.service
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/root/gost -L tcp://:$relay_port/$landing_ip:$landing_port
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 配置
echo "重新加载 systemd 配置..."
systemctl daemon-reload

# 启用并启动服务
echo "启用并启动 gost 服务..."
systemctl enable gost
systemctl start gost

# 检查服务状态
if systemctl is-active --quiet gost; then
    echo "gost 服务已成功启动！"
else
    echo "gost 服务启动失败，请检查配置。"
fi
