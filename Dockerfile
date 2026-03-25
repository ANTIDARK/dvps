# 使用较小的基础镜像
FROM debian:trixie-slim

# 设置环境变量，避免交互式安装
ENV DEBIAN_FRONTEND=noninteractive \
    # 加入PATH
    PATH=/root/bin:$PATH \
    # 关键：指定s6-overlay配置目录为/root/init/s6-overlay/
    S6_OVERLAY_CONFIG_DIR=/root/init/s6-overlay/ \
    # s6-overlay通用环境变量（可选，优化体验）
    S6_KEEP_ENV=1 \
    # 服务启动超时（秒，0=禁用）
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=30 \
    # 优雅停止超时（秒）
    S6_KILL_GRACETIME=10 \
    # 只读根文件系统（K8s）
    S6_READ_ONLY_ROOT=1 \
    # 初始化失败行为（2=继续）
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2

# 非 root 运行兼容（K8s）\
# ENV S6_YES_I_WANT_A_WORLD_WRITABLE_RUN_BECAUSE_KUBERNETES=1

# 1. 先更新索引
RUN apt-get update -qq && \
    # 2. 再升级已装包（非必须，可省）
    apt-get upgrade -y && \
    # 3. 安装你需要的工具，最后清理缓存
    apt-get install -y --no-install-recommends \
    vim supervisor sudo openssh-server iputils-ping net-tools curl ca-certificates python3 python3-pip python3-venv git wget fish micro gh tmux iproute2 iptables procps lrzsz dnsutils tar unzip xz-utils && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # 加入PATH
    echo 'export PATH=/root/bin:$PATH' >> /etc/profile.d/custom.sh && chmod +x /etc/profile.d/custom.sh &&\
    # 设置 root 密码
    echo "root:123456" | chpasswd && \
    # 允许 root 远程登录
    sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config

# 最新版本（2026-03）
ARG S6_OVERLAY_VERSION=3.2.2.0

# 直接下载 s6-overlay 安装包到根目录 /，自动解压
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /

# 创建 sshd 运行目录
# RUN mkdir -p -m 0755 /run/sshd
# 生成主机密钥
# RUN ssh-keygen -A

# 创建club用户并设置密码，同时将其加入sudo组,配置无密码sudo
# RUN useradd -m -s /bin/bash club \
    # && echo "club:123456" | chpasswd \
    # && usermod -aG sudo club 与下面行为相同作用
    # addgroup club wheel && \
    # echo "club ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


# 将当前目录的所有文件复制到容器的 /club 目录下
# COPY ./club/bin /club/bin
# COPY ./club/configs /club/configs
# COPY ./club/entrypoint.sh /club/entrypoint.sh
COPY ./club /club

# 复制自定义s6-overlay配置（./s6-overlay/）到容器内/club/
# COPY ./club/configs/s6-overlay /club/
# 给所有s6 run脚本添加可执行权限（v3必需）
RUN chmod +x /club/configs/s6-overlay/s6-rc.d/*/run

# 设置工作目录
WORKDIR /root

# 设置执行权限
RUN chmod +x /club/entrypoint.sh

EXPOSE 8888 5000

# 设置入口点
ENTRYPOINT ["/club/entrypoint.sh"]

# 设置默认命令
CMD ["/init"]
