#!/bin/bash

# 高级 Hexo 博客部署脚本
# 支持多种部署方式和自动化流程

set -e

# 加载配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/deploy-config.sh"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_debug() {
    if [[ "$LOG_LEVEL" == "debug" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
    fi
}

# 发送通知
send_notification() {
    local title="$1"
    local message="$2"
    local status="${3:-info}"

    if [[ "$ENABLE_NOTIFICATION" != "true" ]] || [[ -z "$NOTIFICATION_WEBHOOK" ]]; then
        return
    fi

    local color
    case "$status" in
        "success") color="good" ;;
        "error") color="danger" ;;
        "warning") color="warning" ;;
        *) color="#808080" ;;
    esac

    local payload="{\"text\":\"$title\",\"attachments\":[{\"text\":\"$message\",\"color\":\"$color\"}]}"

    curl -s -X POST -H 'Content-type: application/json' --data "$payload" "$NOTIFICATION_WEBHOOK" || true
}

# 检查系统要求
check_system() {
    log_info "检查系统要求..."

    # 检查必需的命令
    local required_commands=("node" "npm" "git" "curl")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "必需的命令 '$cmd' 未找到"
            exit 1
        fi
    done

    # 检查Node.js版本
    local node_version=$(node -v | sed 's/v//')
    local required_version="14.0.0"

    if ! [ "$(printf '%s\n' "$required_version" "$node_version" | sort -V | head -n1)" = "$required_version" ]; then
        log_error "Node.js版本过低，需要 >= $required_version，当前版本: $node_version"
        exit 1
    fi

    log_success "系统要求检查通过"
}

# 备份当前部署
backup_current_deployment() {
    if [[ "$ENABLE_BACKUP" != "true" ]]; then
        return
    fi

    log_info "备份当前部署..."

    mkdir -p "$BACKUP_DIR"

    local backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"

    if [[ -d "public" ]]; then
        cp -r public "$backup_path"
        log_success "备份创建: $backup_path"
    fi

    # 清理旧备份
    if [[ -d "$BACKUP_DIR" ]]; then
        find "$BACKUP_DIR" -name "backup_*" -type d -mtime +$BACKUP_RETENTION -exec rm -rf {} + 2>/dev/null || true
    fi
}

# 设置Git配置
setup_git() {
    log_info "设置Git配置..."

    git config user.name "$GIT_USER_NAME"
    git config user.email "$GIT_USER_EMAIL"

    # 设置安全的Git配置
    git config --global --add safe.directory "$(pwd)"

    log_success "Git配置完成"
}

# 安装依赖
install_dependencies() {
    log_info "安装项目依赖..."

    # 缓存npm依赖
    if [[ "$ENABLE_CACHE" == "true" ]]; then
        mkdir -p ~/.npm
        npm config set cache ~/.npm --global
    fi

    # 安装项目依赖
    if [[ -f "yarn.lock" ]]; then
        log_info "检测到yarn，使用yarn安装依赖"
        yarn install --frozen-lockfile
    elif [[ -f "package-lock.json" ]]; then
        log_info "检测到npm，使用npm安装依赖"
        npm ci
    else
        log_info "未检测到锁定文件，使用npm install"
        npm install
    fi

    # 安装Hexo CLI（如果需要）
    if ! command -v hexo &> /dev/null; then
        log_info "安装Hexo CLI..."
        npm install -g hexo-cli
    fi

    log_success "依赖安装完成"
}

# 执行预构建命令
pre_build() {
    if [[ -n "$PRE_BUILD_COMMAND" ]]; then
        log_info "执行预构建命令: $PRE_BUILD_COMMAND"
        eval "$PRE_BUILD_COMMAND"
        log_success "预构建命令执行完成"
    fi
}

# 构建站点
build_site() {
    log_info "构建Hexo站点..."

    # 清理缓存
    hexo clean

    # 执行预构建
    pre_build

    # 生成静态文件
    if [[ "$ENABLE_MINIFY" == "true" ]]; then
        log_info "启用压缩模式构建"
        hexo generate --minify
    else
        hexo generate
    fi

    # 检查构建结果
    if [[ ! -d "public" ]]; then
        log_error "构建失败，未找到public目录"
        exit 1
    fi

    # 统计构建结果
    local file_count=$(find public -type f | wc -l)
    local dir_size=$(du -sh public | cut -f1)
    log_success "构建完成，共生成 $file_count 个文件，大小: $dir_size"
}

# 执行后构建命令
post_build() {
    if [[ -n "$POST_BUILD_COMMAND" ]]; then
        log_info "执行后构建命令: $POST_BUILD_COMMAND"
        eval "$POST_BUILD_COMMAND"
        log_success "后构建命令执行完成"
    fi
}

# 部署到GitHub Pages
deploy_github() {
    log_info "部署到GitHub Pages..."

    # 检查是否配置了远程仓库
    if ! git remote get-url origin &> /dev/null; then
        log_error "未配置Git远程仓库"
        exit 1
    fi

    local repo_url=$(git remote get-url origin)
    local temp_dir=$(mktemp -d)
    local commit_message="Site updated: $(date +'%Y-%m-%d %H:%M:%S')"

    log_debug "临时目录: $temp_dir"
    log_debug "仓库URL: $repo_url"

    # 克隆目标分支
    if git ls-remote --heads origin "$DEPLOY_BRANCH" | grep -q "$DEPLOY_BRANCH"; then
        log_info "克隆现有分支: $DEPLOY_BRANCH"
        git clone --branch "$DEPLOY_BRANCH" --single-branch "$repo_url" "$temp_dir"
    else
        log_info "创建新分支: $DEPLOY_BRANCH"
        git clone "$repo_url" "$temp_dir"
        cd "$temp_dir"
        git checkout --orphan "$DEPLOY_BRANCH"
        git rm -rf .
        cd - > /dev/null
    fi

    # 复制构建文件
    log_info "复制构建文件..."
    cd "$temp_dir"
    rm -rf *
    cp -r "$SCRIPT_DIR/public/"* .

    # 添加CNAME文件（如果配置了）
    if [[ -n "$CNAME" ]]; then
        echo "$CNAME" > CNAME
        log_info "添加CNAME: $CNAME"
    fi

    # 提交更改
    if [[ -n "$(git status --porcelain)" ]]; then
        git add .
        git commit -m "$commit_message"

        # 推送到远程
        git push origin "$DEPLOY_BRANCH"
        log_success "部署到GitHub Pages完成"
    else
        log_info "没有新的更改需要部署"
    fi

    # 清理临时目录
    cd "$SCRIPT_DIR"
    rm -rf "$temp_dir"
}

# 部署到自定义服务器
deploy_custom_server() {
    log_info "部署到自定义服务器..."

    if [[ -z "$CUSTOM_SERVER_HOST" ]] || [[ -z "$CUSTOM_SERVER_USER" ]]; then
        log_error "自定义服务器配置不完整"
        exit 1
    fi

    local server_path="${CUSTOM_SERVER_PATH:-/var/www/html}"

    # 使用rsync或scp上传文件
    if command -v rsync &> /dev/null; then
        log_info "使用rsync上传文件..."
        rsync -avz --delete --exclude="$EXCLUDE_FILES" \
            public/ "$CUSTOM_SERVER_USER@$CUSTOM_SERVER_HOST:$server_path/"
    else
        log_info "使用scp上传文件..."
        scp -r public/* "$CUSTOM_SERVER_USER@$CUSTOM_SERVER_HOST:$server_path/"
    fi

    log_success "部署到自定义服务器完成"
}

# 主部署函数
deploy() {
    case "$DEPLOY_TARGET" in
        "github")
            deploy_github
            ;;
        "custom")
            deploy_custom_server
            ;;
        *)
            log_error "不支持的部署目标: $DEPLOY_TARGET"
            exit 1
            ;;
    esac
}

# 显示部署状态
show_status() {
    log_info "=== 部署状态 ==="

    if [[ -d "public" ]]; then
        local file_count=$(find public -type f | wc -l)
        local dir_size=$(du -sh public | cut -f1)
        echo "构建文件: $file_count 个文件，大小: $dir_size"
    else
        echo "构建文件: 未构建"
    fi

    if git remote get-url origin &> /dev/null; then
        local remote_url=$(git remote get-url origin)
        echo "远程仓库: $remote_url"
    else
        echo "远程仓库: 未配置"
    fi

    echo "部署分支: $DEPLOY_BRANCH"
    echo "部署目标: $DEPLOY_TARGET"

    if [[ -d "$BACKUP_DIR" ]]; then
        local backup_count=$(find "$BACKUP_DIR" -name "backup_*" -type d | wc -l)
        echo "备份数量: $backup_count"
    fi

    echo "==============="
}

# 清理函数
cleanup() {
    log_info "执行清理..."

    # 清理临时文件
    find . -name "*.tmp" -type f -delete 2>/dev/null || true
    find . -name ".DS_Store" -type f -delete 2>/dev/null || true

    # 清理构建缓存
    if [[ "$ENABLE_CACHE" != "true" ]] && [[ -d "$CACHE_DIR" ]]; then
        rm -rf "$CACHE_DIR"
        log_info "清理缓存目录: $CACHE_DIR"
    fi

    log_success "清理完成"
}

# 自动检测和设置代理
auto_detect_proxy() {
    log_info "检测代理设置..."

    # 检查环境变量
    if [[ -n "$http_proxy" || -n "$https_proxy" ]]; then
        log_success "检测到环境变量代理设置"
        return 0
    fi

    # 检查Git配置
    if git config --global --get http.proxy &>/dev/null; then
        log_success "检测到Git代理配置"
        return 0
    fi

    # 检查配置文件
    if [[ -f ".proxy-config" ]]; then
        log_info "发现代理配置文件，正在加载..."
        if source ".proxy-config" 2>/dev/null; then
            export http_proxy="$HTTP_PROXY"
            export https_proxy="$HTTPS_PROXY"
            export all_proxy="$ALL_PROXY"

            # 设置Git代理
            git config --global http.proxy "$HTTP_PROXY"
            git config --global https.proxy "$HTTPS_PROXY"

            log_success "代理配置已从文件加载"
            return 0
        fi
    fi

    # 尝试自动启用本地代理
    local default_proxy="http://127.0.0.1:7890"
    log_info "尝试连接本地代理: $default_proxy"

    if curl -s --max-time 5 --proxy "$default_proxy" https://github.com > /dev/null; then
        log_success "本地代理可用，正在启用..."

        export http_proxy="$default_proxy"
        export https_proxy="$default_proxy"
        export all_proxy="socks5://127.0.0.1:7890"

        # 设置Git代理
        git config --global http.proxy "$default_proxy"
        git config --global https.proxy "$default_proxy"

        log_success "代理已自动启用"
        return 0
    fi

    log_info "未检测到代理设置，继续使用直连模式"
    return 1
}

# 主函数
main() {
    local command="${1:-deploy}"

    # 加载并导出配置
    load_env
    export_config

    # 自动检测代理设置
    auto_detect_proxy

    log_info "开始Hexo博客部署 - 命令: $command"

    # 检查是否有未提交的更改
    if [[ "$command" == "deploy" ]] && [[ -n "$(git status --porcelain)" ]]; then
        log_warning "检测到工作目录有未提交的更改"
        echo "建议在部署前提交源代码更改，或使用以下命令之一:"
        echo "  git add . && git commit -m '更新博客内容'"
        echo "  或使用 --skip-source-check 参数跳过此检查"
        echo ""

        # 如果不是强制跳过，询问用户
        if [[ "${2:-}" != "--skip-source-check" ]]; then
            read -p "是否要继续部署？(y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "部署已取消"
                exit 0
            fi
        fi
    fi

    case "$command" in
        "deploy")
            check_system
            backup_current_deployment
            setup_git
            install_dependencies
            build_site
            post_build
            deploy
            cleanup
            send_notification "部署完成" "Hexo博客已成功部署到 $DEPLOY_TARGET" "success"
            log_success "部署流程完成！"
            ;;
        "deploy-all")
            log_info "执行完整部署流程（包含源代码提交）"

            # 检查并提交源代码
            if [[ -n "$(git status --porcelain)" ]]; then
                log_info "提交源代码更改..."
                git add .
                read -p "请输入提交信息 (默认: 'Auto commit: $(date +'%Y-%m-%d %H:%M:%S')'): " commit_msg
                commit_msg=${commit_msg:-"Auto commit: $(date +'%Y-%m-%d %H:%M:%S')"}
                git commit -m "$commit_msg"
                git push origin "$SOURCE_BRANCH"
                log_success "源代码已提交并推送"
            else
                log_info "没有源代码更改需要提交"
            fi

            # 执行标准部署流程
            check_system
            backup_current_deployment
            setup_git
            install_dependencies
            build_site
            post_build
            deploy
            cleanup
            send_notification "完整部署完成" "Hexo博客源代码和构建产物已成功部署" "success"
            log_success "完整部署流程完成！"
            ;;
        "build")
            check_system
            setup_git
            install_dependencies
            build_site
            post_build
            log_success "构建完成"
            ;;
        "status")
            show_status
            ;;
        "cleanup")
            cleanup
            ;;
        "backup")
            backup_current_deployment
            ;;
        *)
            echo "用法: $0 [deploy|deploy-all|build|status|cleanup|backup] [--skip-source-check]"
            echo ""
            echo "命令说明:"
            echo "  deploy     - 完整部署流程（只部署构建产物）"
            echo "  deploy-all - 完整部署流程（包含源代码提交）"
            echo "  build      - 只构建不部署"
            echo "  status     - 显示部署状态"
            echo "  cleanup    - 清理临时文件"
            echo "  backup     - 备份当前部署"
            echo ""
            echo "选项说明:"
            echo "  --skip-source-check  - 跳过源代码状态检查"
            exit 1
            ;;
    esac
}

# 错误处理
trap 'send_notification "部署失败" "Hexo博客部署过程中出现错误: $?" "error"' ERR

# 执行主函数
main "$@"
