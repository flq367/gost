#!/bin/sh

# 默认下载链接
DEFAULT_URL="https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20250218/gost_3.0.0-nightly.20250218_linux_amd64.tar.gz"

# 提示用户输入下载链接
echo "请输入下载链接（按回车使用默认链接）："
read -r DOWNLOAD_URL

# 如果用户未输入，则使用默认链接
if [ -z "$DOWNLOAD_URL" ]; then
    DOWNLOAD_URL=$DEFAULT_URL
fi

echo "使用下载链接: $DOWNLOAD_URL"

# 临时文件名
TEMP_FILE="gost_temp.tar.gz"

# 下载文件
echo "正在下载文件..."
if command -v wget >/dev/null 2>&1; then
    wget -O "$TEMP_FILE" "$DOWNLOAD_URL"
elif command -v curl >/dev/null 2>&1; then
    curl -L -o "$TEMP_FILE" "$DOWNLOAD_URL"
else
    echo "错误：未找到 wget 或 curl，请先安装其中一个工具。" >&2
    exit 1
fi

# 检查下载是否成功
if [ $? -ne 0 ]; then
    echo "下载失败，请检查链接是否正确。" >&2
    exit 1
fi

echo "下载完成。"

# 解压文件
echo "正在解压文件..."
mkdir -p gost_extracted
tar -xzf "$TEMP_FILE" -C gost_extracted

# 检查解压是否成功
if [ $? -ne 0 ]; then
    echo "解压失败，请检查文件是否为有效的 tar.gz 压缩包。" >&2
    rm -f "$TEMP_FILE"
    exit 1
fi

# 查找并移动 gost 文件
echo "提取 gost 文件..."
if [ -f gost_extracted/gost ]; then
    mv gost_extracted/gost .
    echo "gost 文件已提取到当前目录。"
else
    echo "未找到 gost 文件，请检查压缩包内容。" >&2
    rm -rf gost_extracted "$TEMP_FILE"
    exit 1
fi

# 清理多余文件
echo "清理临时文件..."
rm -rf gost_extracted "$TEMP_FILE"

echo "操作完成！"
