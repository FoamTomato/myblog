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
echo "  1. 修复await关键字问题..."
sed -i 's/const userLocation = getUserLocation();/const userLocation = await getUserLocation();/' node_modules/hexo-electric-clock/clock.js

echo "  2. 修复wttr.in默认数据判断..."
sed -i "s/wttrResult.location !== '北京市'/wttrResult.location !== 'Unknown location'/" node_modules/hexo-electric-clock/clock.js

echo "  3. 修复默认城市名称..."
sed -i "s/location: '北京市'/location: '北京'/" node_modules/hexo-electric-clock/clock.js

# 验证修复
echo "🔍 验证修复结果..."
if grep -q "const userLocation = await getUserLocation();" node_modules/hexo-electric-clock/clock.js && \
   grep -q "location !== 'Unknown location'" node_modules/hexo-electric-clock/clock.js && \
   grep -q "location: '北京'" node_modules/hexo-electric-clock/clock.js; then
    echo "✅ 所有修复都成功应用！"
    echo ""
    echo "📝 修复内容:"
    echo "  1. await关键字修复:"
    echo "     原: const userLocation = getUserLocation();"
    echo "     新: const userLocation = await getUserLocation();"
    echo ""
    echo "  2. wttr.in数据判断修复:"
    echo "     原: wttrResult.location !== '北京市'"
    echo "     新: wttrResult.location !== 'Unknown location'"
    echo ""
    echo "  3. 默认城市名称修复:"
    echo "     原: location: '北京市'"
    echo "     新: location: '北京'"
    echo ""
    echo "🎯 解决的问题:"
    echo "  ✅ 不再发送IP地址到wttr.in (503错误)"
    echo "  ✅ 正确获取城市名称"
    echo "  ✅ 心知天气插件正常加载"
    echo "  ✅ wttr.in默认数据正确处理"
    echo ""
    echo "🔄 下一步:"
    echo "  1. 刷新您的博客页面测试修复效果"
    echo "  2. 检查浏览器控制台确认无错误"
    echo "  3. 验证天气显示是否正常"
    echo "  4. 如果仍有问题，请清理浏览器缓存后重试"
else
    echo "❌ 修复失败，恢复备份文件..."
    cp node_modules/hexo-electric-clock/clock.js.backup node_modules/hexo-electric-clock/clock.js
    echo "💡 建议: 请手动检查文件内容或重新运行脚本"
    exit 1
fi

echo ""
echo "📁 备份文件保存在: node_modules/hexo-electric-clock/clock.js.backup"
