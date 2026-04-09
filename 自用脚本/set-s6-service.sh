#!/bin/bash
set -euo pipefail

# ==================== 配置项 ====================
# s6-rc 基础目录（标准 s6-overlay 路径）
S6_RC_BASE="/root/init/s6-overlay/s6-rc.d"
# 用户启用目录
USER_CONTENTS="${S6_RC_BASE}/user/contents.d"
# 默认服务类型（longrun: 常驻进程 | oneshot: 一次性任务）
DEFAULT_TYPE="longrun"
# =================================================

# 帮助信息
usage() {
  cat << EOF
用法: $0 [选项]
快速创建 s6-overlay 服务运行配置

选项:
  -n, --name <服务名>      必选，服务名称（如 nginx、redis）
  -c, --cmd <启动命令>     必选，服务实际运行命令（如 "nginx -g 'daemon off;'"）
  -t, --type <类型>        可选，服务类型：longrun(默认) / oneshot
  -d, --dep <依赖服务>     可选，依赖的服务名（可多次指定）
  -h, --help              显示此帮助信息

示例:
  $0 -n nginx -c "nginx -g 'daemon off;'"
  $0 -n myapp -c "/app/start.sh" -t longrun -d base-files -d log
EOF
  exit 1
}

# 参数解析
SVC_NAME=""
SVC_CMD=""
SVC_TYPE="${DEFAULT_TYPE}"
DEPS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name) SVC_NAME="$2"; shift 2 ;;
    -c|--cmd) SVC_CMD="$2"; shift 2 ;;
    -t|--type) SVC_TYPE="$2"; shift 2 ;;
    -d|--dep) DEPS+=("$2"); shift 2 ;;
    -h|--help) usage ;;
    *) echo "未知参数: $1"; usage ;;
  esac
done

# 必选参数校验
[[ -z "${SVC_NAME}" ]] && { echo "错误：请指定服务名 -n"; usage; }
[[ -z "${SVC_CMD}" ]] && { echo "错误：请指定启动命令 -c"; usage; }
[[ "${SVC_TYPE}" != "longrun" && "${SVC_TYPE}" != "oneshot" ]] && {
  echo "错误：类型只能是 longrun 或 oneshot"; usage;
}

# 服务目录
SVC_DIR="${S6_RC_BASE}/${SVC_NAME}"

# 1. 创建服务目录
echo "==> 创建服务目录: ${SVC_DIR}"
mkdir -p "${SVC_DIR}"

# 2. 写入服务类型
echo "==> 设置服务类型: ${SVC_TYPE}"
echo -n "${SVC_TYPE}" > "${SVC_DIR}/type"

# 3. 写入依赖（如果有）
if [[ ${#DEPS[@]} -gt 0 ]]; then
  echo "==> 设置依赖: ${DEPS[*]}"
  printf "%s\n" "${DEPS[@]}" > "${SVC_DIR}/dependencies"
fi

# 4. 生成 run 启动脚本（s6 标准格式）
echo "==> 生成 run 启动脚本"
cat > "${SVC_DIR}/run" << EOF
#!/bin/execlineb -P
${SVC_CMD}
EOF
# 赋予执行权限
chmod +x "${SVC_DIR}/run"

# 5. 启用服务（链接到 user/contents.d）
echo "==> 启用服务: 链接到 ${USER_CONTENTS}"
mkdir -p "${USER_CONTENTS}"
ln -sf "../${SVC_NAME}" "${USER_CONTENTS}/${SVC_NAME}"

# 完成提示
echo -e "\n✅ 服务 ${SVC_NAME} 配置创建完成！"
echo "📁 配置路径: ${SVC_DIR}"
echo -e "\nℹ️  生效方式：重启容器 / 执行 s6-svc -u /run/service/${SVC_NAME}"
