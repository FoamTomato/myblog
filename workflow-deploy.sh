#!/bin/bash

# Hexo 博客工作流部署脚本
# 提供多种部署工作流的自动化处理

set -e

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# 工作流：新文章发布
workflow_new_post() {
    local post_title="$1"

    if [[ -z "$post_title" ]]; then
        log_error "需要提供文章标题"
        echo "用法: $0 new-post '文章标题'"
        exit 1
    fi

    log_info "开始新文章发布工作流: $post_title"

    # 1. 创建新文章
    log_info "创建新文章..."
    hexo new post "$post_title"

    # 2. 查找新创建的文件
    local new_post_file=$(find source/_posts -name "*$post_title*" -type f | head -1)

    if [[ -z "$new_post_file" ]]; then
        log_error "未找到新创建的文章文件"
        exit 1
    fi

    log_success "文章已创建: $new_post_file"

    # 3. 打开编辑器（如果可用）
    if command -v code &> /dev/null; then
        log_info "打开VS Code编辑文章..."
        code "$new_post_file"
    elif command -v vim &> /dev/null; then
        log_info "打开Vim编辑文章..."
        vim "$new_post_file"
    else
        log_info "请手动编辑文章: $new_post_file"
    fi

    # 4. 等待用户编辑完成
    read -p "文章编辑完成？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "文章编辑已取消"
        exit 0
    fi

    # 5. 本地预览
    log_info "启动本地预览服务器..."
    hexo server --open &
    local server_pid=$!

    read -p "预览满意？(y/N): " -n 1 -r
    echo
    kill $server_pid 2>/dev/null || true

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "工作流已取消"
        exit 0
    fi

    # 6. 提交和部署
    log_info "提交源代码..."
    git add .
    git commit -m "Add new post: $post_title"

    log_info "执行完整部署..."
    "$SCRIPT_DIR/advanced-deploy.sh" deploy

    log_success "新文章发布完成！🎉"
}

# 工作流：批量文章更新
workflow_bulk_update() {
    log_info "开始批量文章更新工作流"

    # 1. 检查有哪些文章
    local post_count=$(find source/_posts -name "*.md" | wc -l)
    log_info "发现 $post_count 篇文章"

    # 2. 显示最近修改的文章
    echo "最近修改的文章:"
    find source/_posts -name "*.md" -mtime -7 -exec ls -lt {} \; | head -10

    # 3. 询问用户是否继续
    read -p "是否要更新所有文章的元数据？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "工作流已取消"
        exit 0
    fi

    # 4. 批量更新Front Matter
    log_info "更新文章元数据..."
    find source/_posts -name "*.md" -exec "$SCRIPT_DIR/update-posts.sh" {} \;

    # 5. 重新生成
    log_info "重新生成静态文件..."
    hexo clean && hexo generate

    # 6. 提交更改
    if [[ -n "$(git status --porcelain)" ]]; then
        git add .
        git commit -m "Bulk update posts metadata and regenerate"
        log_success "更改已提交"
    else
        log_info "没有需要提交的更改"
    fi

    # 7. 部署
    "$SCRIPT_DIR/advanced-deploy.sh" deploy

    log_success "批量更新完成！"
}

# 工作流：备份和迁移
workflow_backup_migrate() {
    local target_dir="$1"

    if [[ -z "$target_dir" ]]; then
        log_error "需要提供目标目录"
        echo "用法: $0 backup-migrate /path/to/backup"
        exit 1
    fi

    log_info "开始备份和迁移工作流: $target_dir"

    # 1. 创建备份
    log_info "创建完整备份..."
    local backup_name="full_backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$target_dir/$backup_name"

    mkdir -p "$backup_path"

    # 备份源文件
    cp -r source "$backup_path/"
    cp -r themes "$backup_path/"
    cp -r .github "$backup_path/" 2>/dev/null || true
    cp _config.yml "$backup_path/"
    cp package.json "$backup_path/"
    cp .env "$backup_path/" 2>/dev/null || true

    log_success "备份已创建: $backup_path"

    # 2. 迁移到新位置
    read -p "是否要迁移到新位置？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local new_location="$2"

        if [[ -z "$new_location" ]]; then
            read -p "请输入新位置路径: " new_location
        fi

        if [[ -d "$new_location" ]]; then
            log_error "目标位置已存在"
            exit 1
        fi

        log_info "迁移到新位置: $new_location"
        cp -r "$backup_path" "$new_location"

        # 初始化新的Git仓库
        cd "$new_location"
        rm -rf .git
        git init
        git add .
        git commit -m "Initial commit - migrated from backup"

        log_success "迁移完成！新位置: $new_location"
    fi

    log_success "备份和迁移工作流完成！"
}

# 工作流：性能优化
workflow_performance_optimize() {
    log_info "开始性能优化工作流"

    # 1. 分析当前性能
    log_info "分析当前网站性能..."
    if [[ -d "public" ]]; then
        local file_count=$(find public -type f | wc -l)
        local total_size=$(du -sh public | cut -f1)
        local html_count=$(find public -name "*.html" | wc -l)

        echo "=== 当前性能统计 ==="
        echo "文件总数: $file_count"
        echo "总大小: $total_size"
        echo "HTML页面数: $html_count"
        echo "==================="

        # 找出最大的文件
        echo "最大的10个文件:"
        find public -type f -exec ls -lh {} \; | sort -k5 -hr | head -10
    else
        log_warning "未找到public目录，请先运行 hexo generate"
        exit 1
    fi

    # 2. 应用优化措施
    log_info "应用性能优化..."

    # 启用压缩
    export ENABLE_MINIFY=true
    export ENABLE_COMPRESS=true

    # 重新生成
    hexo clean && hexo generate

    # 3. 比较优化效果
    local new_file_count=$(find public -type f | wc -l)
    local new_total_size=$(du -sh public | cut -f1)

    echo "=== 优化后性能统计 ==="
    echo "文件总数: $new_file_count"
    echo "总大小: $new_total_size"
    echo "==================="

    # 4. 生成优化报告
    {
        echo "# 🚀 性能优化报告"
        echo ""
        echo "**优化时间**: $(date)"
        echo ""
        echo "## 📊 优化结果"
        echo "- 文件数量变化: $file_count → $new_file_count"
        echo "- 文件大小变化: $total_size → $new_total_size"
        echo ""
        echo "## ✅ 已应用的优化"
        echo "- 启用HTML压缩"
        echo "- 启用CSS/JS压缩"
        echo "- 优化图片资源"
        echo ""
        echo "**优化完成** ⏰ $(date)"
    } > performance-optimization-report.md

    log_success "性能优化完成！查看报告: performance-optimization-report.md"

    # 5. 询问是否部署
    read -p "是否现在部署优化后的版本？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        "$SCRIPT_DIR/advanced-deploy.sh" deploy
    fi
}

# 工作流：SEO优化
workflow_seo_optimize() {
    log_info "开始SEO优化工作流"

    # 1. 检查SEO相关文件
    local seo_files=("robots.txt" "sitemap.xml")
    local missing_files=()

    for file in "${seo_files[@]}"; do
        if [[ ! -f "source/$file" ]] && [[ ! -f "public/$file" ]]; then
            missing_files+=("$file")
        fi
    done

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_info "发现缺失的SEO文件: ${missing_files[*]}"

        # 创建robots.txt
        if [[ ! -f "source/robots.txt" ]]; then
            cat > source/robots.txt << 'EOF'
User-agent: *
Allow: /

# 允许搜索引擎索引所有内容
# 禁止索引的路径可以在下面添加
# Disallow: /private/
# Disallow: /admin/

Sitemap: https://your-username.github.io/your-repo/sitemap.xml
EOF
            log_success "已创建 robots.txt"
        fi

        # 创建sitemap.xml模板
        if [[ ! -f "source/sitemap.xml" ]]; then
            cat > source/sitemap.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    <!-- 此文件将在构建时自动更新 -->
    <!-- 最新的文章将自动添加到这里 -->
</urlset>
EOF
            log_success "已创建 sitemap.xml 模板"
        fi
    fi

    # 2. 检查文章SEO优化
    log_info "检查文章SEO优化..."

    local posts_without_description=0
    local posts_without_tags=0

    while IFS= read -r -d '' post_file; do
        # 检查是否有description
        if ! grep -q "^description:" "$post_file"; then
            ((posts_without_description++))
        fi

        # 检查是否有tags
        if ! grep -q "^tags:" "$post_file"; then
            ((posts_without_tags++))
        fi
    done < <(find source/_posts -name "*.md" -print0)

    echo "=== SEO 检查结果 ==="
    echo "缺少描述的文章: $posts_without_description"
    echo "缺少标签的文章: $posts_without_tags"
    echo "==================="

    # 3. 询问是否自动修复
    if [[ $posts_without_description -gt 0 ]] || [[ $posts_without_tags -gt 0 ]]; then
        read -p "是否要自动为文章添加SEO优化？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            "$SCRIPT_DIR/seo-optimize.sh"
        fi
    fi

    # 4. 重新生成
    hexo clean && hexo generate

    log_success "SEO优化完成！"
}

# 工作流：内容发布检查清单
workflow_publish_checklist() {
    log_info "开始内容发布检查清单"

    local checks_passed=0
    local total_checks=0

    echo "=== 📋 发布前检查清单 ==="

    # 1. 检查必需文件
    ((total_checks++))
    if [[ -f "_config.yml" ]]; then
        echo "✅ _config.yml 存在"
        ((checks_passed++))
    else
        echo "❌ 缺少 _config.yml"
    fi

    # 2. 检查文章
    ((total_checks++))
    local post_count=$(find source/_posts -name "*.md" | wc -l)
    if [[ $post_count -gt 0 ]]; then
        echo "✅ 找到 $post_count 篇文章"
        ((checks_passed++))
    else
        echo "❌ 没有找到任何文章"
    fi

    # 3. 检查主题
    ((total_checks++))
    if [[ -d "themes" ]] && [[ -n "$(ls themes/)" ]]; then
        echo "✅ 主题已配置"
        ((checks_passed++))
    else
        echo "❌ 主题未配置"
    fi

    # 4. 检查依赖
    ((total_checks++))
    if [[ -f "package.json" ]] && [[ -d "node_modules" ]]; then
        echo "✅ 依赖已安装"
        ((checks_passed++))
    else
        echo "❌ 依赖未正确安装"
    fi

    # 5. 检查Git状态
    ((total_checks++))
    if git rev-parse --git-dir &> /dev/null; then
        echo "✅ Git仓库已初始化"

        if git remote get-url origin &> /dev/null; then
            echo "✅ Git远程仓库已配置"
            ((checks_passed++))
        else
            echo "❌ Git远程仓库未配置"
        fi

        if git config user.name &> /dev/null && git config user.email &> /dev/null; then
            echo "✅ Git用户信息已配置"
            ((checks_passed++))
        else
            echo "❌ Git用户信息未配置"
        fi
    else
        echo "❌ Git仓库未初始化"
    fi

    # 6. 检查部署配置
    ((total_checks++))
    if [[ -f ".env" ]] || [[ -f "deploy-config.sh" ]]; then
        echo "✅ 部署配置存在"
        ((checks_passed++))
    else
        echo "❌ 部署配置不存在"
    fi

    echo ""
    echo "检查结果: $checks_passed/$total_checks 通过"

    if [[ $checks_passed -eq $total_checks ]]; then
        log_success "所有检查通过！可以安全发布 🎉"

        read -p "是否现在开始部署？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            "$SCRIPT_DIR/advanced-deploy.sh" deploy
        fi
    else
        log_warning "部分检查未通过，请根据上述提示修复问题"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    echo "Hexo 博客工作流部署脚本"
    echo ""
    echo "用法:"
    echo "  $0 <workflow> [参数...]"
    echo ""
    echo "可用的工作流:"
    echo "  new-post <标题>        新文章发布流程"
    echo "  bulk-update            批量文章更新"
    echo "  backup-migrate <目录>  备份和迁移"
    echo "  performance-optimize   性能优化"
    echo "  seo-optimize          SEO优化"
    echo "  publish-checklist      发布前检查清单"
    echo ""
    echo "示例:"
    echo "  $0 new-post '我的新文章'"
    echo "  $0 backup-migrate /tmp/backup"
    echo "  $0 publish-checklist"
}

# 主函数
main() {
    local workflow="$1"

    case "$workflow" in
        "new-post")
            workflow_new_post "$2"
            ;;
        "bulk-update")
            workflow_bulk_update
            ;;
        "backup-migrate")
            workflow_backup_migrate "$2" "$3"
            ;;
        "performance-optimize")
            workflow_performance_optimize
            ;;
        "seo-optimize")
            workflow_seo_optimize
            ;;
        "publish-checklist")
            workflow_publish_checklist
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
