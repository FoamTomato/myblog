#!/bin/bash

# GitHub Pages 自定义域名配置工具
# 自动创建CNAME文件并重新部署

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示使用说明
show_usage() {
    echo "GitHub Pages 自定义域名配置工具"
    echo ""
    echo "用法:"
    echo "  $0 <domain> [www]"
    echo ""
    echo "参数:"
    echo "  domain    您的域名 (例如: example.com)"
    echo "  www       可选参数，如果要同时支持www子域 (例如: www)"
    echo ""
    echo "示例:"
    echo "  $0 example.com           # 只配置主域名"
    echo "  $0 example.com www       # 配置主域名和www子域"
    echo ""
    echo "注意:"
    echo "  - 域名格式: 不要包含http://或https://"
    echo "  - CNAME文件会被创建在source目录"
    echo "  - 配置完成后会自动重新生成和部署"
}

# 验证域名格式
validate_domain() {
    local domain=$1

    # 基本格式检查
    if [[ ! $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?)*$ ]]; then
        log_error "域名格式无效: $domain"
        log_error "域名应该只包含字母、数字和连字符，不包含http://或https://"
        return 1
    fi

    # 检查是否包含协议
    if [[ $domain =~ ^https?:// ]]; then
        log_error "域名不应包含http://或https://协议"
        log_error "请使用格式: example.com"
        return 1
    fi

    # 检查是否以连字符开头或结尾
    if [[ $domain =~ ^- ]] || [[ $domain =~ -$ ]]; then
        log_error "域名不能以连字符开头或结尾"
        return 1
    fi

    return 0
}

# 创建CNAME文件
create_cname_file() {
    local domain=$1
    local include_www=$2
    local cname_file="source/CNAME"

    log_info "创建CNAME文件..."

    # 创建或覆盖CNAME文件
    echo "$domain" > "$cname_file"

    if [[ "$include_www" == "www" ]]; then
        echo "www.$domain" >> "$cname_file"
        log_success "CNAME文件创建成功，包含:"
        log_success "  - $domain"
        log_success "  - www.$domain"
    else
        log_success "CNAME文件创建成功，包含:"
        log_success "  - $domain"
    fi

    # 显示文件内容
    echo ""
    log_info "CNAME文件内容:"
    cat "$cname_file"
}

# DNS配置指南
show_dns_guide() {
    local domain=$1
    local include_www=$2

    echo ""
    log_info "📋 DNS配置指南:"
    echo ""
    echo "请在您的域名提供商处添加以下DNS记录:"
    echo ""
    echo "1. A记录 (必需):"
    echo "   类型: A"
    echo "   主机: @"
    echo "   值:   185.199.108.153"
    echo "   值:   185.199.109.153"
    echo "   值:   185.199.110.153"
    echo "   值:   185.199.111.153"
    echo ""
    if [[ "$include_www" == "www" ]]; then
        echo "2. CNAME记录 (如果要支持www子域):"
        echo "   类型: CNAME"
        echo "   主机: www"
        echo "   值:   $domain"
        echo ""
    fi
    echo "3. 验证配置:"
    echo "   - DNS传播可能需要几分钟到24小时"
    echo "   - 可以使用 nslookup 或 dig 命令验证"
    echo "   - 示例: nslookup $domain"
}

# 重新生成和部署
regenerate_and_deploy() {
    log_info "重新生成和部署网站..."

    # 清除缓存
    hexo clean

    # 生成静态文件
    hexo generate

    # 部署
    hexo deploy

    log_success "部署完成！"
}

# 检查Git状态
check_git_status() {
    log_info "检查Git状态..."

    # 检查是否有未提交的更改
    if [[ -n $(git status --porcelain) ]]; then
        log_warning "发现未提交的更改，正在提交..."

        # 添加所有更改
        git add .

        # 提交更改
        git commit -m "feat: 配置自定义域名 $1

- 添加CNAME文件
- 配置GitHub Pages自定义域名
- 域名: $1"

        log_success "更改已提交"
    else
        log_info "工作目录是干净的"
    fi
}

# 主函数
main() {
    # 参数检查
    if [[ $# -lt 1 ]]; then
        show_usage
        exit 1
    fi

    local domain=$1
    local include_www=$2

    # 验证域名
    if ! validate_domain "$domain"; then
        exit 1
    fi

    log_info "开始配置GitHub Pages自定义域名: $domain"

    # 检查是否在Hexo项目目录
    if [[ ! -f "_config.yml" ]]; then
        log_error "未找到 _config.yml 文件，请确保在Hexo项目根目录运行此脚本"
        exit 1
    fi

    # 创建CNAME文件
    create_cname_file "$domain" "$include_www"

    # 检查并提交Git更改
    check_git_status "$domain"

    # 显示DNS配置指南
    show_dns_guide "$domain" "$include_www"

    # 询问是否立即重新部署
    echo ""
    read -p "是否现在重新生成和部署网站? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        regenerate_and_deploy
    else
        log_info "您可以稍后手动运行以下命令重新部署:"
        echo "  hexo clean && hexo generate && hexo deploy"
    fi

    echo ""
    log_success "自定义域名配置完成!"
    log_info "请按照上述DNS配置指南设置DNS记录"
    log_info "DNS更改生效后，您的网站将可以通过 $domain 访问"
}

# 如果脚本被直接调用，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
