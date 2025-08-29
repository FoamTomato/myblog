#!/bin/bash

# 检查整个项目是否还有wttr.in的使用
# 综合检查脚本

echo "🔍 全面检查wttr.in使用情况..."
echo "====================================="

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📁 项目目录: $PROJECT_DIR"
echo ""

# 1. 检查源代码文件
echo "1️⃣ 检查源代码文件..."
echo "   📄 JavaScript文件:"
find "$PROJECT_DIR" -name "*.js" -not -path "*/node_modules/*" -not -path "*/.git/*" -exec grep -l "wttr" {} \; 2>/dev/null || echo "   ✅ 无wttr引用"

echo "   📄 HTML文件:"
find "$PROJECT_DIR" -name "*.html" -not -path "*/node_modules/*" -not -path "*/.git/*" -exec grep -l "wttr" {} \; 2>/dev/null || echo "   ✅ 无wttr引用"

echo "   📄 配置文件:"
find "$PROJECT_DIR" -name "*.yml" -o -name "*.yaml" -o -name "*.json" -not -path "*/node_modules/*" -not -path "*/.git/*" | xargs grep -l "wttr" 2>/dev/null || echo "   ✅ 无wttr引用"

# 2. 检查生成的文件
echo ""
echo "2️⃣ 检查生成的文件 (public目录)..."
if [ -d "$PROJECT_DIR/public" ]; then
    echo "   📄 Public目录HTML文件:"
    find "$PROJECT_DIR/public" -name "*.html" -exec grep -l "wttr" {} \; 2>/dev/null || echo "   ✅ 无wttr引用"

    echo "   📄 Public目录JS文件:"
    find "$PROJECT_DIR/public" -name "*.js" -exec grep -l "wttr" {} \; 2>/dev/null || echo "   ✅ 无wttr引用"
else
    echo "   ⚠️  public目录不存在"
fi

# 3. 检查node_modules中的hexo-electric-clock插件
echo ""
echo "3️⃣ 检查时钟插件..."
if [ -f "$PROJECT_DIR/node_modules/hexo-electric-clock/clock.js" ]; then
    if grep -q "wttr" "$PROJECT_DIR/node_modules/hexo-electric-clock/clock.js"; then
        echo "   ❌ 发现wttr引用!"
        grep -n "wttr" "$PROJECT_DIR/node_modules/hexo-electric-clock/clock.js"
    else
        echo "   ✅ 时钟插件无wttr引用"
    fi
else
    echo "   ⚠️  时钟插件文件不存在"
fi

# 4. 检查浏览器缓存相关的设置
echo ""
echo "4️⃣ 检查localStorage设置..."
echo "   💡 请在浏览器中检查:"
echo "   • 打开博客首页"
echo "   • 按F12打开开发者工具"
echo "   • 在Console中执行: localStorage.getItem('useSeniverseWeather')"
echo "   • 确认返回: 'true' (表示使用心知天气)"

# 5. 检查网络请求
echo ""
echo "5️⃣ 网络请求检查..."
echo "   💡 请在浏览器中检查:"
echo "   • 打开博客首页"
echo "   • 按F12打开开发者工具"
echo "   • 切换到Network标签"
echo "   • 刷新页面"
echo "   • 检查是否有到wttr.in的请求"

# 6. 检查缓存文件
echo ""
echo "6️⃣ 检查缓存文件..."
if [ -f "$PROJECT_DIR/db.json" ]; then
    echo "   📄 db.json文件存在，大小: $(du -h "$PROJECT_DIR/db.json" | cut -f1)"
    echo "   💡 如果修改了文章内容，需要运行: hexo clean && hexo generate"
else
    echo "   ⚠️  db.json文件不存在"
fi

# 7. 总结和建议
echo ""
echo "📋 检查结果总结:"
echo "====================================="

# 统计wttr引用
WTTR_FILES=$(find "$PROJECT_DIR" -type f \( -name "*.js" -o -name "*.html" -o -name "*.md" \) -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/public/*" -exec grep -l "wttr" {} \; 2>/dev/null | wc -l)

if [ "$WTTR_FILES" -eq 0 ]; then
    echo "✅ 源代码中无wttr.in引用"
else
    echo "⚠️  发现 $WTTR_FILES 个文件包含wttr引用"
fi

echo ""
echo "🎯 推荐操作:"
echo "1. 清理浏览器缓存和localStorage"
echo "2. 运行: hexo clean && hexo generate && hexo deploy"
echo "3. 检查浏览器Network标签确认无wttr.in请求"
echo "4. 如果仍有问题，请提供浏览器控制台的错误信息"

echo ""
echo "🔧 快速修复命令:"
echo "• 清理并重新部署: ./quick-deploy.sh"
echo "• 只清理缓存: hexo clean"
echo "• 重新生成: hexo generate"

echo ""
echo "✅ 检查完成！"
