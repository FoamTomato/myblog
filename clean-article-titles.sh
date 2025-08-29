#!/bin/bash

# 文章标题清理脚本
# 用于清理文章标题中的0.x.x版本号前缀

set -e

echo "🧹 文章标题清理工具"
echo "======================"

BLOG_DIR="/Users/foam/个人项目/blog/myblog"
POSTS_DIR="$BLOG_DIR/source/_posts"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 标题清理函数
clean_title() {
    local title="$1"

    # 去除0.x.x-前缀
    title=$(echo "$title" | sed 's/^0\.[0-9]\+\.[0-9]\+-//')

    # 去除0.x.x 前缀（没有连字符的情况）
    title=$(echo "$title" | sed 's/^0\.[0-9]\+\.[0-9]\+ //')

    # 清理多余的空格
    title=$(echo "$title" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    echo "$title"
}

# 处理单个文件
process_file() {
    local file="$1"
    local filename=$(basename "$file")

    log_info "处理文件: $filename"

    # 读取文件内容
    local content=""
    local in_front_matter=false
    local title_found=false
    local original_title=""
    local cleaned_title=""

    while IFS= read -r line; do
        # 检测front matter开始
        if [[ "$line" == "---" ]] && [[ "$in_front_matter" == false ]]; then
            in_front_matter=true
            content="$content$line"$'\n'
            continue
        fi

        # 检测front matter结束
        if [[ "$line" == "---" ]] && [[ "$in_front_matter" == true ]]; then
            in_front_matter=false
            content="$content$line"$'\n'
            continue
        fi

        # 处理title行
        if [[ "$in_front_matter" == true ]] && [[ "$line" =~ ^title: ]]; then
            title_found=true
            original_title=$(echo "$line" | sed 's/^title: *//; s/^"//; s/"$//')
            cleaned_title=$(clean_title "$original_title")

            if [[ "$original_title" != "$cleaned_title" ]]; then
                log_warn "标题需要清理: '$original_title' -> '$cleaned_title'"
                content="$content""title: \"$cleaned_title\""$'\n'
            else
                log_info "标题已经是干净的: '$original_title'"
                content="$content$line"$'\n'
            fi
            continue
        fi

        content="$content$line"$'\n'
    done < "$file"

    # 如果标题被修改，写回文件
    if [[ "$original_title" != "$cleaned_title" ]] && [[ -n "$cleaned_title" ]]; then
        echo "$content" > "$file"
        log_success "已更新文件: $filename"
        return 0
    else
        log_info "文件无需修改: $filename"
        return 1
    fi
}

# 统计信息
stats() {
    local total_files=$(find "$POSTS_DIR" -name "*.md" | wc -l)
    local processed_files=0
    local modified_files=0

    log_info "扫描目录: $POSTS_DIR"
    log_info "找到 $total_files 个Markdown文件"

    for file in "$POSTS_DIR"/*.md; do
        if [[ -f "$file" ]]; then
            ((processed_files++))
            if process_file "$file"; then
                ((modified_files++))
            fi
        fi
    done

    echo ""
    log_success "处理完成！"
    echo "总文件数: $total_files"
    echo "处理文件数: $processed_files"
    echo "修改文件数: $modified_files"
}

# 预览模式
preview() {
    log_info "预览模式 - 显示需要清理的标题"

    for file in "$POSTS_DIR"/*.md; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file")

            # 读取title行
            local title_line=$(grep "^title:" "$file" | head -1)
            if [[ -n "$title_line" ]]; then
                local original_title=$(echo "$title_line" | sed 's/^title: *//; s/^"//; s/"$//')
                local cleaned_title=$(clean_title "$original_title")

                if [[ "$original_title" != "$cleaned_title" ]]; then
                    echo "$filename:"
                    echo "  原始标题: '$original_title'"
                    echo "  清理后: '$cleaned_title'"
                    echo ""
                fi
            fi
        fi
    done
}

# 主函数
main() {
    cd "$BLOG_DIR"

    case "${1:-}" in
        "preview")
            preview
            ;;
        "stats")
            stats
            ;;
        *)
            log_info "开始清理文章标题..."
            echo ""
            stats
            ;;
    esac
}

# 执行主函数
main "$@"
