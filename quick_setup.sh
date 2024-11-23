#!/bin/bash

# 设置错误处理
set -e

# 检查网络连接
if ! ping -c 1 github.com &> /dev/null; then
    echo "错误：无法连接到 GitHub，请检查网络连接"
    exit 1
fi

# 设置安装目录
INSTALL_DIR="$HOME/.local/share/env_script_setup"
BIN_DIR="$HOME/.local/bin"

# 检查必要目录的写入权限
for dir in "$INSTALL_DIR" "$BIN_DIR" "$HOME/.config/fish"; do
    if [ ! -d "$dir" ]; then
        if ! mkdir -p "$dir" 2>/dev/null; then
            echo "错误：无法创建目录 $dir"
            exit 1
        fi
    elif [ ! -w "$dir" ]; then
        echo "错误：没有目录 $dir 的写入权限"
        exit 1
    fi
done

# 用户/仓库名
USER_NAME="JavanTang"
REPO_NAME="HOME"

# 下载必要的脚本
echo "下载必要的脚本..."
for script in "init_env.sh" "model_download_by_conf.sh"; do
    if ! curl -fsSL "https://raw.githubusercontent.com/${USER_NAME}/${REPO_NAME}/main/${script}" -o "$INSTALL_DIR/${script}"; then
        echo "错误：下载 ${script} 失败"
        exit 1
    fi
done

# 创建必要的目录
mkdir -p "$HOME/MODELZOOS"

# 检查并创建软链接
if [ -L "$BIN_DIR/model_download" ] && [ "$(readlink "$BIN_DIR/model_download")" != "$INSTALL_DIR/model_download_by_conf.sh" ]; then
    read -p "model_download 命令已存在，是否覆盖？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "安装已取消"
        exit 1
    fi
fi

ln -sf "$INSTALL_DIR/model_download_by_conf.sh" "$BIN_DIR/model_download"
chmod +x "$BIN_DIR/model_download"
chmod +x "$INSTALL_DIR/init_env.sh"

# 配置 fish shell
FISH_CONFIG_DIR="$HOME/.config/fish"
FISH_CONFIG="$FISH_CONFIG_DIR/config.fish"

# 备份现有配置
if [ -f "$FISH_CONFIG" ]; then
    cp "$FISH_CONFIG" "$FISH_CONFIG.backup"
fi

# 添加 PATH 配置
if ! grep -q "fish_add_path.*/.local/bin" "$FISH_CONFIG" 2>/dev/null; then
    echo 'fish_add_path $HOME/.local/bin' >> "$FISH_CONFIG"
fi

# 配置其他 shell（如果存在）
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ]; then
        if ! grep -q "$HOME/.local/bin" "$rc"; then
            cp "$rc" "$rc.backup"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
        fi
    fi
done

# 执行环境初始化脚本
echo "开始执行环境初始化脚本..."
if ! bash "$INSTALL_DIR/init_env.sh"; then
    echo "错误：环境初始化失败"
    exit 1
fi

echo "安装完成！"
echo "配置文件已备份到 $FISH_CONFIG.backup"
echo "请运行 'source $FISH_CONFIG' 来更新环境变量"