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
    touch /root/init/.root
    echo "初始化完成"
else
    echo "检测到已初始化，跳过初始化步骤..."
fi

# 每次启动时都要执行的操作

# 配置 SSH 服务，/var/run/sshd与/run/sshd等价为运行时目录
if [ ! -d "/run/sshd" ]; then
    mkdir -p /run/sshd
    chmod 0755 /run/sshd
    # RUN mkdir -p -m 0755 /run/sshd
fi

# 确保 SSH 主机密钥存在（/etc/ssh/ssh_host_rsa_key，/etc/ssh/ssh_host_ecdsa_key，/etc/ssh/ssh_host_ed25519_key）
if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
    ssh-keygen -A
fi

# 每次启动都设置ROOT用户密码
ROOT_PWD_FILE="/root/init/.root"
if [ -f "$ROOT_PWD_FILE" ]; then
    ROOT_PWD=$(cat "$ROOT_PWD_FILE")
else
    ROOT_PWD="123456"
fi
echo "root:$ROOT_PWD" | chpasswd


# 遍历目标目录下的所有条目
for file in /root/bin/* ; do
    # 过滤：仅处理普通文件（排除目录、符号链接、设备文件等）
    if [ -f "$file" ]; then
        # 获取纯文件名（去掉路径，只保留文件名）
        filename=$(basename "$file")
        
        # 【兼容版】判断文件名是否包含 "."（无扩展语法，POSIX 标准）
        # 方法1：用 case 语句匹配后缀（推荐，无外部命令依赖）
        case "$filename" in
            *.*) 
                # 有后缀的文件跳过
                echo "【跳过】有后缀的文件：$file"
                ;;
            *) 
                # 无后缀文件添加执行权限
                chmod +x "$file"
                echo "【成功】已添加执行权限：$file"
                ;;
        esac
        # 【备选方法2】用 grep 匹配（需依赖 grep 命令，效果相同）
        # if echo "$filename" | grep -q '\.'; then
        #     echo "【跳过】有后缀的文件：$file"
        # else
        #     chmod +x "$file"
        #     echo "【成功】已添加执行权限：$file"
        # fi
    fi
done

echo -e "\n/root/bin目录下可执行文件已加入执行权限"

# 强制设置全局 PATH（所有子进程都会继承）
export PATH=/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
echo -e "\n/root/bin目录已加入执行PATH"

# 执行传入的命令，通常是启动 supervisord
exec "$@"
