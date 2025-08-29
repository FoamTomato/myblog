#!/bin/bash

# GitHub Pages 修复脚本
# 修复deploy配置和重新部署

set -e

echo "🔧 GitHub Pages 修复工具"
echo "================================"

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

# 修复deploy配置
fix_deploy_config() {
    log_info "修复 _config.yml 中的 deploy 配置..."

    # 备份原配置文件
    cp _config.yml _config.yml.backup.$(date +%Y%m%d_%H%M%S)

    # 修复deploy配置
    if grep -q "repo: https://github.com/FoamTomato/FoamTomato.github.io" _config.yml; then
        sed -i.bak 's|repo: https://github.com/FoamTomato/FoamTomato.github.io|repo: https://github.com/FoamTomato/myblog|' _config.yml
        log_success "✓ 已修复 deploy repo 配置"
    else
        log_info "deploy repo 配置已经是正确的"
    fi

    # 确保分支配置正确
    if grep -q "branch: master" _config.yml; then
        sed -i.bak 's/branch: master/branch: gh-pages/' _config.yml
        log_success "✓ 已修复 deploy branch 配置 (master -> gh-pages)"
    else
        log_info "deploy branch 配置已经是正确的"
    fi
}

# 清理和重新生成
regenerate_site() {
    log_info "清理并重新生成站点..."

    # 清理缓存
    hexo clean
    log_success "✓ 已清理 Hexo 缓存"

    # 重新生成静态文件
    hexo generate
    log_success "✓ 已重新生成静态文件"

    # 检查生成的文件
    if [ -d "public" ] && [ -f "public/index.html" ]; then
        file_count=$(find public -name "*.html" | wc -l)
        log_success "✓ 生成了 $file_count 个HTML文件"
    else
        log_error "✗ 静态文件生成失败"
        exit 1
    fi
}

# 部署到GitHub Pages
deploy_to_github() {
    log_info "部署到 GitHub Pages..."

    # 部署
    hexo deploy
    log_success "✓ 已部署到 GitHub Pages"
}

# 验证部署结果
verify_deployment() {
    log_info "验证部署结果..."

    # 等待GitHub Pages更新（通常需要几分钟）
    echo "等待 GitHub Pages 构建完成..."
    echo "您可以："
    echo "1. 访问 https://foamtomato.github.io 查看是否正常"
    echo "2. 进入 GitHub 仓库的 Actions 标签页查看构建状态"
    echo "3. 如果仍有问题，可以尝试手动重新部署"
}

# 备用方案：创建GitHub Actions workflow
create_github_actions() {
    log_info "创建 GitHub Actions 自动部署工作流..."

    mkdir -p .github/workflows

    cat > .github/workflows/hexo-deploy.yml << 'EOF'
name: Deploy Hexo to GitHub Pages

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v4
      with:
        token: ${{ secrets.GITHUB_TOKEN }}
        submodules: true

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'

    - name: Install Dependencies
      run: |
        npm install

    - name: Clean and Generate
      run: |
        npx hexo clean
        npx hexo generate

    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      if: github.ref == 'refs/heads/main'
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./public
        publish_branch: gh-pages
        cname: foamtomato.github.io
EOF

    log_success "✓ 已创建 GitHub Actions 工作流"
}

# 主函数
main() {
    cd "$BLOG_DIR"

    echo "开始修复 GitHub Pages..."
    echo ""

    # 执行修复步骤
    fix_deploy_config
    echo ""

    regenerate_site
    echo ""

    deploy_to_github
    echo ""

    create_github_actions
    echo ""

    verify_deployment
    echo ""

    log_success "GitHub Pages 修复完成！"
    echo ""
    echo "📋 后续步骤："
    echo "1. 等待 2-3 分钟让 GitHub Pages 完成构建"
    echo "2. 访问 https://foamtomato.github.io 验证修复结果"
    echo "3. 如果仍有问题，检查 GitHub Actions 的构建日志"
}

# 执行主函数
main "$@"
