#!/bin/bash

# 修复wttr.in IP地址请求问题
# 问题: getWeatherDataForClock()函数中缺少await关键字
# 导致异步函数返回Promise对象而不是实际值

echo "🔧 修复wttr.in IP地址请求问题..."
echo "====================================="

# 检查文件是否存在
if [ ! -f "node_modules/hexo-electric-clock/clock.js" ]; then
    echo "❌ 错误: 找不到文件 node_modules/hexo-electric-clock/clock.js"
    echo "请确保时钟插件已正确安装"
    exit 1
fi

# 备份原文件
echo "📋 备份原文件..."
cp node_modules/hexo-electric-clock/clock.js node_modules/hexo-electric-clock/clock.js.backup

# 修复问题
echo "🔧 修复代码..."
sed -i 's/const userLocation = getUserLocation();/const userLocation = await getUserLocation();/' node_modules/hexo-electric-clock/clock.js

# 验证修复
if grep -q "const userLocation = await getUserLocation();" node_modules/hexo-electric-clock/clock.js; then
    echo "✅ 修复成功！"
    echo ""
    echo "📝 修复内容:"
    echo "  原代码: const userLocation = getUserLocation();"
    echo "  新代码: const userLocation = await getUserLocation();"
    echo ""
    echo "🎯 问题解决:"
    echo "  - 不再发送IP地址到wttr.in"
    echo "  - 正确获取城市名称"
    echo "  - 避免503 Service Unavailable错误"
    echo ""
    echo "🔄 下一步:"
    echo "  请刷新您的博客页面测试修复效果"
    echo "  如果仍有问题，请清理浏览器缓存后重试"
else
    echo "❌ 修复失败，恢复备份文件..."
    cp node_modules/hexo-electric-clock/clock.js.backup node_modules/hexo-electric-clock/clock.js
    exit 1
fi

echo ""
echo "📁 备份文件保存在: node_modules/hexo-electric-clock/clock.js.backup"
