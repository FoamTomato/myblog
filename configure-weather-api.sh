#!/bin/bash

# 天气API配置脚本
# 快速配置天气API Key

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

# HTML文件路径
HTML_FILE="doc/北京4天经典之旅 - 长城故宫胡同颐和园.html"

# 检查文件是否存在
check_file() {
    if [[ ! -f "$HTML_FILE" ]]; then
        log_error "找不到HTML文件: $HTML_FILE"
        echo "请确保在博客根目录下运行此脚本"
        exit 1
    fi
}

# 显示当前配置
show_current_config() {
    log_info "当前天气API配置:"

    echo ""
    echo "=== 📋 当前配置状态 ==="

    # 检查心知天气
    if grep -q "your_api_key_here" "$HTML_FILE"; then
        echo "❌ 心知天气: 未配置 (使用默认Key)"
    else
        echo "✅ 心知天气: 已配置"
    fi

    # 检查和风天气
    if grep -q "key: 'your_api_key_here'" "$HTML_FILE" | grep -q "heweather"; then
        echo "❌ 和风天气: 未配置 (使用默认Key)"
    else
        echo "✅ 和风天气: 已配置"
    fi

    # 检查OpenWeatherMap
    if grep -q "appid: 'your_api_key_here'" "$HTML_FILE"; then
        echo "❌ OpenWeatherMap: 未配置 (使用默认Key)"
    else
        echo "✅ OpenWeatherMap: 已配置"
    fi

    echo ""
}

# 配置心知天气API
configure_xinzhi() {
    local api_key="$1"

    if [[ -z "$api_key" ]]; then
        log_error "请提供心知天气API Key"
        echo "用法: $0 xinzhi YOUR_API_KEY"
        return 1
    fi

    log_info "配置心知天气API..."
    sed -i.bak "s/key: 'your_api_key_here'/key: '$api_key'/" "$HTML_FILE"
    sed -i.bak "s/key: 'PI6j51yJjLxq-GF9I'/key: '$api_key'/" "$HTML_FILE"

    if [[ $? -eq 0 ]]; then
        log_success "心知天气API配置成功 (Key: $api_key)"
    else
        log_error "心知天气API配置失败"
        return 1
    fi
}

# 配置和风天气API
configure_heweather() {
    local api_key="$1"

    if [[ -z "$api_key" ]]; then
        log_error "请提供和风天气API Key"
        echo "用法: $0 heweather YOUR_API_KEY"
        return 1
    fi

    log_info "配置和风天气API..."
    # 替换和风天气的key参数
    sed -i.bak "s/key: 'your_api_key_here' \/\/ 需要替换为实际的API Key/key: '$api_key' \/\/ 需要替换为实际的API Key/" "$HTML_FILE"

    if [[ $? -eq 0 ]]; then
        log_success "和风天气API配置成功"
    else
        log_error "和风天气API配置失败"
        return 1
    fi
}

# 配置OpenWeatherMap API
configure_openweather() {
    local api_key="$1"

    if [[ -z "$api_key" ]]; then
        log_error "请提供OpenWeatherMap API Key"
        echo "用法: $0 openweather YOUR_API_KEY"
        return 1
    fi

    log_info "配置OpenWeatherMap API..."
    sed -i.bak "s/appid: 'your_api_key_here'/appid: '$api_key'/" "$HTML_FILE"

    if [[ $? -eq 0 ]]; then
        log_success "OpenWeatherMap API配置成功"
    else
        log_error "OpenWeatherMap API配置失败"
        return 1
    fi
}

# 配置聚合数据API
configure_juhe() {
    local api_key="$1"

    if [[ -z "$api_key" ]]; then
        log_error "请提供聚合数据API Key"
        echo "用法: $0 juhe YOUR_API_KEY"
        return 1
    fi

    log_info "配置聚合数据API..."
    sed -i.bak "s/key: 'your_api_key_here' \/\/ 需要替换为实际的API Key/key: '$api_key' \/\/ 需要替换为实际的API Key/" "$HTML_FILE"

    if [[ $? -eq 0 ]]; then
        log_success "聚合数据API配置成功"
    else
        log_error "聚合数据API配置失败"
        return 1
    fi
}

# 批量配置所有API
configure_all() {
    log_info "批量配置所有天气API..."

    echo "请输入各个平台的API Key (留空则跳过):"
    echo ""

    # 心知天气
    read -p "心知天气 API Key: " xinzhi_key
    if [[ -n "$xinzhi_key" ]]; then
        configure_xinzhi "$xinzhi_key"
    fi

    # 和风天气
    read -p "和风天气 API Key: " heweather_key
    if [[ -n "$heweather_key" ]]; then
        configure_heweather "$heweather_key"
    fi

    # OpenWeatherMap
    read -p "OpenWeatherMap API Key: " openweather_key
    if [[ -n "$openweather_key" ]]; then
        configure_openweather "$openweather_key"
    fi

    # 聚合数据
    read -p "聚合数据 API Key: " juhe_key
    if [[ -n "$juhe_key" ]]; then
        configure_juhe "$juhe_key"
    fi

    log_success "批量配置完成！"
}

# 创建备份
create_backup() {
    local backup_file="${HTML_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$HTML_FILE" "$backup_file"
    log_info "已创建备份: $backup_file"
}

# 显示帮助信息
show_help() {
    echo "天气API配置脚本"
    echo ""
    echo "用法:"
    echo "  $0 <command> [api_key]"
    echo ""
    echo "命令:"
    echo "  status          显示当前配置状态"
    echo "  xinzhi <key>    配置心知天气API"
    echo "  heweather <key> 配置和风天气API"
    echo "  openweather <key> 配置OpenWeatherMap API"
    echo "  juhe <key>      配置聚合数据API"
    echo "  all             批量配置所有API"
    echo "  backup          创建配置备份"
    echo "  help            显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 status"
    echo "  $0 xinzhi YOUR_XINZHI_API_KEY"
    echo "  $0 all"
    echo ""
    echo "注意: 配置前会自动创建备份文件"
}

# 主函数
main() {
    local command="$1"
    shift

    # 检查文件
    check_file

    # 创建备份
    if [[ "$command" != "status" && "$command" != "help" && "$command" != "backup" ]]; then
        create_backup
    fi

    case "$command" in
        "status")
            show_current_config
            ;;
        "xinzhi")
            configure_xinzhi "$1"
            ;;
        "heweather")
            configure_heweather "$1"
            ;;
        "openweather")
            configure_openweather "$1"
            ;;
        "juhe")
            configure_juhe "$1"
            ;;
        "all")
            configure_all
            ;;
        "backup")
            create_backup
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# 执行主函数
main "$@"
