# 使用debian镜像
FROM debian:trixie-backports

# 设置环境变量，避免交互式安装
ENV DEBIAN_FRONTEND=noninteractive

# 1. 先更新索引
RUN apt-get update -qq && \
    # 2. 再升级已装包（非必须，可省）
    apt-get upgrade -y && \
    # 3. 安装你需要的工具，最后清理缓存(可选包：python3-tk )
    apt-get install -y --no-install-recommends \
    vim supervisor sudo openssh-server iputils-ping net-tools curl ca-certificates python3 python3-pip python3-venv git && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 创建club用户并设置密码，同时将其加入sudo组
RUN useradd -m -s /bin/bash club \
    && echo "club:123456" | chpasswd \
    && usermod -aG sudo club

# 将当前目录的所有文件复制到容器的 /club 目录下
COPY ./club/bin /club/bin
COPY ./club/configs /club/configs
COPY ./club/entrypoint.sh /club/entrypoint.sh

# 设置工作目录
WORKDIR /root

# 设置执行权限
RUN chmod +x /club/entrypoint.sh && cp /club/bin/u* /bin

# 设置入口点
ENTRYPOINT ["/club/entrypoint.sh"]

# 设置默认命令
CMD ["/usr/bin/supervisord", "-n", "-c", "/root/supervisord/supervisord.conf"]
