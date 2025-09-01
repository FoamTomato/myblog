#!/bin/bash

# Hexo 博客自动部署脚本 (增强版)
# 用于自动构建和部署到 GitHub Pages
# 支持：自动代理检测、自动清理部署、自动Git推送

set -e  # 遇到错误立即退出

# 配置变量
BLOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_BRANCH="master"
DEPLOY_BRANCH="master"
COMMIT_MESSAGE="Site updated: $(date +'%Y-%m-%d %H:%M:%S')"
DEPLOY_DIR="public"

# 部署统计变量
START_TIME=$(date +%s)
GENERATED_FILES=0
DEPLOYED_SIZE=""
BUILD_DURATION=""
DEPLOY_DURATION=""

# 颜色输出
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

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."

    if ! command -v hexo &> /dev/null; then
        log_error "Hexo 未安装，请先安装 Hexo"
        exit 1
    fi

    if ! command -v git &> /dev/null; then
        log_error "Git 未安装，请先安装 Git"
        exit 1
    fi

    if ! command -v node &> /dev/null; then
        log_error "Node.js 未安装，请先安装 Node.js"
        exit 1
    fi

    log_success "依赖检查通过"
}

# 检查Git状态
check_git_status() {
    log_info "检查 Git 状态..."

    if [[ -n $(git status --porcelain) ]]; then
        log_warning "工作目录有未提交的更改"
        read -p "是否要先提交这些更改？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git add .
            read -p "请输入提交信息 (默认: 'Auto commit'): " commit_msg
            commit_msg=${commit_msg:-"Auto commit"}
            git commit -m "$commit_msg"
            log_success "更改已提交"
        fi
    fi

    # 检查远程仓库
    if ! git remote get-url origin &> /dev/null; then
        log_error "未配置远程仓库，请先配置 Git 远程仓库"
        exit 1
    fi

    log_success "Git 状态检查通过"
}

# 安装依赖
install_dependencies() {
    log_info "安装项目依赖..."

    if [[ -f "package.json" ]]; then
        npm install
        log_success "npm 依赖安装完成"
    fi

    if [[ -f "yarn.lock" ]]; then
        yarn install
        log_success "yarn 依赖安装完成"
    fi
}

# 增强版清理缓存和优化
clean_cache() {
    log_info "🧹 深度清理缓存和临时文件..."

    # 记录清理前的大小
    local before_size=""
    if [[ -d "public" ]]; then
        before_size=$(du -sh public 2>/dev/null | cut -f1)
    fi

    # 清理Hexo缓存
    log_info "清理Hexo缓存..."
    hexo clean

    # 清理Node.js缓存
    log_info "清理Node.js缓存..."
    if [[ -d "node_modules/.cache" ]]; then
        rm -rf node_modules/.cache
        log_info "已清理Node.js缓存"
    fi

    # 清理npm缓存（可选）
    if [[ -d "$(npm config get cache)" ]]; then
        log_info "清理npm缓存..."
        npm cache clean --force > /dev/null 2>&1
    fi

    # 清理系统临时文件
    log_info "清理临时文件..."
    if [[ -d "public" ]]; then
        find public -name "*.tmp" -type f -delete 2>/dev/null || true
        find public -name "*.log" -type f -delete 2>/dev/null || true
    fi

    # 清理Git未跟踪的文件（可选）
    if [[ -n "$(git status --porcelain)" ]]; then
        log_info "发现未跟踪的文件，可选择清理..."
        # 这里可以添加交互式清理，但为了自动化，我们跳过
    fi

    # 记录清理后的大小
    local after_size=""
    if [[ -d "public" ]]; then
        after_size=$(du -sh public 2>/dev/null | cut -f1)
    fi

    if [[ -n "$before_size" && -n "$after_size" ]]; then
        log_success "✅ 缓存清理完成 (清理前: $before_size, 清理后: $after_size)"
    else
        log_success "✅ 缓存清理完成"
    fi
}

# 增强版生成静态文件
generate_site() {
    local build_start=$(date +%s)

    log_info "🏗️  开始生成静态文件..."

    # 检查必要文件
    if [[ ! -f "_config.yml" ]]; then
        log_error "❌ 未找到 _config.yml 配置文件"
        exit 1
    fi

    # 检查主题
    if [[ ! -d "themes" ]]; then
        log_error "❌ 未找到 themes 目录，请先安装主题"
        exit 1
    fi

    # 预检查文章数量
    local post_count=$(find source/_posts -name "*.md" 2>/dev/null | wc -l)
    log_info "📝 发现 $post_count 篇文章"

    if [[ $post_count -eq 0 ]]; then
        log_warning "⚠️  未发现任何文章文件，生成的内容可能为空"
    fi

    # 检查资源文件
    local img_count=$(find source -name "img" -type d 2>/dev/null | wc -l)
    if [[ $img_count -gt 0 ]]; then
        local total_img_files=$(find source/img -type f 2>/dev/null | wc -l)
        log_info "🖼️  发现 $total_img_files 个图片资源文件"
    fi

    # 执行生成
    log_info "🔨 执行 Hexo 生成..."
    if hexo generate; then
        log_success "✅ 静态文件生成成功"
    else
        log_error "❌ 静态文件生成失败"
        exit 1
    fi

    # 统计生成结果
    if [[ -d "public" ]]; then
        GENERATED_FILES=$(find public -type f | wc -l)
        DEPLOYED_SIZE=$(du -sh public | cut -f1)

        # 分析生成的文件类型
        local html_files=$(find public -name "*.html" -type f | wc -l)
        local css_files=$(find public -name "*.css" -type f | wc -l)
        local js_files=$(find public -name "*.js" -type f | wc -l)
        local img_files=$(find public -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" -o -name "*.webp" -o -name "*.svg" \) | wc -l)

        log_success "📊 生成统计:"
        log_success "   总文件数: $GENERATED_FILES"
        log_success "   总大小: $DEPLOYED_SIZE"
        log_success "   HTML文件: $html_files"
        log_success "   CSS文件: $css_files"
        log_success "   JS文件: $js_files"
        log_success "   图片文件: $img_files"

        # 计算构建时间
        local build_end=$(date +%s)
        BUILD_DURATION=$((build_end - build_start))
        log_success "⏱️  构建耗时: ${BUILD_DURATION}秒"

        # 验证关键文件
        local critical_files=("$DEPLOY_DIR/index.html" "$DEPLOY_DIR/archives/index.html" "$DEPLOY_DIR/tags/index.html")
        local missing_files=()

        for file in "${critical_files[@]}"; do
            if [[ ! -f "$file" ]]; then
                missing_files+=("$file")
            fi
        done

        if [[ ${#missing_files[@]} -gt 0 ]]; then
            log_warning "⚠️  缺少关键文件: ${missing_files[*]}"
        else
            log_success "✅ 关键文件验证通过"
        fi

    else
        log_error "❌ 生成失败，未找到 public 目录"
        exit 1
    fi
}

# 增强版部署到GitHub Pages
deploy_to_github() {
    local deploy_start=$(date +%s)

    log_info "🚀 开始部署到 GitHub Pages..."

    # 检查是否存在部署配置
    if [[ ! -f "_config.yml" ]]; then
        log_error "❌ 未找到 _config.yml 配置文件"
        exit 1
    fi

    # 检查Git配置
    if ! git remote get-url origin &> /dev/null; then
        log_error "❌ 未配置Git远程仓库，请先运行: git remote add origin <repository-url>"
        exit 1
    fi

    # 检查部署目录
    if [[ ! -d "$DEPLOY_DIR" ]]; then
        log_error "❌ 未找到 $DEPLOY_DIR 目录，请先运行生成命令"
        exit 1
    fi

    # 读取GitHub仓库信息
    local repo_url=$(git remote get-url origin)
    log_info "📦 部署目标: $repo_url"

    # 检查是否有未提交的更改
    if [[ -n "$(git status --porcelain)" ]]; then
        log_warning "⚠️  检测到未提交的更改，建议先提交或推送源码"
        read -p "是否继续部署？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "部署已取消"
            return 1
        fi
    fi

    # 执行Hexo部署
    log_info "📤 执行 Hexo 部署..."
    if hexo deploy; then
        log_success "✅ 部署到 GitHub Pages 成功"
    else
        log_error "❌ 部署到 GitHub Pages 失败"
        log_info "💡 可能的解决方案:"
        log_info "   1. 检查 _config.yml 中的 deploy 配置"
        log_info "   2. 确认 GitHub Token 或 SSH 密钥正确"
        log_info "   3. 检查网络连接和代理设置"
        exit 1
    fi

    # 计算部署时间
    local deploy_end=$(date +%s)
    DEPLOY_DURATION=$((deploy_end - deploy_start))

    # 部署后验证
    log_info "🔍 部署后验证..."
    local repo_name=$(basename "$repo_url" .git)
    local username=$(echo "$repo_url" | sed -E 's|https://github.com/([^/]+)/.*|\1|')

    if [[ "$repo_url" == https://github.com/* ]]; then
        local site_url="https://${username}.github.io/${repo_name}"

        # 尝试访问网站
        log_info "🌐 验证网站可访问性: $site_url"
        if curl -s --max-time 10 --head "$site_url" | grep -q "200 OK"; then
            log_success "✅ 网站访问正常: $site_url"
        else
            log_warning "⚠️  网站可能还在更新中，请稍后访问"
            log_info "💡 GitHub Pages 更新通常需要 1-5 分钟"
        fi
    fi

    log_success "⏱️  部署耗时: ${DEPLOY_DURATION}秒"
}

# 手动部署方式（备用）
manual_deploy() {
    log_info "使用手动部署方式..."

    # 检查部署目录是否存在
    if [[ ! -d "$DEPLOY_DIR" ]]; then
        log_error "部署目录 $DEPLOY_DIR 不存在，请先运行生成命令"
        exit 1
    fi

    # 创建临时目录
    temp_dir=$(mktemp -d)
    log_info "创建临时目录: $temp_dir"

    # 克隆部署分支到临时目录
    if git ls-remote --heads origin $DEPLOY_BRANCH | grep -q $DEPLOY_BRANCH; then
        git clone --branch $DEPLOY_BRANCH --single-branch $(git remote get-url origin) $temp_dir
    else
        log_warning "部署分支 $DEPLOY_BRANCH 不存在，将创建新分支"
        git clone $(git remote get-url origin) $temp_dir
        cd $temp_dir
        git checkout --orphan $DEPLOY_BRANCH
        git rm -rf .
        cd $BLOG_DIR
    fi

    # 复制静态文件到临时目录
    cp -r $DEPLOY_DIR/* $temp_dir/

    # 提交和推送
    cd $temp_dir
    git add .
    git commit -m "$COMMIT_MESSAGE"
    git push origin $DEPLOY_BRANCH

    # 清理临时目录
    cd $BLOG_DIR
    rm -rf $temp_dir

    log_success "手动部署完成"
}

# 增强版推送源码
push_source() {
    log_info "📤 智能源码推送..."

    # 检查Git状态
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "❌ 当前目录不是Git仓库"
        return 1
    fi

    # 检查远程仓库
    if ! git remote get-url origin &> /dev/null; then
        log_error "❌ 未配置远程仓库，请先运行: git remote add origin <repository-url>"
        return 1
    fi

    # 检查当前分支
    local current_branch=$(git branch --show-current)
    if [[ "$current_branch" != "$SOURCE_BRANCH" ]]; then
        log_warning "⚠️  当前分支是 $current_branch，不是目标分支 $SOURCE_BRANCH"
        read -p "是否切换到 $SOURCE_BRANCH 分支？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if git checkout $SOURCE_BRANCH 2>/dev/null; then
                log_success "✅ 已切换到 $SOURCE_BRANCH 分支"
            else
                log_error "❌ 切换分支失败"
                return 1
            fi
        else
            log_info "ℹ️  继续在当前分支 $current_branch 上操作"
        fi
    fi

    # 检查工作目录状态
    local status=$(git status --porcelain)
    if [[ -z "$status" ]]; then
        log_info "ℹ️  工作目录是干净的，没有需要提交的更改"

        # 检查是否需要推送
        local local_commit=$(git rev-parse HEAD)
        local remote_commit=$(git rev-parse origin/$SOURCE_BRANCH 2>/dev/null || echo "")

        if [[ "$local_commit" == "$remote_commit" ]]; then
            log_success "✅ 本地和远程分支都是最新的，无需推送"
            return 0
        else
            log_info "📤 推送现有提交到远程..."
        fi
    else
        # 有未提交的更改
        log_info "📝 发现未提交的更改:"

        # 分析更改类型
        local added_files=$(echo "$status" | grep "^A" | wc -l)
        local modified_files=$(echo "$status" | grep "^M" | wc -l)
        local deleted_files=$(echo "$status" | grep "^D" | wc -l)
        local untracked_files=$(echo "$status" | grep "^??" | wc -l)

        if [[ $added_files -gt 0 ]]; then
            log_info "   新增文件: $added_files"
        fi
        if [[ $modified_files -gt 0 ]]; then
            log_info "   修改文件: $modified_files"
        fi
        if [[ $deleted_files -gt 0 ]]; then
            log_info "   删除文件: $deleted_files"
        fi
        if [[ $untracked_files -gt 0 ]]; then
            log_info "   未跟踪文件: $untracked_files"
        fi

        # 智能生成提交信息
        local smart_commit_msg="$COMMIT_MESSAGE"
        if [[ $added_files -gt 0 && $modified_files -eq 0 && $deleted_files -eq 0 ]]; then
            smart_commit_msg="feat: 添加新文件 - $(date +'%Y-%m-%d %H:%M:%S')"
        elif [[ $modified_files -gt 0 && $added_files -eq 0 && $deleted_files -eq 0 ]]; then
            smart_commit_msg="fix: 更新文件 - $(date +'%Y-%m-%d %H:%M:%S')"
        elif [[ $deleted_files -gt 0 ]]; then
            smart_commit_msg="refactor: 清理文件 - $(date +'%Y-%m-%d %H:%M:%S')"
        fi

        # 添加文件到暂存区
        log_info "📦 添加文件到暂存区..."
        git add .

        # 提交更改
        log_info "💾 提交更改..."
        if git commit -m "$smart_commit_msg"; then
            log_success "✅ 更改已提交: $smart_commit_msg"
        else
            log_error "❌ 提交失败"
            return 1
        fi
    fi

    # 推送代码
    log_info "🚀 推送代码到远程仓库..."
    if git push origin $SOURCE_BRANCH; then
        log_success "✅ 源码推送成功"

        # 显示推送统计
        local remote_url=$(git remote get-url origin)
        local commit_count=$(git rev-list --count HEAD ^origin/$SOURCE_BRANCH 2>/dev/null || echo "N/A")

        if [[ "$commit_count" != "N/A" && "$commit_count" -gt 0 ]]; then
            log_success "📊 推送统计: $commit_count 个新提交"
        fi

        log_success "🔗 远程仓库: $remote_url"

    else
        log_error "❌ 推送失败"
        log_info "💡 可能的解决方案:"
        log_info "   1. 检查网络连接和代理设置"
        log_info "   2. 确认有推送权限"
        log_info "   3. 尝试手动推送: git push origin $SOURCE_BRANCH"
        return 1
    fi
}

# 部署前验证
pre_deploy_validation() {
    log_info "🔍 部署前验证..."

    local validation_passed=true

    # 1. 检查配置文件
    log_info "📄 检查配置文件..."
    if [[ ! -f "_config.yml" ]]; then
        log_error "❌ 缺少 _config.yml 配置文件"
        validation_passed=false
    else
        log_success "✅ _config.yml 存在"

        # 检查deploy配置
        if ! grep -q "^deploy:" _config.yml; then
            log_warning "⚠️  _config.yml 中缺少 deploy 配置"
        else
            log_success "✅ 部署配置存在"
        fi
    fi

    # 2. 检查主题
    if [[ ! -d "themes" ]]; then
        log_error "❌ 缺少 themes 目录"
        validation_passed=false
    else
        local theme_count=$(find themes -maxdepth 1 -type d | wc -l)
        theme_count=$((theme_count - 1))  # 减去 themes 目录本身
        if [[ $theme_count -eq 0 ]]; then
            log_warning "⚠️  未安装任何主题"
        else
            log_success "✅ 发现 $theme_count 个主题"
        fi
    fi

    # 3. 检查文章
    local post_count=$(find source/_posts -name "*.md" 2>/dev/null | wc -l)
    if [[ $post_count -eq 0 ]]; then
        log_warning "⚠️  未发现任何文章文件"
    else
        log_success "✅ 发现 $post_count 篇文章"
    fi

    # 4. 检查Git仓库状态
    if git rev-parse --git-dir > /dev/null 2>&1; then
        if git remote get-url origin &> /dev/null; then
            log_success "✅ Git仓库配置正确"
        else
            log_error "❌ 未配置Git远程仓库"
            validation_passed=false
        fi
    else
        log_error "❌ 当前目录不是Git仓库"
        validation_passed=false
    fi

    # 5. 检查依赖
    log_info "🔧 检查依赖..."
    local deps=("hexo" "git" "node")
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            log_success "✅ $dep 已安装"
        else
            log_error "❌ $dep 未安装"
            validation_passed=false
        fi
    done

    # 6. 检查网络连接
    log_info "🌐 检查网络连接..."
    if curl -s --max-time 5 https://github.com > /dev/null; then
        log_success "✅ 网络连接正常"
    else
        log_warning "⚠️  网络连接可能有问题"
    fi

    # 7. 检查磁盘空间
    log_info "💾 检查磁盘空间..."
    local available_space=$(df . | tail -1 | awk '{print $4}')
    local available_gb=$((available_space / 1024 / 1024))

    if [[ $available_gb -lt 1 ]]; then
        log_warning "⚠️  磁盘可用空间不足: ${available_gb}GB"
    else
        log_success "✅ 磁盘可用空间: ${available_gb}GB"
    fi

    # 返回验证结果
    if [[ "$validation_passed" == "true" ]]; then
        log_success "🎉 部署前验证全部通过！"
        return 0
    else
        log_error "❌ 部署前验证失败，请修复上述问题"
        return 1
    fi
}

# 部署后验证
post_deploy_validation() {
    log_info "🔍 部署后验证..."

    # 检查部署目录
    if [[ -d "$DEPLOY_DIR" ]]; then
        log_success "✅ 部署目录存在: $DEPLOY_DIR"

        # 统计部署文件
        local deployed_files=$(find "$DEPLOY_DIR" -type f | wc -l)
        local deployed_size=$(du -sh "$DEPLOY_DIR" | cut -f1)

        log_success "📊 部署统计:"
        log_success "   文件数量: $deployed_files"
        log_success "   部署大小: $deployed_size"

        # 验证关键文件
        local critical_files=("index.html" "archives/index.html" "tags/index.html")
        local missing_critical=()

        for file in "${critical_files[@]}"; do
            if [[ ! -f "$DEPLOY_DIR/$file" ]]; then
                missing_critical+=("$file")
            fi
        done

        if [[ ${#missing_critical[@]} -gt 0 ]]; then
            log_warning "⚠️  缺少关键文件: ${missing_critical[*]}"
        else
            log_success "✅ 关键文件验证通过"
        fi

    else
        log_error "❌ 部署目录不存在: $DEPLOY_DIR"
        return 1
    fi

    log_success "🎉 部署后验证完成！"
}

# 显示帮助信息
show_help() {
    echo "🚀 Hexo 博客自动部署脚本 (增强版)"
    echo ""
    echo "✨ 主要特性:"
    echo "  🔍 智能代理自动检测和配置"
    echo "  🧹 深度清理缓存和临时文件"
    echo "  📊 详细的部署统计和日志"
    echo "  ✅ 完整的验证和错误处理"
    echo "  🎯 一键完整部署流程"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -c, --clean         深度清理缓存和临时文件"
    echo "  -g, --generate      生成静态文件（带统计）"
    echo "  -d, --deploy        部署到 GitHub Pages（带验证）"
    echo "  -p, --push          智能推送源码（自动提交）"
    echo "  -a, --all          执行完整流程（推荐）"
    echo "  --manual           使用手动部署方式"
    echo "  --preview          启动本地预览服务器"
    echo "  --offline          离线测试（网络不可用时使用）"
    echo "  --validate         仅执行部署前验证"
    echo ""
    echo "完整流程说明 (--all):"
    echo "  1. 🔍 部署前验证（配置、依赖、网络等）"
    echo "  2. 🌐 自动检测和配置代理"
    echo "  3. 🧹 深度清理缓存和临时文件"
    echo "  4. 📝 检查Git状态和未提交更改"
    echo "  5. 🏗️ 生成静态文件（带详细统计）"
    echo "  6. 🚀 部署到GitHub Pages（带验证）"
    echo "  7. 📤 智能推送源码（自动生成提交信息）"
    echo "  8. 📊 显示详细部署统计和日志"
    echo ""
    echo "示例:"
    echo "  $0 --all                    # 🔥 一键完整部署（推荐）"
    echo "  $0 --validate               # 仅验证环境"
    echo "  $0 -c -g -d                 # 手动选择步骤"
    echo "  $0 --preview                # 本地预览测试"
    echo "  $0 --offline                # 离线环境测试"
    echo ""
    echo "💡 提示:"
    echo "  • 首次使用建议运行: $0 --all"
    echo "  • 如遇到代理问题，脚本会自动检测和配置"
    echo "  • 部署日志会自动保存到当前目录"
    echo "  • 详细的错误信息和解决建议会显示在控制台"
}

# 主函数
main() {
    local clean=false
    local generate=false
    local deploy=false
    local push=false
    local manual=false
    local all=false
    local validate_only=false

    # 自动检测代理设置
    auto_detect_proxy

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                clean=true
                shift
                ;;
            -g|--generate)
                generate=true
                shift
                ;;
            -d|--deploy)
                deploy=true
                shift
                ;;
            -p|--push)
                push=true
                shift
                ;;
            -a|--all)
                all=true
                shift
                ;;
            --manual)
                manual=true
                shift
                ;;
            --preview)
                preview_site
                exit 0
                ;;
            --offline)
                offline_test
                exit 0
                ;;
            --validate)
                validate_only=true
                shift
                ;;
            *)
                log_error "❌ 未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 检查工作目录
    if [[ ! -f "_config.yml" ]]; then
        log_error "❌ 请在 Hexo 博客根目录下运行此脚本"
        exit 1
    fi

    log_info "🚀 开始 Hexo 博客部署流程..."
    log_info "📁 工作目录: $BLOG_DIR"
    log_info "⏰ 开始时间: $(date +'%Y-%m-%d %H:%M:%S')"

    # 如果只是验证，则只执行验证
    if [[ "$validate_only" == "true" ]]; then
        pre_deploy_validation
        exit $?
    fi

    # 部署前验证
    if ! pre_deploy_validation; then
        log_error "❌ 部署前验证失败，退出部署流程"
        exit 1
    fi

    # 检查依赖
    check_dependencies

    # 检查Git状态
    check_git_status

    # 完整流程
    if [[ "$all" == "true" ]]; then
        clean=true
        generate=true
        deploy=true
        push=true
    fi

    # 执行各项任务
    # 重要：生成和部署前必须清理缓存
    if [[ "$generate" == "true" || "$deploy" == "true" || "$all" == "true" ]]; then
        if [[ "$clean" == "false" ]]; then
            log_warning "检测到生成/部署操作，将自动清理缓存以确保最新内容"
            clean_cache
        fi
    fi

    if [[ "$clean" == "true" ]]; then
        clean_cache
    fi

    if [[ "$generate" == "true" ]]; then
        generate_site
    fi

    if [[ "$deploy" == "true" ]]; then
        if [[ "$manual" == "true" ]]; then
            manual_deploy
        else
            deploy_to_github
        fi
    fi

    if [[ "$push" == "true" ]]; then
        push_source
    fi

    # 如果没有指定任何操作，显示帮助
    if [[ "$clean" == "false" && "$generate" == "false" && "$deploy" == "false" && "$push" == "false" && "$all" == "false" ]]; then
        log_warning "⚠️  未指定操作，使用 --all 执行完整流程"
        all=true
        clean=true
        generate=true
        deploy=true
        push=true
    fi

    # 部署后验证
    if [[ "$generate" == "true" || "$deploy" == "true" || "$all" == "true" ]]; then
        post_deploy_validation
    fi

    # 显示部署统计
    show_deploy_stats

    log_success "🎉 部署流程完成！"
    log_info "🌐 访问你的博客: https://你的用户名.github.io"
}
# 本地预览站点
preview_site() {
    log_info "启动本地预览服务器..."

    # 检查是否已生成静态文件
    if [[ ! -d "public" ]]; then
        log_info "生成静态文件..."
        hexo generate --silent
    fi

    # 启动服务器
    log_success "本地预览服务器已启动"
    log_info "访问地址: http://localhost:4000"
    log_info "按 Ctrl+C 停止服务器"

    hexo server --open
}

# 离线测试
offline_test() {
    log_info "开始离线测试..."

    # 检查必要文件
    log_info "检查配置文件..."
    if [[ ! -f "_config.yml" ]]; then
        log_error "缺少 _config.yml 文件"
        exit 1
    fi
    log_success "配置文件存在"

    # 检查主题
    if [[ ! -d "themes" ]]; then
        log_error "缺少 themes 目录"
        exit 1
    fi
    log_success "主题文件存在"

    # 检查文章
    local post_count=$(find source/_posts -name "*.md" 2>/dev/null | wc -l)
    if [[ $post_count -eq 0 ]]; then
        log_warning "没有找到任何文章文件"
    else
        log_success "找到 $post_count 篇文章"
    fi

    # 生成测试
    log_info "执行生成测试..."
    if hexo generate --silent; then
        log_success "静态文件生成成功"

        # 检查生成的文件
        if [[ -d "public" ]]; then
            local file_count=$(find public -type f | wc -l)
            local size=$(du -sh public | cut -f1)
            log_success "生成 $file_count 个文件，总大小: $size"
        fi
    else
        log_error "静态文件生成失败"
        exit 1
    fi

    # 验证重要页面
    log_info "验证重要页面..."
    local important_pages=("index.html" "archives/index.html" "tags/index.html" "categories/index.html")

    for page in "${important_pages[@]}"; do
        if [[ -f "public/$page" ]]; then
            log_success "✓ $page"
        else
            log_warning "✗ 缺少 $page"
        fi
    done

    log_success "离线测试完成！"
    log_info "你可以使用 ./deploy.sh --preview 来启动本地预览"
}

# 增强版自动检测和设置代理
auto_detect_proxy() {
    log_info "🔍 智能代理检测与配置..."

    # 1. 检查现有的环境变量代理
    if [[ -n "$http_proxy" || -n "$https_proxy" ]]; then
        log_success "✅ 检测到环境变量代理设置: HTTP_PROXY=$http_proxy, HTTPS_PROXY=$https_proxy"
        return 0
    fi

    # 2. 检查Git全局代理配置
    if git config --global --get http.proxy &>/dev/null; then
        local git_http_proxy=$(git config --global --get http.proxy)
        local git_https_proxy=$(git config --global --get https.proxy)
        log_success "✅ 检测到Git代理配置: $git_http_proxy, $git_https_proxy"
        export http_proxy="$git_http_proxy"
        export https_proxy="$git_https_proxy"
        return 0
    fi

    # 3. 检查系统级代理设置 (macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # 检查网络偏好设置中的代理
        if command -v networksetup &> /dev/null; then
            log_info "🍎 检查macOS系统代理设置..."
            # 获取当前网络服务
            local network_service=$(networksetup -listallnetworkservices | grep -E "(Wi-Fi|Ethernet)" | head -1)
            if [[ -n "$network_service" ]]; then
                # 检查HTTP代理
                if networksetup -getwebproxy "$network_service" | grep -q "Enabled: Yes"; then
                    local sys_http_proxy=$(networksetup -getwebproxy "$network_service" | grep "Server:" | cut -d: -f2 | tr -d ' ')
                    local sys_http_port=$(networksetup -getwebproxy "$network_service" | grep "Port:" | cut -d: -f2 | tr -d ' ')
                    if [[ -n "$sys_http_proxy" && -n "$sys_http_port" ]]; then
                        local proxy_url="http://$sys_http_proxy:$sys_http_port"
                        log_success "✅ 检测到macOS系统HTTP代理: $proxy_url"
                        export http_proxy="$proxy_url"
                        export https_proxy="$proxy_url"
                        git config --global http.proxy "$proxy_url"
                        git config --global https.proxy "$proxy_url"
                        return 0
                    fi
                fi
            fi
        fi
    fi

    # 4. 检查代理配置文件
    if [[ -f ".proxy-config" ]]; then
        log_info "📄 发现代理配置文件，正在加载..."
        if source ".proxy-config" 2>/dev/null; then
            if [[ -n "$HTTP_PROXY" ]]; then
                export http_proxy="$HTTP_PROXY"
                export https_proxy="${HTTPS_PROXY:-$HTTP_PROXY}"
                export all_proxy="${ALL_PROXY:-$HTTP_PROXY}"

                # 设置Git代理
                git config --global http.proxy "$HTTP_PROXY"
                if [[ -n "$HTTPS_PROXY" ]]; then
                    git config --global https.proxy "$HTTPS_PROXY"
                fi

                log_success "✅ 代理配置已从文件加载"
                return 0
            fi
        else
            log_warning "⚠️ 代理配置文件加载失败"
        fi
    fi

    # 5. 智能扫描常用代理端口
    log_info "🔎 扫描常用代理端口..."

    local common_ports=("7890" "7897" "1080" "1087" "8888" "8080")
    local common_protocols=("http" "socks5")

    for port in "${common_ports[@]}"; do
        for protocol in "${common_protocols[@]}"; do
            local proxy_addr="127.0.0.1:$port"
            local proxy_url="$protocol://$proxy_addr"

            log_info "测试代理: $proxy_url"

            # 使用timeout避免长时间等待
            if timeout 3 bash -c "curl -s --max-time 2 --proxy '$proxy_url' https://github.com > /dev/null" 2>/dev/null; then
                log_success "✅ 发现可用代理: $proxy_url"

                if [[ "$protocol" == "http" ]]; then
                    export http_proxy="$proxy_url"
                    export https_proxy="$proxy_url"
                    git config --global http.proxy "$proxy_url"
                    git config --global https.proxy "$proxy_url"
                else
                    export all_proxy="$proxy_url"
                    # 对于socks5，仍然设置http代理为http协议
                    export http_proxy="http://$proxy_addr"
                    export https_proxy="http://$proxy_addr"
                    git config --global http.proxy "http://$proxy_addr"
                    git config --global https.proxy "http://$proxy_addr"
                fi

                log_success "✅ 代理已自动启用: $proxy_url"
                return 0
            fi
        done
    done

    # 6. 检查是否有VPN或代理软件运行
    log_info "🔍 检查VPN和代理软件..."

    # 检查常见代理软件进程
    local proxy_processes=("clash" "v2ray" "ssr" "shadowsocks" "privoxy" "proxychains")

    for process in "${proxy_processes[@]}"; do
        if pgrep -f "$process" > /dev/null 2>&1; then
            log_success "✅ 检测到代理软件运行: $process"
            # 尝试使用默认配置
            if [[ "$process" == "clash" ]]; then
                local clash_config="${HOME}/.config/clash/config.yaml"
                if [[ -f "$clash_config" ]]; then
                    local port=$(grep -E "^port:" "$clash_config" | cut -d: -f2 | tr -d ' ' | head -1)
                    if [[ -n "$port" ]]; then
                        local proxy_url="http://127.0.0.1:$port"
                        log_success "✅ 从Clash配置中获取代理: $proxy_url"
                        export http_proxy="$proxy_url"
                        export https_proxy="$proxy_url"
                        git config --global http.proxy "$proxy_url"
                        git config --global https.proxy "$proxy_url"
                        return 0
                    fi
                fi
            fi
        fi
    done

    log_info "ℹ️ 未检测到代理设置，将使用直连模式"
    log_info "💡 提示: 如果需要使用代理，请设置环境变量或配置文件"
    return 1
}

# 显示部署统计
show_deploy_stats() {
    local end_time=$(date +%s)
    local total_duration=$((end_time - START_TIME))

    log_info "📊 部署统计报告"
    echo "========================================"

    # 时间统计
    log_info "⏰ 时间统计:"
    if [[ -n "$BUILD_DURATION" ]]; then
        log_info "   构建耗时: ${BUILD_DURATION}秒"
    fi
    if [[ -n "$DEPLOY_DURATION" ]]; then
        log_info "   部署耗时: ${DEPLOY_DURATION}秒"
    fi
    log_info "   总耗时: ${total_duration}秒"

    # 文件统计
    if [[ -n "$GENERATED_FILES" && "$GENERATED_FILES" -gt 0 ]]; then
        log_info "📁 文件统计:"
        log_info "   生成文件数: $GENERATED_FILES"
        if [[ -n "$DEPLOYED_SIZE" ]]; then
            log_info "   部署大小: $DEPLOYED_SIZE"
        fi
    fi

    # 系统信息
    log_info "💻 系统信息:"
    log_info "   操作系统: $(uname -s) $(uname -m)"
    log_info "   Node.js版本: $(node --version 2>/dev/null || echo '未知')"
    log_info "   Hexo版本: $(hexo version 2>/dev/null | grep "hexo:" | cut -d: -f2 | tr -d ' ' || echo '未知')"
    log_info "   Git版本: $(git --version | cut -d' ' -f3 || echo '未知')"

    # 网络和代理信息
    if [[ -n "$http_proxy" ]]; then
        log_info "🌐 网络代理: $http_proxy"
    else
        log_info "🌐 网络模式: 直连"
    fi

    echo "========================================"

    # 生成部署日志
    generate_deploy_log "$total_duration"
}

# 生成部署日志
generate_deploy_log() {
    local total_duration="$1"
    local log_file="deploy-$(date +'%Y%m%d-%H%M%S').log"

    log_info "📝 生成部署日志: $log_file"

    {
        echo "=== Hexo 博客部署日志 ==="
        echo "部署时间: $(date +'%Y-%m-%d %H:%M:%S')"
        echo "工作目录: $BLOG_DIR"
        echo "总耗时: ${total_duration}秒"
        echo ""
        echo "=== 构建信息 ==="
        echo "构建耗时: ${BUILD_DURATION:-'N/A'}秒"
        echo "生成文件数: ${GENERATED_FILES:-'N/A'}"
        echo "部署大小: ${DEPLOYED_SIZE:-'N/A'}"
        echo ""
        echo "=== 部署信息 ==="
        echo "部署耗时: ${DEPLOY_DURATION:-'N/A'}秒"
        echo "部署分支: $DEPLOY_BRANCH"
        echo "源码分支: $SOURCE_BRANCH"
        echo ""
        echo "=== 系统信息 ==="
        echo "操作系统: $(uname -s) $(uname -m)"
        echo "Node.js版本: $(node --version 2>/dev/null || echo '未知')"
        echo "Hexo版本: $(hexo version 2>/dev/null | grep "hexo:" | cut -d: -f2 | tr -d ' ' || echo '未知')"
        echo "Git版本: $(git --version | cut -d' ' -f3 || echo '未知')"
        echo ""
        echo "=== 网络配置 ==="
        if [[ -n "$http_proxy" ]]; then
            echo "HTTP代理: $http_proxy"
        else
            echo "网络模式: 直连"
        fi
        if [[ -n "$https_proxy" ]]; then
            echo "HTTPS代理: $https_proxy"
        fi
        echo ""
        echo "=== 部署结果 ==="
        echo "状态: 成功"
        echo "完成时间: $(date +'%Y-%m-%d %H:%M:%S')"
        echo "========================================"

    } > "$log_file"

    log_success "✅ 部署日志已保存到: $log_file"
}

# 运行主函数
main "$@"
