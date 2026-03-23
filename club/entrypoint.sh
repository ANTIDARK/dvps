#!/bin/sh

# 进入工作目录
cd /root

# 创建初始化标记文件所在的目录
mkdir -p /root/init

# 检查是否首次启动（通过检查标记文件）
if [ ! -f "/root/init/.initialized" ]; then
    echo "首次启动，执行初始化操作..."

    # 创建必要的目录
    mkdir -p /root/bin
    

    # 为二进制文件设置权限并移动到/root/bin下
    for bin in /club/bin/*; do
        chmod 755 $bin
        # 直接使用完整路径$bin，无需额外拼接/club/bin/
        # 注意：如果/bin下都是文件，-r可以去掉；如果有目录则保留
        cp -r "$bin" "/root/bin/"
    done

    # 复制必要的配置
    cp /club/configs/.bashrc /root/.bashrc
    cp /club/configs/supervisord.conf /root/init/supervisord.conf

    # 创建标记文件，表示已初始化
    touch /root/init/.initialized
    echo "初始化完成"
else
    echo "检测到已初始化，跳过初始化步骤..."
fi

# 每次启动时都要执行的操作

# 配置 SSH 服务
if [ ! -d "/var/run/sshd" ]; then
    mkdir -p /var/run/sshd
    chmod 0755 /var/run/sshd
fi

# 确保 SSH 主机密钥存在
if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
    ssh-keygen -A
fi

# 每次启动都设置club用户密码
CLUB_PWD_FILE="/root/init/.club"
if [ -f "$CLUB_PWD_FILE" ]; then
    CLUB_PWD=$(cat "$CLUB_PWD_FILE")
else
    CLUB_PWD="123456"
fi
echo "club:$CLUB_PWD" | chpasswd

export PATH=“/root/bin:$PATH”

# 执行传入的命令，通常是启动 supervisord
exec "$@"
