# 使用较小的基础镜像
FROM debian:trixie-slim

# 设置环境变量，避免交互式安装
ENV DEBIAN_FRONTEND=noninteractive \
    # 加入PATH
    PATH=/root/bin:$PATH \
    # 设置系统环境为中文 UTF-8
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8 \
    # 设置时区（上海时区）
    TZ=Asia/Shanghai


# 1. 先更新索引
RUN apt-get update -qq && \
    # 2. 再升级已装包（非必须，可省）
    apt-get upgrade -y && \
    # 3. 安装你需要的工具，最后清理缓存
    apt-get install -y --no-install-recommends \
    vim supervisor sudo openssh-server iputils-ping net-tools curl ca-certificates python3 python3-pip python3-venv git wget fish micro gh tmux iproute2 iptables procps lrzsz dnsutils tar unzip locales tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # 加入PATH
    echo 'export PATH=/root/bin:$PATH' >> /etc/profile.d/custom.sh && chmod +x /etc/profile.d/custom.sh &&\
    # 设置 root 密码
    echo "root:123456" | chpasswd && \
    # 允许 root 远程登录
    sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    # 生成中文 UTF-8 locale
    echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    # 设置时区（上海时区）
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

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

# 设置工作目录
WORKDIR /root

# 设置执行权限
RUN chmod +x /club/entrypoint.sh 

EXPOSE 8888 5000

# 设置入口点
ENTRYPOINT ["/club/entrypoint.sh"]

# 设置默认命令
CMD ["/usr/bin/supervisord", "-n", "-c", "/root/init/supervisord.conf"]
