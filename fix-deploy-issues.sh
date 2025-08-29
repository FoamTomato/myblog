#!/bin/bash

# 部署问题快速修复脚本
# 自动检测和修复Hexo部署相关问题

set -e

echo "🔧 Hexo部署问题修复脚本"
echo "========================="

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

# 检测问题
detect_issues() {
    log_info "🔍 检测部署问题..."

    local issues_found=0

    # 检查配置文件
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "❌ 缺少配置文件: _config.yml"
        ((issues_found++))
    else
        log_success "✅ 配置文件存在"
    fi

    # 检查deploy配置
    if ! grep -q "^deploy:" "$CONFIG_FILE"; then
        log_error "❌ 配置文件中缺少deploy配置"
        ((issues_found++))
    else
        log_success "✅ 部署配置存在"
    fi

    # 检查Git仓库
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "❌ 当前目录不是Git仓库"
        ((issues_found++))
    else
        log_success "✅ Git仓库配置正确"
    fi

    # 检查远程仓库
    if ! git remote get-url origin &> /dev/null; then
        log_error "❌ 未配置Git远程仓库"
        ((issues_found++))
    else
        log_success "✅ 远程仓库配置正确"
    fi

    # 检查gh-pages分支
    if ! git ls-remote --heads origin gh-pages &> /dev/null; then
        log_warning "⚠️ gh-pages分支可能不存在"
    else
        log_success "✅ gh-pages分支存在"
    fi

    # 检查public目录
    if [[ ! -d "public" ]]; then
        log_warning "⚠️ public目录不存在，需要先生成静态文件"
    else
        log_success "✅ public目录存在"
    fi

    return $issues_found
}

# 修复配置问题
fix_config_issues() {
    log_info "🔧 修复配置问题..."

    # 确保deploy配置正确
    if ! grep -q "type: git" "$CONFIG_FILE"; then
        log_warning "⚠️ 修复deploy配置..."

        # 备份原配置
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

        # 添加deploy配置
        cat >> "$CONFIG_FILE" << 'EOF'

# Deployment
## Docs: https://hexo.io/docs/one-command-deployment
deploy:
  type: git
  repo: https://github.com/FoamTomato/myblog.git
  branch: gh-pages
  message: "Site updated: {{ now('YYYY-MM-DD HH:mm:ss') }}"
EOF

        log_success "✅ deploy配置已修复"
    fi
}

# 修复Git问题
fix_git_issues() {
    log_info "🔧 修复Git问题..."

    # 确保在正确的分支
    local current_branch=$(git branch --show-current)
    if [[ "$current_branch" != "main" && "$current_branch" != "master" ]]; then
        log_warning "⚠️ 当前分支是 $current_branch，建议在main/master分支上操作"
    fi

    # 检查是否有未提交的更改
    if [[ -n "$(git status --porcelain)" ]]; then
        log_info "📝 发现未提交的更改，正在自动提交..."

        git add .
        git commit -m "Auto commit: $(date +'%Y-%m-%d %H:%M:%S')" || log_warning "⚠️ 没有新的更改需要提交"
    fi

    # 推送源码
    log_info "📤 推送源码到远程仓库..."
    if git push origin "$current_branch"; then
        log_success "✅ 源码推送成功"
    else
        log_error "❌ 源码推送失败，请检查网络和权限"
        return 1
    fi
}

# 修复SSH/认证问题
fix_auth_issues() {
    log_info "🔧 检查认证配置..."

    # 检查是否可以使用当前凭据
    if git ls-remote --heads origin &> /dev/null; then
        log_success "✅ Git认证正常"
        return 0
    fi

    log_warning "⚠️ Git认证可能有问题"

    # 提供解决方案
    echo ""
    log_info "💡 解决方案:"

    echo "1. 🔑 使用GitHub Personal Access Token:"
    echo "   ./setup-github-token.sh"

    echo ""
    echo "2. 🔐 配置SSH密钥:"
    echo "   ./check-ssh-config.sh"
    echo "   按照提示配置SSH密钥"

    echo ""
    echo "3. 🌐 检查网络和代理:"
    echo "   curl -I https://github.com"

    return 1
}

# 生成静态文件
generate_site() {
    log_info "🏗️ 生成静态文件..."

    if [[ ! -d "public" ]] || [[ -z "$(ls -A public 2>/dev/null)" ]]; then
        log_info "📝 生成静态文件..."
        if hexo generate; then
            log_success "✅ 静态文件生成成功"
        else
            log_error "❌ 静态文件生成失败"
            return 1
        fi
    else
        log_success "✅ 静态文件已存在"
    fi
}

# 测试部署
test_deploy() {
    log_info "🧪 测试部署..."

    if hexo deploy --dry-run; then
        log_success "✅ 部署配置测试通过"
        return 0
    else
        log_error "❌ 部署配置测试失败"
        return 1
    fi
}

# 执行完整修复
full_fix() {
    log_info "🔧 执行完整修复流程..."

    # 1. 检测问题
    if ! detect_issues; then
        log_info "发现问题，开始修复..."
    fi

    # 2. 修复配置问题
    fix_config_issues

    # 3. 检查认证
    if ! fix_auth_issues; then
        log_warning "⚠️ 认证问题需要手动解决"
        return 1
    fi

    # 4. 修复Git问题
    fix_git_issues

    # 5. 生成静态文件
    generate_site

    # 6. 测试部署
    if test_deploy; then
        log_success "🎉 所有问题修复完成！"
        echo ""
        log_info "现在可以运行以下命令:"
        echo "  ./deploy.sh --all          # 一键完整部署"
        echo "  hexo deploy               # 直接部署"
        return 0
    else
        log_error "❌ 修复失败，请检查错误信息"
        return 1
    fi
}

# 显示使用说明
show_help() {
    echo "Hexo部署问题修复脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -d, --detect        仅检测问题"
    echo "  -f, --fix          执行完整修复"
    echo "  -t, --test          测试部署配置"
    echo "  -g, --generate      生成静态文件"
    echo ""
    echo "示例:"
    echo "  $0 --fix           # 自动修复所有问题"
    echo "  $0 --detect        # 仅检测问题"
    echo "  $0 --test          # 测试部署"
}

# 主函数
main() {
    local action=""

    # 解析参数
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--detect)
            action="detect"
            ;;
        -f|--fix)
            action="fix"
            ;;
        -t|--test)
            action="test"
            ;;
        -g|--generate)
            action="generate"
            ;;
        "")
            action="fix"
            ;;
        *)
            log_error "❌ 未知选项: $1"
            show_help
            exit 1
            ;;
    esac

    cd "$BLOG_DIR"

    case "$action" in
        "detect")
            detect_issues
            ;;
        "fix")
            full_fix
            ;;
        "test")
            test_deploy
            ;;
        "generate")
            generate_site
            ;;
    esac
}

# 运行主函数
main "$@"
