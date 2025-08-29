#!/bin/bash

# Hexo 博客代理设置脚本
# 用于快速启用/禁用代理设置

set -e

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

# 默认代理设置
DEFAULT_HTTP_PROXY="http://127.0.0.1:7890"
DEFAULT_HTTPS_PROXY="http://127.0.0.1:7890"
DEFAULT_ALL_PROXY="socks5://127.0.0.1:7890"

# 启用代理
enable_proxy() {
    local http_proxy="${1:-$DEFAULT_HTTP_PROXY}"
    local https_proxy="${2:-$DEFAULT_HTTPS_PROXY}"
    local all_proxy="${3:-$DEFAULT_ALL_PROXY}"

    log_info "启用代理设置..."

    # 设置环境变量
    export http_proxy="$http_proxy"
    export https_proxy="$https_proxy"
    export all_proxy="$all_proxy"

    # 设置Git代理
    git config --global http.proxy "$http_proxy"
    git config --global https.proxy "$https_proxy"

    # 设置npm代理
    npm config set proxy "$http_proxy"
    npm config set https-proxy "$https_proxy"

    # 设置yarn代理（如果安装了）
    if command -v yarn &> /dev/null; then
        yarn config set proxy "$http_proxy"
        yarn config set https-proxy "$https_proxy"
    fi

    log_success "代理已启用"
    log_info "HTTP代理: $http_proxy"
    log_info "HTTPS代理: $https_proxy"
    log_info "SOCKS5代理: $all_proxy"

    # 测试连接
    test_proxy_connection
}

# 禁用代理
disable_proxy() {
    log_info "禁用代理设置..."

    # 清除环境变量
    unset http_proxy
    unset https_proxy
    unset all_proxy

    # 清除Git代理
    git config --global --unset http.proxy
    git config --global --unset https.proxy

    # 清除npm代理
    npm config delete proxy
    npm config delete https-proxy

    # 清除yarn代理
    if command -v yarn &> /dev/null; then
        yarn config delete proxy
        yarn config delete https-proxy
    fi

    log_success "代理已禁用"
}

# 显示当前代理状态
show_proxy_status() {
    log_info "检查代理状态..."

    echo ""
    echo "=== 🌐 代理状态 ==="
    echo ""

    # 检查环境变量
    echo "环境变量:"
    echo "  http_proxy: ${http_proxy:-未设置}"
    echo "  https_proxy: ${https_proxy:-未设置}"
    echo "  all_proxy: ${all_proxy:-未设置}"
    echo ""

    # 检查Git配置
    echo "Git配置:"
    local git_http=$(git config --global --get http.proxy 2>/dev/null || echo "未设置")
    local git_https=$(git config --global --get https.proxy 2>/dev/null || echo "未设置")
    echo "  http.proxy: $git_http"
    echo "  https.proxy: $git_https"
    echo ""

    # 检查npm配置
    echo "npm配置:"
    local npm_http=$(npm config get proxy 2>/dev/null || echo "未设置")
    local npm_https=$(npm config get https-proxy 2>/dev/null || echo "未设置")
    echo "  proxy: $npm_http"
    echo "  https-proxy: $npm_https"
    echo ""

    # 检查网络连接
    echo "网络连接测试:"
    test_basic_connectivity
}

# 测试代理连接
test_proxy_connection() {
    log_info "测试代理连接..."

    local targets=(
        "https://github.com|GitHub"
        "https://api.github.com|GitHub API"
        "https://registry.npmjs.org|NPM Registry"
    )

    for target in "${targets[@]}"; do
        local url=$(echo "$target" | cut -d'|' -f1)
        local name=$(echo "$target" | cut -d'|' -f2)

        if curl -s --max-time 10 "$url" > /dev/null; then
            log_success "✓ $name 连接正常"
        else
            log_error "✗ $name 连接失败"
        fi
    done
}

# 测试基本网络连接
test_basic_connectivity() {
    local targets=(
        "https://github.com|GitHub"
        "https://www.google.com|Google"
    )

    for target in "${targets[@]}"; do
        local url=$(echo "$target" | cut -d'|' -f1)
        local name=$(echo "$target" | cut -d'|' -f2)

        if curl -s --max-time 5 "$url" > /dev/null; then
            echo "  ✓ $name 可访问"
        else
            echo "  ✗ $name 不可访问"
        fi
    done
}

# 保存代理配置
save_proxy_config() {
    local config_file="${1:-.proxy-config}"

    log_info "保存代理配置到 $config_file"

    cat > "$config_file" << EOF
# 代理配置文件
# 自动生成于 $(date)

HTTP_PROXY="$DEFAULT_HTTP_PROXY"
HTTPS_PROXY="$DEFAULT_HTTPS_PROXY"
ALL_PROXY="$DEFAULT_ALL_PROXY"
EOF

    log_success "配置已保存"
}

# 加载代理配置
load_proxy_config() {
    local config_file="${1:-.proxy-config}"

    if [[ -f "$config_file" ]]; then
        log_info "加载代理配置从 $config_file"
        source "$config_file"
        enable_proxy "$HTTP_PROXY" "$HTTPS_PROXY" "$ALL_PROXY"
    else
        log_warning "配置文件不存在: $config_file"
    fi
}

# 显示帮助信息
show_help() {
    echo "Hexo 博客代理设置脚本"
    echo ""
    echo "用法:"
    echo "  $0 <命令> [参数...]"
    echo ""
    echo "命令:"
    echo "  enable     启用代理"
    echo "  disable    禁用代理"
    echo "  status     显示代理状态"
    echo "  test       测试代理连接"
    echo "  save       保存代理配置"
    echo "  load       加载代理配置"
    echo "  help       显示帮助信息"
    echo ""
    echo "参数:"
    echo "  --http     HTTP代理地址"
    echo "  --https    HTTPS代理地址"
    echo "  --socks5   SOCKS5代理地址"
    echo ""
    echo "示例:"
    echo "  $0 enable                           # 启用默认代理"
    echo "  $0 enable --http http://127.0.0.1:8080"
    echo "  $0 disable                          # 禁用所有代理"
    echo "  $0 status                           # 查看代理状态"
    echo "  $0 test                             # 测试连接"
    echo ""
    echo "快速使用:"
    echo "  source <($0 enable)                 # 启用并设置环境变量"
}

# 主函数
main() {
    local command="$1"
    shift

    case "$command" in
        "enable")
            local http_proxy=""
            local https_proxy=""
            local all_proxy=""

            # 解析参数
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --http)
                        http_proxy="$2"
                        shift 2
                        ;;
                    --https)
                        https_proxy="$2"
                        shift 2
                        ;;
                    --socks5)
                        all_proxy="$2"
                        shift 2
                        ;;
                    *)
                        log_error "未知参数: $1"
                        show_help
                        exit 1
                        ;;
                esac
            done

            enable_proxy "$http_proxy" "$https_proxy" "$all_proxy"

            # 输出环境变量设置命令
            echo ""
            echo "=== 📝 环境变量设置命令 ==="
            echo "export http_proxy=\"$DEFAULT_HTTP_PROXY\""
            echo "export https_proxy=\"$DEFAULT_HTTPS_PROXY\""
            echo "export all_proxy=\"$DEFAULT_ALL_PROXY\""
            echo ""
            ;;
        "disable")
            disable_proxy
            ;;
        "status")
            show_proxy_status
            ;;
        "test")
            test_proxy_connection
            ;;
        "save")
            save_proxy_config "$@"
            ;;
        "load")
            load_proxy_config "$@"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# 执行主函数
main "$@"
