#!/bin/bash

# Hexo 博客部署测试脚本
# 用于验证部署配置和环境是否正确

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 测试函数
test_system_requirements() {
    log_info "测试系统要求..."

    local tests_passed=0
    local total_tests=0

    # 测试必需命令
    local required_commands=("node" "npm" "git" "curl")
    for cmd in "${required_commands[@]}"; do
        ((total_tests++))
        if command -v "$cmd" &> /dev/null; then
            log_success "$cmd 可用"
            ((tests_passed++))
        else
            log_error "$cmd 未找到"
        fi
    done

    # 测试Node.js版本
    ((total_tests++))
    if command -v node &> /dev/null; then
        local node_version=$(node -v | sed 's/v//')
        if [[ "$(printf '%s\n' "14.0.0" "$node_version" | sort -V | head -n1)" = "14.0.0" ]]; then
            log_success "Node.js版本: $node_version ✓"
            ((tests_passed++))
        else
            log_error "Node.js版本过低: $node_version (需要 >= 14.0.0)"
        fi
    fi

    # 测试npm版本
    ((total_tests++))
    if command -v npm &> /dev/null; then
        local npm_version=$(npm -v)
        log_success "npm版本: $npm_version ✓"
        ((tests_passed++))
    else
        log_error "npm未找到"
    fi

    echo "系统要求测试: $tests_passed/$total_tests 通过"
    return $((total_tests - tests_passed))
}

test_project_structure() {
    log_info "测试项目结构..."

    local tests_passed=0
    local total_tests=0

    # 测试必需文件
    local required_files=("_config.yml" "package.json")
    for file in "${required_files[@]}"; do
        ((total_tests++))
        if [[ -f "$file" ]]; then
            log_success "$file 存在 ✓"
            ((tests_passed++))
        else
            log_error "$file 不存在"
        fi
    done

    # 测试可选文件
    local optional_files=("yarn.lock" "package-lock.json" ".env")
    for file in "${optional_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_info "$file 存在 (可选)"
        fi
    done

    # 测试目录结构
    local required_dirs=("source" "themes")
    for dir in "${required_dirs[@]}"; do
        ((total_tests++))
        if [[ -d "$dir" ]]; then
            log_success "$dir 目录存在 ✓"
            ((tests_passed++))
        else
            log_error "$dir 目录不存在"
        fi
    done

    echo "项目结构测试: $tests_passed/$total_tests 通过"
    return $((total_tests - tests_passed))
}

test_git_configuration() {
    log_info "测试Git配置..."

    local tests_passed=0
    local total_tests=0

    # 测试Git仓库
    ((total_tests++))
    if git rev-parse --git-dir &> /dev/null; then
        log_success "Git仓库初始化 ✓"
        ((tests_passed++))
    else
        log_error "不是Git仓库"
        return 1
    fi

    # 测试远程仓库
    ((total_tests++))
    if git remote get-url origin &> /dev/null; then
        local remote_url=$(git remote get-url origin)
        log_success "远程仓库配置: $remote_url ✓"
        ((tests_passed++))
    else
        log_warning "未配置远程仓库"
    fi

    # 测试Git用户配置
    ((total_tests++))
    if git config user.name &> /dev/null && git config user.email &> /dev/null; then
        local user_name=$(git config user.name)
        local user_email=$(git config user.email)
        log_success "Git用户信息: $user_name <$user_email> ✓"
        ((tests_passed++))
    else
        log_warning "Git用户信息未配置"
    fi

    echo "Git配置测试: $tests_passed/$total_tests 通过"
    return $((total_tests - tests_passed))
}

test_dependencies() {
    log_info "测试依赖安装..."

    local tests_passed=0
    local total_tests=0

    # 检查package.json
    ((total_tests++))
    if [[ -f "package.json" ]]; then
        log_success "package.json存在 ✓"
        ((tests_passed++))
    else
        log_error "package.json不存在"
        return 1
    fi

    # 检查node_modules
    ((total_tests++))
    if [[ -d "node_modules" ]]; then
        log_success "node_modules目录存在 ✓"
        ((tests_passed++))
    else
        log_warning "node_modules不存在，建议运行 npm install"
    fi

    # 检查Hexo CLI
    ((total_tests++))
    if command -v hexo &> /dev/null; then
        local hexo_version=$(hexo version | grep "hexo:" | awk '{print $2}')
        log_success "Hexo CLI安装: $hexo_version ✓"
        ((tests_passed++))
    else
        log_warning "Hexo CLI未安装，建议运行 npm install -g hexo-cli"
    fi

    echo "依赖测试: $tests_passed/$total_tests 通过"
    return $((total_tests - tests_passed))
}

test_build_process() {
    log_info "测试构建过程..."

    local tests_passed=0
    local total_tests=0

    # 清理缓存
    ((total_tests++))
    if hexo clean &> /dev/null; then
        log_success "Hexo缓存清理成功 ✓"
        ((tests_passed++))
    else
        log_error "Hexo缓存清理失败"
    fi

    # 生成静态文件
    ((total_tests++))
    if hexo generate &> /dev/null; then
        log_success "静态文件生成成功 ✓"
        ((tests_passed++))
    else
        log_error "静态文件生成失败"
    fi

    # 检查public目录
    ((total_tests++))
    if [[ -d "public" ]]; then
        local file_count=$(find public -type f | wc -l)
        local dir_size=$(du -sh public | cut -f1)
        log_success "构建产物: $file_count 个文件，大小 $dir_size ✓"
        ((tests_passed++))
    else
        log_error "public目录不存在"
    fi

    echo "构建测试: $tests_passed/$total_tests 通过"
    return $((total_tests - tests_passed))
}

test_deployment_configuration() {
    log_info "测试部署配置..."

    local tests_passed=0
    local total_tests=0

    # 检查部署脚本
    local deploy_scripts=("deploy.sh" "advanced-deploy.sh" "deploy-config.sh")
    for script in "${deploy_scripts[@]}"; do
        ((total_tests++))
        if [[ -f "$script" ]]; then
            if [[ -x "$script" ]]; then
                log_success "$script 存在并可执行 ✓"
                ((tests_passed++))
            else
                log_warning "$script 存在但不可执行"
                ((tests_passed++))
            fi
        else
            log_info "$script 不存在 (可选)"
        fi
    done

    # 检查GitHub Actions配置
    ((total_tests++))
    if [[ -f ".github/workflows/hexo-deploy.yml" ]]; then
        log_success "GitHub Actions配置存在 ✓"
        ((tests_passed++))
    else
        log_info "GitHub Actions配置不存在 (可选)"
    fi

    # 检查环境变量文件
    ((total_tests++))
    if [[ -f ".env" ]]; then
        log_success ".env文件存在 ✓"
        ((tests_passed++))
    else
        log_info ".env文件不存在，建议创建 (可选)"
    fi

    echo "部署配置测试: $tests_passed/$total_tests 通过"
    return $((total_tests - tests_passed))
}

show_summary() {
    log_info "=== 测试总结 ==="
    echo "✅ 所有测试完成"
    echo ""
    echo "📋 建议操作:"
    echo "1. 如果有失败的测试，请根据错误信息修复"
    echo "2. 运行 'npm install' 安装依赖"
    echo "3. 运行 'npm install -g hexo-cli' 安装Hexo CLI"
    echo "4. 配置Git远程仓库: git remote add origin <repository-url>"
    echo "5. 设置Git用户信息: git config user.name/email"
    echo "6. 创建 .env 文件配置环境变量"
    echo "7. 测试构建: ./test-deploy.sh build"
    echo "8. 测试部署: ./advanced-deploy.sh deploy"
    echo ""
    echo "🚀 快速开始:"
    echo "  ./advanced-deploy.sh deploy    # 完整部署"
    echo "  ./advanced-deploy.sh build     # 只构建"
    echo "  ./advanced-deploy.sh status    # 查看状态"
}

run_all_tests() {
    local total_failed=0

    echo "🧪 开始运行部署测试..."
    echo "========================================"

    test_system_requirements
    ((total_failed += $?))

    echo ""

    test_project_structure
    ((total_failed += $?))

    echo ""

    test_git_configuration
    ((total_failed += $?))

    echo ""

    test_dependencies
    ((total_failed += $?))

    echo ""

    test_deployment_configuration
    ((total_failed += $?))

    echo ""
    echo "========================================"

    if [[ $total_failed -eq 0 ]]; then
        log_success "所有测试通过！🎉"
    else
        log_warning "有 $total_failed 个测试失败，请检查上述错误信息"
    fi

    echo ""

    show_summary

    return $total_failed
}

# 主函数
main() {
    case "${1:-all}" in
        "system")
            test_system_requirements
            ;;
        "structure")
            test_project_structure
            ;;
        "git")
            test_git_configuration
            ;;
        "deps")
            test_dependencies
            ;;
        "build")
            test_build_process
            ;;
        "deploy")
            test_deployment_configuration
            ;;
        "all")
            run_all_tests
            ;;
        *)
            echo "用法: $0 [system|structure|git|deps|build|deploy|all]"
            echo ""
            echo "测试项目:"
            echo "  system    - 系统要求"
            echo "  structure - 项目结构"
            echo "  git       - Git配置"
            echo "  deps      - 依赖安装"
            echo "  build     - 构建过程"
            echo "  deploy    - 部署配置"
            echo "  all       - 运行所有测试 (默认)"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
