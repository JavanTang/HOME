FROM swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/ubuntu:latest-linuxarm64

# 设置非交互式环境
ENV DEBIAN_FRONTEND=noninteractive

# 先安装ca-certificates
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# 配置清华源（ARM架构，使用Ubuntu 22.04 jammy）
RUN rm -f /etc/apt/sources.list
RUN echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy main restricted universe multiverse" > /etc/apt/sources.list
RUN echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy-backports main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy-security main restricted universe multiverse" >> /etc/apt/sources.list

# 安装基本工具
RUN apt-get clean && \
    apt-get update && \
    apt-get install -y \
    sudo \
    curl \
    wget \
    git \
    fish \
    htop \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 复制脚本和环境变量文件到容器
COPY init_env.sh /root/init_env.sh
COPY .env* /root/
COPY id_rsa.pub /root/id_rsa.pub
RUN chmod +x /root/init_env.sh

# 设置工作目录
WORKDIR /root

# 启动bash
CMD ["/bin/bash"] 