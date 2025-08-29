#!/bin/bash

# Hexo 博客部署配置文件
# 可以根据需要修改这些配置

# Git 配置
GIT_USER_NAME="${GIT_USER_NAME:-"GitHub Actions"}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-"action@github.com"}"

# 部署配置
DEPLOY_BRANCH="${DEPLOY_BRANCH:-gh-pages}"
SOURCE_BRANCH="${SOURCE_BRANCH:-main}"

# 域名配置（可选）
CNAME="${CNAME:-}"

# 构建配置
NODE_VERSION="${NODE_VERSION:-18}"
HEXO_VERSION="${HEXO_VERSION:-latest}"

# 缓存配置
ENABLE_CACHE="${ENABLE_CACHE:-true}"
CACHE_DIR="${CACHE_DIR:-.hexo_cache}"

# 通知配置
ENABLE_NOTIFICATION="${ENABLE_NOTIFICATION:-false}"
NOTIFICATION_WEBHOOK="${NOTIFICATION_WEBHOOK:-}"

# 自定义构建命令
PRE_BUILD_COMMAND="${PRE_BUILD_COMMAND:-}"
POST_BUILD_COMMAND="${POST_BUILD_COMMAND:-}"

# 排除的文件和目录
EXCLUDE_FILES="${EXCLUDE_FILES:-node_modules .git .github}"

# 部署目标
DEPLOY_TARGET="${DEPLOY_TARGET:-github}"  # github, gitlab, custom

# 自定义服务器配置（用于非GitHub Pages部署）
CUSTOM_SERVER_HOST="${CUSTOM_SERVER_HOST:-}"
CUSTOM_SERVER_USER="${CUSTOM_SERVER_USER:-}"
CUSTOM_SERVER_PATH="${CUSTOM_SERVER_PATH:-}"

# 性能优化
ENABLE_MINIFY="${ENABLE_MINIFY:-false}"
ENABLE_COMPRESS="${ENABLE_COMPRESS:-true}"

# 日志配置
LOG_LEVEL="${LOG_LEVEL:-info}"
LOG_FILE="${LOG_FILE:-deploy.log}"

# 备份配置
ENABLE_BACKUP="${ENABLE_BACKUP:-true}"
BACKUP_DIR="${BACKUP_DIR:-.backup}"
BACKUP_RETENTION="${BACKUP_RETENTION:-7}"  # 保留天数

# 函数：加载环境变量
load_env() {
    if [[ -f ".env" ]]; then
        export $(grep -v '^#' .env | xargs)
    fi

    if [[ -f ".env.local" ]]; then
        export $(grep -v '^#' .env.local | xargs)
    fi
}

# 函数：检查配置
check_config() {
    local required_vars=("GIT_USER_NAME" "GIT_USER_EMAIL")

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            echo "错误: 必需的配置变量 '$var' 未设置"
            exit 1
        fi
    done

    echo "配置检查通过"
}

# 函数：显示当前配置
show_config() {
    echo "=== 当前部署配置 ==="
    echo "Git 用户名: $GIT_USER_NAME"
    echo "Git 邮箱: $GIT_USER_EMAIL"
    echo "部署分支: $DEPLOY_BRANCH"
    echo "源分支: $SOURCE_BRANCH"
    echo "Node.js 版本: $NODE_VERSION"
    echo "启用缓存: $ENABLE_CACHE"
    echo "缓存目录: $CACHE_DIR"
    echo "域名: ${CNAME:-未设置}"
    echo "部署目标: $DEPLOY_TARGET"
    echo "日志级别: $LOG_LEVEL"
    echo "=================="
}

# 导出配置函数供其他脚本使用
export_config() {
    export GIT_USER_NAME
    export GIT_USER_EMAIL
    export DEPLOY_BRANCH
    export SOURCE_BRANCH
    export CNAME
    export NODE_VERSION
    export HEXO_VERSION
    export ENABLE_CACHE
    export CACHE_DIR
    export ENABLE_NOTIFICATION
    export NOTIFICATION_WEBHOOK
    export PRE_BUILD_COMMAND
    export POST_BUILD_COMMAND
    export EXCLUDE_FILES
    export DEPLOY_TARGET
    export CUSTOM_SERVER_HOST
    export CUSTOM_SERVER_USER
    export CUSTOM_SERVER_PATH
    export ENABLE_MINIFY
    export ENABLE_COMPRESS
    export LOG_LEVEL
    export LOG_FILE
    export ENABLE_BACKUP
    export BACKUP_DIR
    export BACKUP_RETENTION
}

# 主函数
main() {
    load_env
    check_config

    case "${1:-}" in
        "show")
            show_config
            ;;
        "export")
            export_config
            ;;
        *)
            echo "用法: $0 [show|export]"
            echo "  show   - 显示当前配置"
            echo "  export - 导出配置变量"
            ;;
    esac
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
