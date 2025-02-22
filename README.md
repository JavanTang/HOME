# 环境自动配置工具

这是一个用于快速配置Linux环境的自动化工具，主要功能包括用户管理、SSH配置、基础环境安装、代理配置等。

## 功能特点

- 🔑 用户管理：创建新用户并配置sudo权限
- 🔒 SSH配置：支持从文件读取或手动输入SSH公钥
- 🛠 基础环境：自动安装和配置常用工具（wget, git, curl, fish等）
- 🌐 代理配置：自动配置SSR代理，支持HTTP代理
- 🐟 Shell环境：配置fish shell及其插件
- 🐍 Python环境：配置pip源，可选安装Miniconda

## 快速开始

### 方法1：直接在Linux系统上运行

1. 克隆仓库：
   ```bash
   git clone https://github.com/JavanTang/HOME
   cd HOME
   ```

2. 创建配置文件：
   ```bash
   cp .env.example .env
   ```

3. 编辑配置文件：
   ```bash
   nano .env
   ```
   填写必要的配置信息：
   - TEST_USERNAME：要创建的用户名
   - TEST_PASSWORD：用户密码
   - SSH_PUBLIC_KEY_PATH：SSH公钥路径（可选）
   - SSR_SETTING_URL：SSR订阅地址
   - SSR_PORT：SSR本地端口（默认1080）
   - HTTP_PROXY_PORT：HTTP代理端口（默认7890）

4. 运行脚本：
   ```bash
   sudo ./init_env.sh
   ```

### 方法2：使用Docker测试

1. 准备SSH公钥：
   ```bash
   ssh-keygen -t rsa -f id_rsa -N ""  # 如果没有现成的SSH密钥对
   ```

2. 创建并编辑配置文件：
   ```bash
   cp .env.example .env
   nano .env
   ```

3. 构建并运行Docker容器：
   ```bash
   docker build -t init-env-test .
   docker run -it init-env-test
   ```

4. 在容器中运行脚本：
   ```bash
   cd /root && ./init_env.sh
   ```

## 配置说明

### 必需的环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| TEST_USERNAME | 要创建的用户名 | - |
| TEST_PASSWORD | 用户密码 | - |
| SSR_SETTING_URL | SSR订阅地址 | - |
| SSR_PORT | SSR本地端口 | 1080 |
| HTTP_PROXY_PORT | HTTP代理端口 | 7890 |

### 可选的环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| SSH_PUBLIC_KEY_PATH | SSH公钥文件路径 | - |

如果未设置`SSH_PUBLIC_KEY_PATH`，脚本会提供两个选项：
1. 直接输入SSH公钥
2. 指定公钥文件路径

## 代理使用说明

脚本配置完成后，可以使用以下命令管理代理：

### Fish Shell下：
```fish
# 设置代理
setproxy            # 设置SOCKS5代理
sethttpsproxy       # 设置HTTP代理

# 取消代理
unsetproxy          # 取消SOCKS5代理
unsethttpsproxy     # 取消HTTP代理

# 查看当前IP
ip
```

### 手动配置SSR：
```bash
# 更新SSR配置
shadowsocksr-cli --setting-url $SSR_SETTING_URL
shadowsocksr-cli -u

# 查看可用节点
shadowsocksr-cli -l

# 选择节点（例如选择第18个节点）
shadowsocksr-cli -s 18

# 启动代理服务
shadowsocksr-cli -p 1080 --http-proxy start --http-proxy-port 7890
```

## 注意事项

1. 脚本需要root权限运行
2. 首次运行后需要重新登录以使所有配置生效
3. 如果在Docker中测试，确保：
   - 已正确配置`.env`文件
   - 已准备好SSH公钥文件
   - 构建镜像时已正确复制所有必需文件

## 常见问题

1. SSH公钥配置失败
   - 检查公钥文件路径是否正确
   - 确保公钥格式正确（以ssh-rsa开头）

2. 代理连接失败
   - 验证SSR订阅地址是否有效
   - 检查系统时间是否正确
   - 尝试手动切换不同节点

3. 软件包安装失败
   - 检查网络连接
   - 确认软件源配置正确
   - 尝试手动更新软件源缓存

