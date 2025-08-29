#!/bin/bash

# Hexo 博客部署监控脚本
# 用于监控部署状态、性能指标和健康检查

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

# 检查GitHub Pages状态
check_github_pages_status() {
    local repo_owner="$1"
    local repo_name="$2"

    if [[ -z "$repo_owner" ]] || [[ -z "$repo_name" ]]; then
        log_error "需要提供仓库所有者和仓库名"
        return 1
    fi

    log_info "检查GitHub Pages状态..."

    local api_url="https://api.github.com/repos/$repo_owner/$repo_name/pages"
    local response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$api_url")

    if [[ $? -ne 0 ]]; then
        log_error "无法访问GitHub API"
        return 1
    fi

    local status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    local url=$(echo "$response" | grep -o '"html_url":"[^"]*"' | cut -d'"' -f4)

    echo "GitHub Pages状态: $status"
    echo "访问地址: $url"

    case "$status" in
        "building")
            log_info "页面正在构建中..."
            return 0
            ;;
        "ready")
            log_success "GitHub Pages 部署成功 ✓"
            return 0
            ;;
        "error")
            log_error "GitHub Pages 部署失败"
            return 1
            ;;
        *)
            log_warning "未知状态: $status"
            return 1
            ;;
    esac
}

# 检查网站可访问性
check_website_accessibility() {
    local url="$1"
    local timeout="${2:-30}"

    if [[ -z "$url" ]]; then
        log_error "需要提供网站URL"
        return 1
    fi

    log_info "检查网站可访问性: $url"

    # 检查HTTP状态码
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url")

    if [[ "$http_code" -eq 200 ]]; then
        log_success "网站可正常访问 (HTTP $http_code) ✓"

        # 检查响应时间
        local response_time=$(curl -s -o /dev/null -w "%{time_total}" "$url")
        echo "响应时间: ${response_time}s"

        if (( $(echo "$response_time < 2.0" | bc -l) )); then
            log_success "响应时间正常 ✓"
        else
            log_warning "响应时间较慢: ${response_time}s"
        fi

        return 0
    else
        log_error "网站访问失败 (HTTP $http_code)"
        return 1
    fi
}

# 分析网站性能
analyze_website_performance() {
    local url="$1"

    if [[ -z "$url" ]]; then
        log_error "需要提供网站URL"
        return 1
    fi

    log_info "分析网站性能..."

    # 使用curl获取详细性能信息
    local perf_data=$(curl -s -w "@curl-format.txt" -o /dev/null "$url" 2>/dev/null)

    if [[ -n "$perf_data" ]]; then
        echo "=== 性能分析报告 ==="
        echo "$perf_data"
        echo "=================="
    fi

    # 检查页面大小
    local page_size=$(curl -s "$url" | wc -c)
    local page_size_mb=$(echo "scale=2; $page_size / 1024 / 1024" | bc)

    echo "页面大小: ${page_size_mb}MB"

    if (( $(echo "$page_size_mb < 5.0" | bc -l) )); then
        log_success "页面大小正常 ✓"
    else
        log_warning "页面较大: ${page_size_mb}MB，建议优化"
    fi
}

# 监控部署状态
monitor_deployment() {
    local repo_owner="$1"
    local repo_name="$2"
    local check_interval="${3:-60}"
    local max_checks="${4:-10}"

    if [[ -z "$repo_owner" ]] || [[ -z "$repo_name" ]]; then
        log_error "需要提供仓库所有者和仓库名"
        exit 1
    fi

    log_info "开始监控部署状态..."
    log_info "检查间隔: ${check_interval}秒"
    log_info "最大检查次数: $max_checks"

    local check_count=0
    local deploy_url=""

    while [[ $check_count -lt $max_checks ]]; do
        ((check_count++))

        log_info "第 $check_count 次检查..."

        # 检查GitHub Pages状态
        if check_github_pages_status "$repo_owner" "$repo_name"; then
            # 获取部署URL
            local api_response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                "https://api.github.com/repos/$repo_owner/$repo_name/pages")

            deploy_url=$(echo "$api_response" | grep -o '"html_url":"[^"]*"' | cut -d'"' -f4)

            if [[ -n "$deploy_url" ]]; then
                log_success "部署完成！访问地址: $deploy_url"

                # 检查网站可访问性
                sleep 10  # 等待DNS生效
                if check_website_accessibility "$deploy_url" 30; then
                    log_success "网站部署成功！🎉"
                    return 0
                else
                    log_warning "网站暂时无法访问，可能是DNS缓存问题"
                    return 0
                fi
            fi
        else
            if [[ $check_count -lt $max_checks ]]; then
                log_info "等待 ${check_interval} 秒后重新检查..."
                sleep "$check_interval"
            fi
        fi
    done

    log_error "部署监控超时，未能确认部署成功"
    return 1
}

# 生成健康检查报告
generate_health_report() {
    local url="$1"
    local output_file="${2:-health-report.md}"

    if [[ -z "$url" ]]; then
        log_error "需要提供网站URL"
        return 1
    fi

    log_info "生成健康检查报告..."

    {
        echo "# 📊 网站健康检查报告"
        echo ""
        echo "**检查时间**: $(date)"
        echo "**网站地址**: $url"
        echo ""

        # 检查网站可访问性
        echo "## 🌐 可访问性检查"
        if check_website_accessibility "$url" 30; then
            echo "✅ 网站可正常访问"
        else
            echo "❌ 网站访问异常"
        fi
        echo ""

        # 性能分析
        echo "## ⚡ 性能分析"
        analyze_website_performance "$url"
        echo ""

        # SEO检查
        echo "## 🔍 SEO 检查"
        local title=$(curl -s "$url" | grep -o '<title>[^<]*</title>' | sed 's/<title>\(.*\)<\/title>/\1/')
        if [[ -n "$title" ]]; then
            echo "✅ 页面标题: $title"
        else
            echo "⚠️  未找到页面标题"
        fi

        local meta_desc=$(curl -s "$url" | grep -o '<meta name="description" content="[^"]*"' | sed 's/.*content="\([^"]*\)".*/\1/')
        if [[ -n "$meta_desc" ]]; then
            echo "✅ 页面描述: $meta_desc"
        else
            echo "⚠️  未找到页面描述"
        fi
        echo ""

        # 链接检查
        echo "## 🔗 链接检查"
        local broken_links=$(curl -s "$url" | grep -o 'href="[^"]*"' | sed 's/href="\([^"]*\)"/\1/' | head -10)
        echo "发现的链接数量: $(echo "$broken_links" | wc -l)"
        echo ""

        echo "**报告生成完成** ⏰ $(date)"

    } > "$output_file"

    log_success "健康检查报告已生成: $output_file"
}

# 显示帮助信息
show_help() {
    echo "Hexo 博客部署监控脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help              显示帮助信息"
    echo "  -u, --url <url>         网站URL"
    echo "  -r, --repo <owner/name> GitHub仓库 (格式: owner/repo)"
    echo "  -m, --monitor           监控部署状态"
    echo "  -i, --interval <秒>     检查间隔时间 (默认: 60)"
    echo "  -c, --count <次数>      最大检查次数 (默认: 10)"
    echo "  -p, --performance       性能分析"
    echo "  -s, --status            检查网站状态"
    echo "  -o, --output <文件>     输出文件路径"
    echo ""
    echo "环境变量:"
    echo "  GITHUB_TOKEN           GitHub API Token"
    echo ""
    echo "示例:"
    echo "  $0 -u https://username.github.io/repo -s"
    echo "  $0 -r username/repo -m -i 30"
    echo "  $0 -u https://example.com -p -o report.md"
}

# 主函数
main() {
    local url=""
    local repo=""
    local monitor=false
    local interval=60
    local max_checks=10
    local performance=false
    local status_check=false
    local output_file=""

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -u|--url)
                url="$2"
                shift 2
                ;;
            -r|--repo)
                repo="$2"
                shift 2
                ;;
            -m|--monitor)
                monitor=true
                shift
                ;;
            -i|--interval)
                interval="$2"
                shift 2
                ;;
            -c|--count)
                max_checks="$2"
                shift 2
                ;;
            -p|--performance)
                performance=true
                shift
                ;;
            -s|--status)
                status_check=true
                shift
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 执行各项任务
    if [[ "$monitor" == "true" ]]; then
        if [[ -z "$repo" ]]; then
            log_error "监控模式需要指定仓库 (-r owner/repo)"
            exit 1
        fi

        local repo_owner=$(echo "$repo" | cut -d'/' -f1)
        local repo_name=$(echo "$repo" | cut -d'/' -f2)

        monitor_deployment "$repo_owner" "$repo_name" "$interval" "$max_checks"

    elif [[ "$status_check" == "true" ]]; then
        if [[ -z "$url" ]]; then
            log_error "状态检查需要指定URL (-u url)"
            exit 1
        fi

        check_website_accessibility "$url"

    elif [[ "$performance" == "true" ]]; then
        if [[ -z "$url" ]]; then
            log_error "性能分析需要指定URL (-u url)"
            exit 1
        fi

        analyze_website_performance "$url"

        # 生成完整报告
        if [[ -n "$output_file" ]]; then
            generate_health_report "$url" "$output_file"
        fi

    else
        # 默认行为：显示帮助
        show_help
    fi
}

# 创建curl格式文件（如果不存在）
create_curl_format() {
    if [[ ! -f "curl-format.txt" ]]; then
        cat > curl-format.txt << 'EOF'
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
EOF
    fi
}

# 初始化
create_curl_format

# 执行主函数
main "$@"
