#!/bin/sh

# 设置默认下载链接
DEFAULT_URL="https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz"

# 步骤1：获取下载链接
printf "请输入下载链接（回车使用默认值 %s）: " "$DEFAULT_URL"
read URL
URL=${URL:-$DEFAULT_URL}

# 检测下载工具
if command -v curl >/dev/null 2>&1; then
  DOWNLOAD="curl -L -s -o tmp_gost.tar.gz"
elif command -v wget >/dev/null 2>&1; then
  DOWNLOAD="wget -q -O tmp_gost.tar.gz"
else
  echo "错误：需要安装 curl 或 wget"
  exit 1
fi

# 步骤2：下载并解压
echo "正在下载文件..."
$DOWNLOAD "$URL"

echo "正在解压文件..."
tar xzf tmp_gost.tar.gz gost --strip-components 1
rm -f tmp_gost.tar.gz

# 移动文件并设置权限
mv gost /root/gost
chmod +x /root/gost

# 步骤4：获取用户输入
printf "请输入中转机端口: "
read MID_PORT
printf "请输入落地机IP: "
read DEST_IP
printf "请输入落地机端口: "
read DEST_PORT

# 步骤3：生成systemd服务文件
echo "正在创建服务文件..."
cat > /etc/systemd/system/gost.service <<EOF
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/root/gost -L tcp://:$MID_PORT/$DEST_IP:$DEST_PORT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 步骤5：启用并启动服务
echo "正在启用服务..."
systemctl enable gost

echo "正在启动服务..."
systemctl start gost

echo "操作完成！"
echo "服务状态可通过以下命令检查：systemctl status gost"
