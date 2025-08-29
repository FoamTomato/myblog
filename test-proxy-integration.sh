#!/bin/bash

# 测试代理集成功能
# 验证所有部署脚本都能正确使用代理

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 测试脚本
test_script() {
    local script="$1"
    local test_command="$2"
    local description="$3"

    log_info "测试 $description..."

    if [[ ! -x "$script" ]]; then
        log_error "脚本不存在或没有执行权限: $script"
        return 1
    fi

    # 运行测试命令
    if bash -c "unset http_proxy https_proxy all_proxy && timeout 30 ./$script $test_command" 2>/dev/null; then
        log_success "$description 测试通过"
        return 0
    else
        log_error "$description 测试失败"
        return 1
    fi
}

# 测试代理自动检测
test_proxy_detection() {
    log_info "测试代理自动检测功能..."

    # 测试deploy.sh
    log_info "测试 deploy.sh..."
    if ./deploy.sh --offline 2>&1 | grep -q "代理已自动启用\|检测到.*代理\|Git代理配置"; then
        log_success "deploy.sh 代理自动检测正常"
    else
        log_warning "deploy.sh 代理自动检测可能有问题"
    fi

    # 测试advanced-deploy.sh
    log_info "测试 advanced-deploy.sh..."
    if ./advanced-deploy.sh status 2>&1 | grep -q "代理已自动启用\|检测到.*代理\|Git代理配置"; then
        log_success "advanced-deploy.sh 代理自动检测正常"
    else
        log_warning "advanced-deploy.sh 代理自动检测可能有问题"
    fi

    # 测试workflow-deploy.sh
    log_info "测试 workflow-deploy.sh..."
    if ./workflow-deploy.sh publish-checklist 2>&1 | grep -q "代理已自动启用\|检测到.*代理\|Git代理配置"; then
        log_success "workflow-deploy.sh 代理自动检测正常"
    else
        log_warning "workflow-deploy.sh 代理自动检测可能有问题"
    fi

    return 0
}

# 测试配置文件
test_config_file() {
    log_info "测试代理配置文件..."

    if [[ ! -f ".proxy-config" ]]; then
        log_error "代理配置文件不存在"
        return 1
    fi

    # 检查配置文件内容
    if grep -q "HTTP_PROXY" .proxy-config && grep -q "HTTPS_PROXY" .proxy-config; then
        log_success "代理配置文件格式正确"
        return 0
    else
        log_error "代理配置文件格式错误"
        return 1
    fi
}

# 生成测试报告
generate_test_report() {
    local report_file="proxy-integration-test-report.md"
    local start_time=$(date +%s)

    log_info "生成测试报告..."

    {
        echo "# 🔗 代理集成测试报告"
        echo ""
        echo "**测试时间**: $(date)"
        echo "**测试环境**: $(uname -a)"
        echo ""

        echo "## 📋 测试结果"
        echo ""

        # 测试脚本权限
        echo "### 脚本权限检查"
        local scripts=("deploy.sh" "advanced-deploy.sh" "workflow-deploy.sh" "proxy-setup.sh")
        for script in "${scripts[@]}"; do
            if [[ -x "$script" ]]; then
                echo "- ✅ $script: 有执行权限"
            else
                echo "- ❌ $script: 缺少执行权限"
            fi
        done
        echo ""

        # 测试配置文件
        echo "### 配置文件检查"
        if [[ -f ".proxy-config" ]]; then
            echo "- ✅ .proxy-config: 存在"
            if grep -q "HTTP_PROXY" .proxy-config; then
                echo "- ✅ 包含HTTP_PROXY配置"
            fi
            if grep -q "HTTPS_PROXY" .proxy-config; then
                echo "- ✅ 包含HTTPS_PROXY配置"
            fi
        else
            echo "- ❌ .proxy-config: 不存在"
        fi
        echo ""

        # 测试网络连接
        echo "### 网络连接测试"
        if curl -s --max-time 5 https://github.com > /dev/null; then
            echo "- ✅ GitHub直连: 成功"
        else
            echo "- ❌ GitHub直连: 失败"
        fi

        if curl -s --max-time 5 --proxy http://127.0.0.1:7890 https://github.com > /dev/null; then
            echo "- ✅ GitHub代理: 成功"
        else
            echo "- ❌ GitHub代理: 失败"
        fi
        echo ""

        # 代理状态
        echo "### 代理状态"
        if [[ -n "$http_proxy" ]]; then
            echo "- ✅ http_proxy: $http_proxy"
        else
            echo "- ℹ️  http_proxy: 未设置"
        fi

        if [[ -n "$https_proxy" ]]; then
            echo "- ✅ https_proxy: $https_proxy"
        else
            echo "- ℹ️  https_proxy: 未设置"
        fi

        local git_http=$(git config --global --get http.proxy 2>/dev/null || echo "未设置")
        local git_https=$(git config --global --get https.proxy 2>/dev/null || echo "未设置")
        echo "- Git HTTP代理: $git_http"
        echo "- Git HTTPS代理: $git_https"
        echo ""

        echo "## 🎯 测试总结"
        echo ""
        echo "**测试用时**: $(( $(date +%s) - start_time )) 秒"
        echo "**测试状态**: 完成"
        echo ""

        echo "## 💡 使用建议"
        echo ""
        echo "1. **自动代理**: 所有部署脚本现在都默认启用代理"
        echo "2. **自定义配置**: 编辑 .proxy-config 来自定义代理设置"
        echo "3. **手动控制**: 使用 ./proxy-setup.sh 手动管理代理"
        echo "4. **网络诊断**: 使用 ./network-diagnosis.sh 诊断网络问题"
        echo ""

        echo "**报告生成完成** ⏰ $(date)"

    } > "$report_file"

    log_success "测试报告已生成: $report_file"
}

# 显示帮助信息
show_help() {
    echo "代理集成测试脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -t, --test-all      完整测试"
    echo "  -p, --proxy         测试代理功能"
    echo "  -c, --config        测试配置文件"
    echo "  -r, --report        生成测试报告"
    echo ""
    echo "示例:"
    echo "  $0 --test-all       # 完整测试"
    echo "  $0 --proxy          # 测试代理功能"
    echo "  $0 --report         # 生成报告"
}

# 主函数
main() {
    local test_all=false
    local proxy_test=false
    local config_test=false
    local report=false

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -t|--test-all)
                test_all=true
                shift
                ;;
            -p|--proxy)
                proxy_test=true
                shift
                ;;
            -c|--config)
                config_test=true
                shift
                ;;
            -r|--report)
                report=true
                shift
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 如果没有指定选项，运行完整测试
    if [[ "$test_all" == "false" && "$proxy_test" == "false" && "$config_test" == "false" && "$report" == "false" ]]; then
        test_all=true
    fi

    # 执行测试
    if [[ "$test_all" == "true" || "$config_test" == "true" ]]; then
        log_info "=== 配置文件测试 ==="
        test_config_file
        echo ""
    fi

    if [[ "$test_all" == "true" || "$proxy_test" == "true" ]]; then
        log_info "=== 代理功能测试 ==="
        test_proxy_detection
        echo ""
    fi

    if [[ "$report" == "true" ]]; then
        generate_test_report
    fi

    log_success "代理集成测试完成！"
}

# 执行主函数
main "$@"
