#!/bin/bash

# SSH配置检查脚本
# 检查GitHub SSH密钥配置是否正确

set -e

echo "🔐 SSH配置检查脚本"
echo "==================="

BLOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查SSH密钥
check_ssh_keys() {
    log_info "🔑 检查SSH密钥..."

    local ssh_dir="$HOME/.ssh"
    local found_keys=false

    if [[ ! -d "$ssh_dir" ]]; then
        log_error "SSH目录不存在: $ssh_dir"
        return 1
    fi

    # 检查常见的SSH密钥文件
    local key_files=("id_rsa" "id_ed25519" "id_ecdsa" "id_dsa")

    for key_file in "${key_files[@]}"; do
        if [[ -f "$ssh_dir/$key_file" ]]; then
            log_success "找到SSH私钥: $key_file"
            found_keys=true

            # 检查对应的公钥
            if [[ -f "$ssh_dir/$key_file.pub" ]]; then
                log_success "找到SSH公钥: $key_file.pub"
            else
                log_warning "缺少公钥文件: $key_file.pub"
            fi
        fi
    done

    if [[ "$found_keys" == "false" ]]; then
        log_warning "未找到任何SSH密钥文件"
        return 1
    fi

    return 0
}

# 检查SSH Agent
check_ssh_agent() {
    log_info "👤 检查SSH Agent..."

    if [[ -n "$SSH_AGENT_PID" ]] && ps -p "$SSH_AGENT_PID" > /dev/null 2>&1; then
        log_success "SSH Agent正在运行 (PID: $SSH_AGENT_PID)"
        return 0
    else
        log_warning "SSH Agent未运行或未设置"
        return 1
    fi
}

# 检查SSH配置
check_ssh_config() {
    log_info "⚙️ 检查SSH配置..."

    local ssh_config="$HOME/.ssh/config"
    local github_config=false

    if [[ -f "$ssh_config" ]]; then
        if grep -q "Host github.com" "$ssh_config"; then
            log_success "找到GitHub SSH配置"
            github_config=true
        else
            log_info "未找到GitHub特定配置，使用默认设置"
        fi
    else
        log_info "未找到SSH配置文件，使用默认设置"
    fi

    return 0
}

# 测试GitHub连接
test_github_connection() {
    log_info "🌐 测试GitHub SSH连接..."

    # 使用timeout避免长时间等待
    if timeout 10 ssh -T git@github.com -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
        log_success "✅ GitHub SSH认证成功"
        return 0
    else
        log_error "❌ GitHub SSH认证失败"
        log_info "💡 请检查:"
        log_info "   1. SSH密钥是否已添加到GitHub账户"
        log_info "   2. SSH Agent是否正在运行"
        log_info "   3. 网络连接是否正常"
        return 1
    fi
}

# 显示配置建议
show_recommendations() {
    echo ""
    log_info "📋 配置建议:"

    if [[ "$ssh_keys_exist" == "false" ]]; then
        echo ""
        log_info "1. 生成SSH密钥:"
        echo "   ssh-keygen -t ed25519 -C 'your_email@example.com'"
        echo ""
        log_info "2. 添加公钥到GitHub:"
        echo "   cat ~/.ssh/id_ed25519.pub"
        echo "   复制输出内容到: https://github.com/settings/keys"
    fi

    if [[ "$ssh_agent_running" == "false" ]]; then
        echo ""
        log_info "启动SSH Agent:"
        echo "   eval \"\$(ssh-agent -s)\""
        echo "   ssh-add ~/.ssh/id_ed25519  # 或您的密钥文件"
    fi

    if [[ "$github_auth_success" == "false" ]]; then
        echo ""
        log_info "测试SSH连接:"
        echo "   ssh -T git@github.com"
        echo ""
        log_info "或者切换到HTTPS + Token模式:"
        echo "   ./setup-github-token.sh"
    fi
}

# 主函数
main() {
    local ssh_keys_exist=false
    local ssh_agent_running=false
    local github_auth_success=false

    log_info "开始检查SSH配置..."

    # 检查SSH密钥
    if check_ssh_keys; then
        ssh_keys_exist=true
    fi

    # 检查SSH Agent
    if check_ssh_agent; then
        ssh_agent_running=true
    fi

    # 检查SSH配置
    check_ssh_config

    # 测试GitHub连接
    if test_github_connection; then
        github_auth_success=true
    fi

    # 显示结果
    echo ""
    log_info "📊 检查结果:"

    if [[ "$ssh_keys_exist" == "true" ]]; then
        log_success "✅ SSH密钥: 已配置"
    else
        log_error "❌ SSH密钥: 未配置"
    fi

    if [[ "$ssh_agent_running" == "true" ]]; then
        log_success "✅ SSH Agent: 运行中"
    else
        log_warning "⚠️ SSH Agent: 未运行"
    fi

    if [[ "$github_auth_success" == "true" ]]; then
        log_success "✅ GitHub认证: 成功"
    else
        log_error "❌ GitHub认证: 失败"
    fi

    # 显示建议
    if [[ "$ssh_keys_exist" == "false" || "$ssh_agent_running" == "false" || "$github_auth_success" == "false" ]]; then
        show_recommendations
    else
        echo ""
        log_success "🎉 SSH配置检查通过！您可以使用SSH模式进行部署"
        echo ""
        log_info "现在可以运行:"
        echo "  ./deploy.sh --all          # 一键部署"
        echo "  hexo clean && hexo generate && hexo deploy  # 手动部署"
    fi
}

# 运行主函数
main "$@"
