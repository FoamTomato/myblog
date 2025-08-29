#!/bin/bash

# GitHub Pages 故障诊断脚本
# 用于快速诊断和解决GitHub Pages相关问题

set -e

echo "🔍 GitHub Pages 故障诊断工具"
echo "======================================"

BLOG_DIR="/Users/foam/个人项目/blog/myblog"
GITHUB_REPO="https://github.com/FoamTomato/myblog"

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

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 检查GitHub Pages设置
check_github_pages_settings() {
    log_info "检查GitHub Pages设置..."

    # 检查是否有gh-pages分支
    if git ls-remote --heads origin | grep -q gh-pages; then
        log_success "✓ 存在 gh-pages 分支"
    else
        log_warn "! 不存在 gh-pages 分支，建议使用main分支部署"
    fi

    # 检查分支名称
    current_branch=$(git branch --show-current)
    log_info "当前分支: $current_branch"

    if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
        log_success "✓ 分支名称正确"
    else
        log_warn "! 当前不在主分支上"
    fi
}

# 检查配置文件
check_config_files() {
    log_info "检查配置文件..."

    # 检查Hexo配置文件
    if [ -f "_config.yml" ]; then
        log_success "✓ 存在 _config.yml"

        # 检查GitHub Pages相关配置
        if grep -q "deploy:" _config.yml; then
            log_success "✓ 部署配置存在"
        else
            log_warn "! 缺少部署配置"
        fi

        # 检查仓库URL
        if grep -q "repo:" _config.yml; then
            log_success "✓ 仓库URL已配置"
        else
            log_warn "! 缺少仓库URL配置"
        fi
    else
        log_error "✗ 缺少 _config.yml 文件"
    fi
}

# 检查构建状态
check_build_status() {
    log_info "检查构建状态..."

    # 检查public目录
    if [ -d "public" ]; then
        file_count=$(find public -name "*.html" | wc -l)
        log_success "✓ public目录存在，包含 $file_count 个HTML文件"
    else
        log_warn "! public目录不存在，需要重新生成"
    fi

    # 检查node_modules
    if [ -d "node_modules" ]; then
        log_success "✓ node_modules 存在"
    else
        log_error "✗ node_modules 不存在，需要运行 npm install"
    fi
}

# 检查依赖和版本
check_dependencies() {
    log_info "检查依赖和版本..."

    # 检查Node.js版本
    if command -v node &> /dev/null; then
        node_version=$(node -v)
        log_info "Node.js版本: $node_version"
    else
        log_error "✗ Node.js 未安装"
    fi

    # 检查npm版本
    if command -v npm &> /dev/null; then
        npm_version=$(npm -v)
        log_info "npm版本: $npm_version"
    else
        log_error "✗ npm 未安装"
    fi

    # 检查Hexo版本
    if command -v hexo &> /dev/null; then
        hexo_version=$(hexo version | grep "hexo:" | cut -d' ' -f2)
        log_success "Hexo版本: $hexo_version"
    else
        log_error "✗ Hexo 未安装"
    fi
}

# 检查最近的提交
check_recent_commits() {
    log_info "检查最近的提交..."

    # 显示最近5次提交
    echo "最近5次提交:"
    git log --oneline -5

    # 检查是否有未推送的提交
    ahead_count=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "0")
    if [ "$ahead_count" -gt 0 ]; then
        log_warn "! 有 $ahead_count 个提交未推送到远程"
    else
        log_success "✓ 本地和远程同步"
    fi
}

# 网络连接测试
test_network() {
    log_info "测试网络连接..."

    # 测试GitHub连接
    if ping -c 1 github.com &> /dev/null; then
        log_success "✓ GitHub网络连接正常"
    else
        log_error "✗ GitHub网络连接失败"
    fi

    # 测试代理设置（如果有）
    if [ -n "$http_proxy" ] || [ -n "$https_proxy" ]; then
        log_info "检测到代理设置: $http_proxy"
    fi
}

# 生成修复建议
generate_fix_suggestions() {
    echo ""
    echo "🔧 修复建议:"
    echo "======================================"

    # 检查是否需要重新生成
    if [ ! -d "public" ] || [ ! -f "public/index.html" ]; then
        echo "1. 重新生成静态文件:"
        echo "   hexo clean && hexo generate"
    fi

    # 检查是否需要推送
    ahead_count=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "0")
    if [ "$ahead_count" -gt 0 ]; then
        echo "2. 推送最新提交:"
        echo "   git push origin main"
    fi

    # 检查依赖
    if [ ! -d "node_modules" ]; then
        echo "3. 安装依赖:"
        echo "   npm install"
    fi

    echo "4. 手动触发GitHub Pages部署:"
    echo "   - 进入GitHub仓库 Settings > Pages"
    echo "   - 确认Source设置为 'Deploy from a branch'"
    echo "   - 确认Branch设置为 'main' 或 'gh-pages'"
    echo "   - 如果没有生效，可以尝试切换分支或重新保存"

    echo "5. 检查构建日志:"
    echo "   - 进入GitHub仓库 Actions 标签页"
    echo "   - 查看最新的workflow运行状态"
    echo "   - 如果有错误，点击查看详细日志"
}

# 执行所有检查
main() {
    cd "$BLOG_DIR"

    echo "开始诊断..."
    echo ""

    check_github_pages_settings
    echo ""

    check_config_files
    echo ""

    check_build_status
    echo ""

    check_dependencies
    echo ""

    check_recent_commits
    echo ""

    test_network
    echo ""

    generate_fix_suggestions

    echo ""
    log_info "诊断完成！请根据上述建议执行修复操作。"
}

# 执行主函数
main "$@"
