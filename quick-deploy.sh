#!/bin/bash

# 快速部署脚本 - 自动清理缓存并部署
# 解决Hexo部署时缓存不清理的问题

echo "🚀 开始快速部署流程..."
echo "====================================="

# 检查是否在正确的目录
if [[ ! -f "_config.yml" ]]; then
    echo "❌ 错误: 请在Hexo博客根目录下运行此脚本"
    exit 1
fi

echo "📋 当前目录: $(pwd)"
echo ""

# 步骤1: 清理缓存
echo "🧹 步骤1: 清理Hexo缓存..."
if hexo clean; then
    echo "✅ 缓存清理完成"
else
    echo "❌ 缓存清理失败"
    exit 1
fi

echo ""

# 步骤2: 生成静态文件
echo "🔨 步骤2: 生成静态文件..."
if hexo generate; then
    echo "✅ 静态文件生成完成"
else
    echo "❌ 静态文件生成失败"
    exit 1
fi

echo ""

# 步骤3: 部署到GitHub Pages
echo "🚀 步骤3: 部署到GitHub Pages..."
if hexo deploy; then
    echo "✅ 部署完成！"
    echo ""
    echo "🎉 部署成功！"
    echo "📱 访问你的博客: https://你的用户名.github.io"
else
    echo "❌ 部署失败"
    exit 1
fi

echo ""
echo "✅ 快速部署流程完成！"
echo "💡 提示: 以后可以直接运行 ./quick-deploy.sh 来自动清理缓存并部署"
