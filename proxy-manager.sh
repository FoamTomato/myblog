#!/bin/bash

# 代理管理脚本
# 用于管理Git代理设置，避免部署时出现连接问题

PROXY_HOST="127.0.0.1"
PROXY_PORT="7890"
HTTP_PROXY="http://${PROXY_HOST}:${PROXY_PORT}"
HTTPS_PROXY="http://${PROXY_HOST}:${PROXY_PORT}"

show_help() {
    echo "代理管理工具"
    echo "用法: $0 [命令]"
    echo ""
    echo "可用命令:"
    echo "  enable    启用代理"
    echo "  disable   禁用代理"
    echo "  status    查看代理状态"
    echo "  test      测试代理连接"
    echo "  help      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 enable   # 启用代理"
    echo "  $0 disable  # 禁用代理"
    echo "  $0 status   # 查看状态"
    echo "  $0 test     # 测试连接"
}

enable_proxy() {
    echo "启用Git代理..."
    git config --global http.proxy "$HTTP_PROXY"
    git config --global https.proxy "$HTTPS_PROXY"
    echo "✅ 代理已启用: $HTTP_PROXY"
}

disable_proxy() {
    echo "禁用Git代理..."
    git config --global --unset http.proxy
    git config --global --unset https.proxy
    echo "✅ 代理已禁用"
}

check_status() {
    echo "代理状态检查:"
    echo "===================="

    HTTP_PROXY_CONFIG=$(git config --global http.proxy)
    HTTPS_PROXY_CONFIG=$(git config --global https.proxy)

    if [ -n "$HTTP_PROXY_CONFIG" ] && [ -n "$HTTPS_PROXY_CONFIG" ]; then
        echo "✅ Git代理状态: 已启用"
        echo "   HTTP代理: $HTTP_PROXY_CONFIG"
        echo "   HTTPS代理: $HTTPS_PROXY_CONFIG"
    else
        echo "❌ Git代理状态: 已禁用"
    fi

    # 检查代理服务是否运行
    if nc -z "$PROXY_HOST" "$PROXY_PORT" 2>/dev/null; then
        echo "✅ 代理服务状态: 运行中 ($PROXY_HOST:$PROXY_PORT)"
    else
        echo "❌ 代理服务状态: 未运行 ($PROXY_HOST:$PROXY_PORT)"
        echo "   提示: 请确保代理软件正在运行"
    fi
}

test_connection() {
    echo "测试网络连接..."
    echo "===================="

    # 测试直连
    echo "测试直连GitHub..."
    if curl -s --connect-timeout 5 https://github.com > /dev/null; then
        echo "✅ 直连GitHub: 成功"
    else
        echo "❌ 直连GitHub: 失败"
    fi

    # 测试代理连接
    echo "测试代理连接GitHub..."
    if curl -s --connect-timeout 5 --proxy "$HTTP_PROXY" https://github.com > /dev/null; then
        echo "✅ 代理连接GitHub: 成功"
    else
        echo "❌ 代理连接GitHub: 失败"
    fi
}

case "${1:-help}" in
    "enable")
        enable_proxy
        ;;
    "disable")
        disable_proxy
        ;;
    "status")
        check_status
        ;;
    "test")
        test_connection
        ;;
    "help"|*)
        show_help
        ;;
esac
