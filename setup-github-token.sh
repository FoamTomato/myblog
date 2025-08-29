#!/bin/bash

# GitHub Token 配置脚本
# 用于配置Hexo部署所需的GitHub Personal Access Token

set -e

echo "🔑 GitHub Token 配置脚本"
echo "=========================="

BLOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$BLOG_DIR/_config.yml"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查配置文件
check_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "未找到 _config.yml 配置文件"
        exit 1
    fi
    log_success "找到配置文件: $CONFIG_FILE"
}

# 获取GitHub用户名
get_github_username() {
    # 尝试从Git远程URL中提取用户名
    if git remote get-url origin &>/dev/null; then
        local remote_url=$(git remote get-url origin)
        if [[ $remote_url == https://github.com/* ]]; then
            echo "$remote_url" | sed 's|https://github.com/\([^/]*\)/.*|\1|'
            return 0
        fi
    fi

    # 手动输入
    read -p "请输入您的GitHub用户名: " username
    echo "$username"
}

# 配置Token
configure_token() {
    local username="$1"

    echo ""
    log_info "📋 配置步骤:"
    echo "1. 打开浏览器访问: https://github.com/settings/tokens"
    echo "2. 点击 'Generate new token (classic)'"
    echo "3. 填写Note: 'Hexo Deploy Token'"
    echo "4. 选择权限范围:"
    echo "   - 勾选 'repo' (Full control of private repositories)"
    echo "   - 或勾选 'public_repo' (Access public repositories)"
    echo "5. 点击 'Generate token'"
    echo "6. 复制生成的token"
    echo ""

    read -p "请输入您的GitHub Personal Access Token: " token

    if [[ -z "$token" ]]; then
        log_error "Token不能为空"
        exit 1
    fi

    # 更新配置文件
    log_info "🔧 更新配置文件..."

    # 备份原配置
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

    # 更新repo配置
    sed -i.bak "s|github: https://github.com/$username/myblog.git|github: https://$token@github.com/$username/myblog.git|" "$CONFIG_FILE"

    if [[ $? -eq 0 ]]; then
        log_success "✅ Token配置成功"
    else
        log_error "❌ 配置更新失败"
        exit 1
    fi
}

# 测试配置
test_configuration() {
    log_info "🧪 测试配置..."

    # 尝试执行hexo deploy --dry-run
    if hexo deploy --dry-run > /dev/null 2>&1; then
        log_success "✅ 配置测试通过"
    else
        log_warning "⚠️ 配置测试失败，可能是网络或权限问题"
        log_info "💡 请检查:"
        log_info "   1. Token是否正确"
        log_info "   2. 网络连接是否正常"
        log_info "   3. GitHub仓库权限是否足够"
    fi
}

# 显示配置信息
show_config_info() {
    echo ""
    log_info "📝 配置信息:"
    echo "配置文件: $CONFIG_FILE"
    echo "仓库地址: https://github.com/$username/myblog"
    echo "部署分支: gh-pages"
    echo ""
    log_success "🎉 配置完成！"
    echo ""
    log_info "现在您可以使用以下命令进行部署:"
    echo "  ./deploy.sh --all          # 一键完整部署"
    echo "  hexo clean && hexo generate && hexo deploy  # 手动部署"
}

# 主函数
main() {
    log_info "开始配置GitHub Token..."

    cd "$BLOG_DIR"

    # 检查配置文件
    check_config

    # 获取GitHub用户名
    local username=$(get_github_username)
    log_info "GitHub用户名: $username"

    # 配置Token
    configure_token "$username"

    # 测试配置
    test_configuration

    # 显示配置信息
    show_config_info
}

# 运行主函数
main "$@"
