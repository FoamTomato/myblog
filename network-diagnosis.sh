#!/bin/bash

# Hexo 博客网络诊断脚本
# 用于诊断和解决网络连接问题

set -e

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

# 测试网络连接
test_network_connectivity() {
    local target="$1"
    local timeout="${2:-10}"

    log_info "测试连接: $target"

    if curl -s --max-time "$timeout" "$target" > /dev/null; then
        log_success "✓ 连接成功"
        return 0
    else
        log_error "✗ 连接失败"
        return 1
    fi
}

# 测试DNS解析
test_dns_resolution() {
    local domain="$1"

    log_info "测试DNS解析: $domain"

    if nslookup "$domain" 2>/dev/null | grep -q "Address"; then
        local ip=$(nslookup "$domain" 2>/dev/null | grep "Address" | tail -1 | awk '{print $2}')
        log_success "✓ DNS解析成功: $ip"
        return 0
    else
        log_error "✗ DNS解析失败"
        return 1
    fi
}

# 测试Git连接
test_git_connection() {
    log_info "测试Git连接..."

    # 测试GitHub
    if git ls-remote https://github.com/octocat/Hello-World.git HEAD &>/dev/null; then
        log_success "✓ GitHub连接正常"
        return 0
    else
        log_error "✗ GitHub连接失败"
        return 1
    fi
}

# 检测网络代理
detect_proxy() {
    log_info "检测网络代理设置..."

    local proxy_vars=("http_proxy" "https_proxy" "HTTP_PROXY" "HTTPS_PROXY")
    local proxy_found=false

    for var in "${proxy_vars[@]}"; do
        if [[ -n "${!var}" ]]; then
            log_info "发现代理设置: $var=${!var}"
            proxy_found=true
        fi
    done

    if [[ "$proxy_found" == "false" ]]; then
        log_info "未检测到代理设置"
    fi

    # 检查git代理
    if git config --global --get http.proxy &>/dev/null; then
        local git_proxy=$(git config --global --get http.proxy)
        log_info "Git代理设置: $git_proxy"
    fi
}

# 测试网络速度
test_network_speed() {
    log_info "测试网络速度..."

    # 下载一个小文件测试速度
    local test_file="https://www.google.com/favicon.ico"
    local start_time=$(date +%s)

    if curl -s -o /tmp/speed_test.ico --max-time 10 "$test_file"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        if [[ -f /tmp/speed_test.ico ]]; then
            local size=$(stat -f%z /tmp/speed_test.ico 2>/dev/null || stat -c%s /tmp/speed_test.ico)
            local speed=$((size / duration / 1024))  # KB/s
            log_success "网络速度: ${speed}KB/s"
            rm -f /tmp/speed_test.ico
        fi
    else
        log_warning "网络速度测试失败"
    fi
}

# 生成诊断报告
generate_diagnosis_report() {
    local report_file="${1:-network-diagnosis-report.md}"

    log_info "生成诊断报告..."

    {
        echo "# 🌐 网络诊断报告"
        echo ""
        echo "**诊断时间**: $(date)"
        echo "**系统**: $(uname -a)"
        echo ""

        echo "## 📊 基本信息"
        echo "- **网络接口**: $(ip route show 2>/dev/null | grep default || echo '无法获取')"
        echo "- **DNS服务器**: $(cat /etc/resolv.conf 2>/dev/null | grep nameserver | head -1 || echo '无法获取')"
        echo ""

        echo "## 🔍 连接测试"
        echo ""

        # 测试各个服务
        local services=(
            "https://github.com|GitHub"
            "https://api.github.com|GitHub API"
            "https://www.google.com|Google"
            "https://registry.npmjs.org|NPM Registry"
        )

        for service in "${services[@]}"; do
            local url=$(echo "$service" | cut -d'|' -f1)
            local name=$(echo "$service" | cut -d'|' -f2)

            echo "### $name ($url)"
            if test_network_connectivity "$url" 15; then
                echo "✅ 连接正常"
            else
                echo "❌ 连接失败"
            fi
            echo ""
        done

        echo "## 💡 解决建议"
        echo ""
        echo "### 如果连接失败:"
        echo ""
        echo "1. **检查网络连接**"
        echo "   - 确认网络连接正常"
        echo "   - 检查防火墙设置"
        echo ""
        echo "2. **使用代理**"
        echo "   - 设置HTTP/HTTPS代理"
        echo "   - 配置Git代理: \`git config --global http.proxy http://proxy:port\`"
        echo ""
        echo "3. **DNS问题**"
        echo "   - 尝试更换DNS服务器"
        echo "   - 使用Google DNS: 8.8.8.8"
        echo ""
        echo "4. **VPN连接**"
        echo "   - 连接到可用的VPN"
        echo "   - 检查VPN设置"
        echo ""
        echo "**报告生成完成** ⏰ $(date)"

    } > "$report_file"

    log_success "诊断报告已生成: $report_file"
}

# 提供解决建议
provide_solutions() {
    log_info "提供解决建议..."

    echo ""
    echo "=== 🔧 解决建议 ==="
    echo ""

    echo "1. 检查网络连接:"
    echo "   ping -c 3 github.com"
    echo ""

    echo "2. 设置代理 (如果需要):"
    echo "   export http_proxy=http://proxy-server:port"
    echo "   export https_proxy=http://proxy-server:port"
    echo ""

    echo "3. 配置Git代理:"
    echo "   git config --global http.proxy http://proxy:port"
    echo "   git config --global https.proxy http://proxy:port"
    echo ""

    echo "4. 清除Git代理:"
    echo "   git config --global --unset http.proxy"
    echo "   git config --global --unset https.proxy"
    echo ""

    echo "5. 使用VPN:"
    echo "   - 连接到可用的VPN服务器"
    echo "   - 确认VPN正常工作"
    echo ""

    echo "6. 更换DNS:"
    echo "   # 编辑 /etc/resolv.conf"
    echo "   nameserver 8.8.8.8"
    echo "   nameserver 8.8.4.4"
    echo ""

    echo "7. 重新测试:"
    echo "   $0 --test-all"
    echo ""
}

# 显示帮助信息
show_help() {
    echo "Hexo 博客网络诊断脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -t, --test-all      完整网络测试"
    echo "  -c, --connectivity  测试连接性"
    echo "  -d, --dns           测试DNS解析"
    echo "  -g, --git           测试Git连接"
    echo "  -p, --proxy         检测代理设置"
    echo "  -s, --speed         测试网络速度"
    echo "  -r, --report        生成诊断报告"
    echo "  --solutions         显示解决建议"
    echo ""
    echo "示例:"
    echo "  $0 --test-all       # 完整诊断"
    echo "  $0 -c -d -g         # 测试连接、DNS、Git"
    echo "  $0 --report         # 生成报告"
}

# 主函数
main() {
    local test_all=false
    local connectivity=false
    local dns=false
    local git_test=false
    local proxy=false
    local speed=false
    local report=false
    local solutions=false

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
            -c|--connectivity)
                connectivity=true
                shift
                ;;
            -d|--dns)
                dns=true
                shift
                ;;
            -g|--git)
                git_test=true
                shift
                ;;
            -p|--proxy)
                proxy=true
                shift
                ;;
            -s|--speed)
                speed=true
                shift
                ;;
            -r|--report)
                report=true
                shift
                ;;
            --solutions)
                solutions=true
                shift
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 如果没有指定选项，显示帮助
    if [[ "$test_all" == "false" && "$connectivity" == "false" && "$dns" == "false" && "$git_test" == "false" && "$proxy" == "false" && "$speed" == "false" && "$report" == "false" && "$solutions" == "false" ]]; then
        show_help
        exit 0
    fi

    # 执行测试
    if [[ "$test_all" == "true" || "$connectivity" == "true" ]]; then
        log_info "=== 网络连接测试 ==="

        local targets=(
            "https://github.com"
            "https://api.github.com"
            "https://www.google.com"
            "https://registry.npmjs.org"
        )

        for target in "${targets[@]}"; do
            test_network_connectivity "$target"
        done

        echo ""
    fi

    if [[ "$test_all" == "true" || "$dns" == "true" ]]; then
        log_info "=== DNS解析测试 ==="

        local domains=(
            "github.com"
            "api.github.com"
            "google.com"
            "registry.npmjs.org"
        )

        for domain in "${domains[@]}"; do
            test_dns_resolution "$domain"
        done

        echo ""
    fi

    if [[ "$test_all" == "true" || "$git_test" == "true" ]]; then
        log_info "=== Git连接测试 ==="
        test_git_connection
        echo ""
    fi

    if [[ "$test_all" == "true" || "$proxy" == "true" ]]; then
        log_info "=== 代理检测 ==="
        detect_proxy
        echo ""
    fi

    if [[ "$test_all" == "true" || "$speed" == "true" ]]; then
        log_info "=== 网络速度测试 ==="
        test_network_speed
        echo ""
    fi

    if [[ "$report" == "true" ]]; then
        generate_diagnosis_report
    fi

    if [[ "$solutions" == "true" ]] || [[ "$test_all" == "true" ]]; then
        provide_solutions
    fi

    log_success "网络诊断完成！"
}

# 执行主函数
main "$@"
