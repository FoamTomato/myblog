#!/bin/bash

# 测试天气API连接性
# 用于验证API Key是否有效

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 测试心知天气API
test_xinzhi_api() {
    local api_key="$1"

    if [[ -z "$api_key" ]]; then
        log_error "请提供心知天气API Key"
        return 1
    fi

    log_info "测试心知天气API..."

    local response=$(curl -s "https://api.seniverse.com/v3/weather/daily.json?key=$api_key&location=beijing&language=zh-Hans&unit=c&start=0&days=1")

    if [[ $? -ne 0 ]]; then
        log_error "网络连接失败"
        return 1
    fi

    # 检查API响应
    if echo "$response" | grep -q '"status":"OK"'; then
        log_success "心知天气API测试成功"
        echo "$response" | jq '.results[0].location.name' 2>/dev/null || echo "城市: 北京"
        echo "$response" | jq '.results[0].daily[0].text_day' 2>/dev/null || echo "天气: $(echo "$response" | grep -o '"text_day":"[^"]*"' | cut -d'"' -f4)"
        return 0
    elif echo "$response" | grep -q '"status":"The API key is invalid."'; then
        log_error "心知天气API Key无效"
        echo "请检查API Key是否正确"
        return 1
    else
        log_error "心知天气API响应异常"
        echo "响应: $response"
        return 1
    fi
}

# 测试和风天气API
test_heweather_api() {
    local api_key="$1"

    if [[ -z "$api_key" ]]; then
        log_error "请提供和风天气API Key"
        return 1
    fi

    log_info "测试和风天气API..."

    local response=$(curl -s "https://devapi.qweather.com/v7/weather/3d?location=101010100&key=$api_key")

    if [[ $? -ne 0 ]]; then
        log_error "网络连接失败"
        return 1
    fi

    if echo "$response" | grep -q '"code":"200"'; then
        log_success "和风天气API测试成功"
        return 0
    else
        log_error "和风天气API响应异常"
        echo "响应: $(echo "$response" | jq '.code' 2>/dev/null || echo "$response")"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    echo "天气API测试脚本"
    echo ""
    echo "用法:"
    echo "  $0 <api_name> <api_key>"
    echo ""
    echo "支持的API:"
    echo "  xinzhi <key>    测试心知天气API"
    echo "  heweather <key> 测试和风天气API"
    echo ""
    echo "示例:"
    echo "  $0 xinzhi YOUR_XINZHI_API_KEY"
    echo "  $0 heweather YOUR_HEWEATHER_API_KEY"
    echo ""
    echo "注意: 确保网络连接正常且API Key有效"
}

# 主函数
main() {
    local api_name="$1"
    local api_key="$2"

    case "$api_name" in
        "xinzhi")
            test_xinzhi_api "$api_key"
            ;;
        "heweather")
            test_heweather_api "$api_key"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# 执行主函数
main "$@"
