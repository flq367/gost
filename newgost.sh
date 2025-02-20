#!/bin/bash

while true; do
    clear
    echo "================================"
    echo "        GOST 端口转发        "
    echo "================================"
    echo "1. 新建 GOST 服务"
    echo "2. 新增 GOST 服务"
    echo "3. 手动修改 GOST 服务"
    echo "4. 删除 GOST 服务"
    echo "0. 退出"
    echo "================================"
    
    read -p "请输入选项 [0-4]: " choice

    case $choice in
        1)
            echo "正在新建 GOST 服务..."
            
            # 提示用户输入中转机端口、落地机 IP 和落地机端口
            read -p "请输入中转机端口: " relay_port
            read -p "请输入落地机 IP: " destination_ip
            read -p "请输入落地机端口: " destination_port
            
            # 创建 /etc/systemd/system/gost.service 脚本
            cat <<EOF > /etc/systemd/system/gost.service
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
EOF

            # 启用并启动 GOST 服务
            systemctl daemon-reload
            systemctl enable gost
            systemctl start gost

            echo "GOST 服务已创建并启动"
            read -p "按回车键继续..."
            ;;
            
        2)
            echo "新增 GOST 服务..."
            read -p "请输入中转机端口: " relay_port
            read -p "请输入落地机IP: " destination_ip
            read -p "请输入落地机端口: " destination_port
            
            # 在ExecStart行后添加新的转发规则
            sed -i "/ExecStart=/ s/$/ -L tcp:\/\/:$relay_port\/$destination_ip:$destination_port/" /etc/systemd/system/gost.service
            
            # 重新加载systemd配置并重启服务
            systemctl daemon-reload
            systemctl enable gost
            systemctl restart gost
            
            echo "GOST 服务已更新并重启"
            read -p "按回车键继续..."
            ;;
            
        3)
            echo "手动修改 GOST 服务..."
            nano /etc/systemd/system/gost.service
            
            # 修改后重新加载systemd配置并重启服务
            systemctl daemon-reload
            systemctl restart gost
            
            echo "配置已更新，服务已重启"
            read -p "按回车键继续..."
            ;;
            
        4)
            echo "正在删除 GOST 服务..."
            systemctl stop gost
            systemctl disable gost
            rm -f /etc/systemd/system/gost.service
            rm -f /root/gost
            systemctl daemon-reload
            
            echo "GOST 服务已完全删除"
            read -p "按回车键继续..."
            ;;
            
        0)
            echo "退出程序..."
            exit 0
            ;;
            
        *)
            echo "无效选项，请重新选择"
            read -p "按回车键继续..."
            ;;
    esac
done
