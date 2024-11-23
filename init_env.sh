#!/usr/bin/env bash

# =================================================================
# 环境配置自动化脚本
# 功能:
# 1. 用户管理: 创建新用户、配置sudo权限
# 2. SSH配置: 设置SSH密钥、权限
# 3. 基础环境: 安装必要软件包(wget, git, curl, fish等)
# 4. Python环境: 安装Miniconda
# 5. Shell环境: 安装fish及插件
# 6. 代理配置: 安装配置shadowsocksr-cli
# =================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =================================================================
# 基础工具函数
# =================================================================

log_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 未安装，请先安装该命令"
        exit 1
    fi
}

# =================================================================
# 用户管理功能
# =================================================================

setup_user() {
    local username=$1
    local password=$2

    log_info "创建用户 $username..."
    useradd -m $username 2>/dev/null || log_warn "用户 $username 已存在"
    usermod -aG sudo $username

    log_info "设置用户密码..."
    echo "$username:$password" | chpasswd
}

get_user_input() {
    if [ "$#" -eq 2 ]; then
        USERNAME=$1
        PASSWORD=$2
        log_info "使用命令行参数设置用户名和密码"
    else
        log_info "请按照提示输入用户信息"
        read -p "请输入要创建的用户名: " USERNAME
        read -s -p "请输入密码: " PASSWORD
        echo
        read -s -p "请再次输入密码确认: " PASSWORD2
        echo

        if [ "$PASSWORD" != "$PASSWORD2" ]; then
            log_error "两次输入的密码不一致!"
            exit 1
        fi
    fi
}

# =================================================================
# SSH配置功能
# =================================================================

get_ssh_key() {
    log_info "SSH密钥配置"
    echo "请选择SSH密钥配置方式:"
    echo "1. 直接输入密钥"
    echo "2. 从文件读取密钥"
    read -p "请选择 (1-2): " choice

    case $choice in
        1)
            echo "请输入SSH公钥 (以ssh-rsa开头的完整密钥):"
            read -r SSH_KEY
            ;;
        2)
            read -p "请输入SSH公钥文件路径: " key_file
            if [ -f "$key_file" ]; then
                SSH_KEY=$(cat "$key_file")
            else
                log_error "文件不存在: $key_file"
                exit 1
            fi
            ;;
        *)
            log_error "无效的选择"
            exit 1
            ;;
    esac

    # 验证SSH密钥格式
    if ! echo "$SSH_KEY" | grep -q "^ssh-rsa "; then
        log_error "无效的SSH密钥格式"
        exit 1
    fi
}

setup_ssh() {
    local username=$1
    log_info "配置SSH..."

    local ssh_dir="/home/$username/.ssh"
    mkdir -p $ssh_dir

    # 添加SSH公钥
    echo "$SSH_KEY" > $ssh_dir/authorized_keys

    # 设置权限
    chmod 700 $ssh_dir
    chmod 600 $ssh_dir/authorized_keys
    chown -R $username:$username $ssh_dir

    log_info "SSH配置完成"
}

# =================================================================
# 基础软件安装
# =================================================================

install_basic_packages() {
    log_info "安装必要的软件包..."
    apt-get update
    apt-get install -y wget git curl fish sudo htop python3-pip

    # 确保 sudo 配置正确
    if [ ! -f "/etc/sudoers.d/nopasswd" ]; then
        echo "%sudo ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/nopasswd
        chmod 440 /etc/sudoers.d/nopasswd
    fi

    # 如果 /etc/sudoers 文件中没有 sudo 组，添加它
    if ! grep -q "^%sudo" /etc/sudoers; then
        echo "%sudo ALL=(ALL:ALL) ALL" >> /etc/sudoers
    fi
}

# =================================================================
# Python环境配置
# =================================================================

setup_pip() {
    local username=$1
    log_info "配置pip清华源..."

    # 创建pip配置目录
    local pip_dir="/home/$username/.pip"
    mkdir -p $pip_dir

    # 配置pip源
    cat > $pip_dir/pip.conf << EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF

    # 设置权限
    chown -R $username:$username $pip_dir

    log_info "pip源配置完成"
}

setup_miniconda() {
    local username=$1
    local miniconda_path="/home/$username/miniconda3"

    # 检查 miniconda 是否已经存在
    if [ -d "$miniconda_path" ]; then
        log_warn "Miniconda 已经安装在 $miniconda_path"
        read -p "是否重新安装? (y/n): " reinstall
        if [[ $reinstall != "y" ]]; then
            log_info "跳过 Miniconda 安装"
            return
        fi
        log_info "将删除现有安装..."
        rm -rf "$miniconda_path"
    fi

    log_info "安装Miniconda..."
    local arch=$(uname -m)
    local miniconda_url

    if [ "$arch" = "x86_64" ]; then
        miniconda_url="https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-py39_4.9.2-Linux-x86_64.sh"
    elif [ "$arch" = "aarch64" ]; then
        miniconda_url="https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-py39_4.9.2-Linux-aarch64.sh"
    else
        log_error "不支持的架构: $arch"
        exit 1
    fi

    wget -c $miniconda_url -O /tmp/miniconda.sh
    su - $username -c "bash /tmp/miniconda.sh -b -p $miniconda_path"
    rm /tmp/miniconda.sh
}

# =================================================================
# Shell环境配置
# =================================================================

setup_fish() {
    local username=$1
    log_info "安装和配置fish shell..."

    # 安装fish
    apt-get install -y fish curl

    # 安装fisher (fish的包管理器)
    su - $username -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | fish"

    # 创建fish配置目录
    local fish_config_dir="/home/$username/.config/fish"
    mkdir -p $fish_config_dir

    # 创建fish配置文件
    cat > $fish_config_dir/config.fish << 'EOL'
# 设置代理的别名
alias setproxy="set -gx ALL_PROXY socks5://127.0.0.1:1080"
alias unsetproxy="set -gx ALL_PROXY ''"
alias ip="curl http://ip-api.com/json/?lang=zh-CN"

alias sethttpsproxy="set -gx HTTPS_PROXY http://127.0.0.1:7890"
alias unsethttpsproxy="set -gx HTTPS_PROXY ''"

# 一些有用的别名
alias ll='ls -lh'
alias la='ls -lha'
alias ..='cd ..'
alias ...='cd ../..'

# 如果存在的话，将conda初始化
if test -f "$HOME/miniconda3/bin/conda"
    eval "$HOME/miniconda3/bin/conda" "shell.fish" "hook" $argv | source
end

# 设置默认编辑器
set -gx EDITOR nano

# 设置语言环境
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8

# 自定义fish问候语
function fish_greeting
    echo "Welcome to Fish Shell!"
    echo "System: "(uname -rs)
    echo "Current time: "(date "+%Y-%m-%d %H:%M:%S")
end

# 添加到PATH
fish_add_path $HOME/.local/bin
EOL

    # 设置正确的权限
    chown -R $username:$username $fish_config_dir

    # 设置fish为默认shell
    log_info "设置fish为默认shell..."
    chsh -s $(which fish) $username

    log_info "Fish shell配置完成"
}

# =================================================================
# 代理配置
# =================================================================

setup_proxy() {
    local username=$1
    log_info "安装并配置代理..."

    read -p "请输入shadowsocksr-cli的setting-url: " setting_url

    # 1. 安装shadowsocksr-cli (使用gitee源)
    log_info "安装shadowsocksr-cli..."
    su - $username -c 'pip3 install git+https://gitee.com/JavanTang/ssr-command-client.git'

    # 2. 配置SSR
    log_info "配置SSR服务器..."
    su - $username -c "shadowsocksr-cli --setting-url $setting_url"

    # 3. 更新节点
    log_info "更新SSR节点..."
    su - $username -c 'shadowsocksr-cli -u'

    # 最大重试次数
    local max_retries=20
    local retries=0
    local success=false

    while [ $retries -lt $max_retries ]; do
        # 选择节点（轮流尝试不同节点）
        log_info "尝试连接节点 $((retries + 1))..."
        su - $username -c "shadowsocksr-cli -s $((retries + 1))"

        # 启动代理服务
        log_info "启动代理服务..."
        su - $username -c 'shadowsocksr-cli -p 1080 --http-proxy start --http-proxy-port 7890'

        # 验证代理状态
        log_info "验证代理状态..."
        sleep 5  # 等待服务启动

        if su - $username -c 'curl -s https://www.google.com' > /dev/null; then
            log_info "代理设置成功，当前节点: $(($retries + 1))"
            success=true
            break
        else
            log_warn "节点 $(($retries + 1)) 未正常工作，尝试下一个节点..."
            retries=$((retries + 1))
        fi
    done

    if [ "$success" = false ]; then
        log_error "代理配置失败，请手动检查设置。"
        exit 1
    fi
}

# =================================================================
# 将当前目录夹所有的脚本复制到用户/bin目录下，并且设置为可执行，放入环境变量
# =================================================================

setup_scripts() {
    local username=$1
    log_info "配置用户脚本环境..."

    # 创建用户的bin目录
    local bin_dir="/home/$username/bin"
    mkdir -p $bin_dir

    # 复制当前目录下的所有脚本到用户bin目录
    cp -r ./* $bin_dir/

    # 设置正确的权限
    chmod -R +x $bin_dir/*
    chown -R $username:$username $bin_dir

    # 确保bin目录在PATH中
    local fish_config="/home/$username/.config/fish/config.fish"
    if ! grep -q "fish_add_path ~/bin" "$fish_config"; then
        echo "fish_add_path ~/bin" >> "$fish_config"
    fi

    # 为bash用户也添加PATH配置
    local bash_rc="/home/$username/.bashrc"
    if [ -f "$bash_rc" ]; then
        if ! grep -q "export PATH=\$HOME/bin:\$PATH" "$bash_rc"; then
            echo 'export PATH=$HOME/bin:$PATH' >> "$bash_rc"
        fi
    fi

    log_info "脚本环境配置完成"
}

# =================================================================
# 主函数
# =================================================================

main() {
    # 检查是否为root用户
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用sudo运行此脚本"
        exit 1
    fi

    # 获取用户输入
    get_user_input "$@"

    # 执行配置
    # 1. 首先创建用户和基础环境
    setup_user $USERNAME $PASSWORD

    # 2. 获取SSH密钥
    get_ssh_key

    # 3. 配置SSH
    setup_ssh $USERNAME
    install_basic_packages

    # 4. 配置pip源
    setup_pip $USERNAME

    # 5. 安装并配置代理
    setup_proxy $USERNAME

    # 等待代理服务启动
    log_info "等待10秒钟使代理服务生效..."
    sleep 10

    # 配置代理环境变量
    export ALL_PROXY=socks5://127.0.0.1:1080
    export HTTPS_PROXY=http://127.0.0.1:7890

    log_info "正在测试代理连接..."
    if curl -s https://www.google.com > /dev/null; then
        log_info "代理连接成功!"
    else
        log_warn "代理可能未正常工作，但将继续安装..."
        log_warn "如果后续步骤失败，请手动配置代理后重试"
    fi

    # 6. 安装其他环境
    setup_miniconda $USERNAME
    setup_fish $USERNAME

    # 完成提示
    log_info "环境配置完成！请注意以下事项："
    echo "1. 请重新登录以使修改生效"
    echo "2. 配置SSR代理请运行："
    echo "   shadowsocksr-cli --setting-url $setting_url"
    echo "   shadowsocksr-cli -u"
    echo "   shadowsocksr-cli -l"
    echo "3. 选择台湾节点运行："
    echo "   shadowsocksr-cli -s 18"
    echo "4. 启动代理运行："
    echo "   shadowsocksr-cli -p 1080 --http-proxy start --http-proxy-port 7890"
}

# 执行主函数
main "$@"