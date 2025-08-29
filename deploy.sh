#!/bin/bash

# Hexo 博客自动部署脚本
# 用于自动构建和部署到 GitHub Pages

set -e  # 遇到错误立即退出

# 配置变量
BLOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_BRANCH="main"
DEPLOY_BRANCH="gh-pages"
COMMIT_MESSAGE="Site updated: $(date +'%Y-%m-%d %H:%M:%S')"
DEPLOY_DIR="_site"

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

# 清理缓存
clean_cache() {
    log_info "清理缓存..."

    hexo clean
    log_success "缓存清理完成"
}

# 生成静态文件
generate_site() {
    log_info "生成静态文件..."

    hexo generate
    log_success "静态文件生成完成"
}

# 部署到GitHub Pages
deploy_to_github() {
    log_info "开始部署到 GitHub Pages..."

    # 检查是否存在部署配置
    if [[ ! -f "_config.yml" ]]; then
        log_error "未找到 _config.yml 文件"
        exit 1
    fi

    # 使用Hexo内置的deploy命令
    hexo deploy
    log_success "部署到 GitHub Pages 完成"
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

# 推送源码
push_source() {
    log_info "推送源码到 $SOURCE_BRANCH 分支..."

    git add .
    git commit -m "$COMMIT_MESSAGE" || log_warning "没有新的更改需要提交"
    git push origin $SOURCE_BRANCH

    log_success "源码推送完成"
}

# 显示帮助信息
show_help() {
    echo "Hexo 博客自动部署脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -c, --clean         清理缓存"
    echo "  -g, --generate      生成静态文件"
    echo "  -d, --deploy        部署到 GitHub Pages"
    echo "  -p, --push          推送源码"
    echo "  -a, --all          执行完整流程（推荐）"
    echo "  --manual           使用手动部署方式"
    echo "  --preview          启动本地预览服务器"
    echo "  --offline          离线测试（网络不可用时使用）"
    echo ""
    echo "示例:"
    echo "  $0 --all           # 完整部署流程"
    echo "  $0 -c -g -d        # 清理、生成、部署"
    echo "  $0 --preview       # 本地预览"
    echo "  $0 --offline       # 离线测试"
}

# 主函数
main() {
    local clean=false
    local generate=false
    local deploy=false
    local push=false
    local manual=false
    local all=false

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
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 检查工作目录
    if [[ ! -f "_config.yml" ]]; then
        log_error "请在 Hexo 博客根目录下运行此脚本"
        exit 1
    fi

    log_info "开始 Hexo 博客部署流程..."
    log_info "工作目录: $BLOG_DIR"

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
        log_warning "未指定操作，使用 --all 执行完整流程"
        all=true
        clean=true
        generate=true
        deploy=true
        push=true
    fi

    log_success "部署流程完成！"
    log_info "访问你的博客: https://你的用户名.github.io"
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

# 运行主函数
main "$@"
