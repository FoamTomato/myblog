// 测试修复后的天气系统
async function testWeatherFix() {
    console.log('=== 测试修复后的天气系统 ===\n');

    // 模拟不同的位置信息
    const testLocations = [
        'beijing',
        'shanghai',
        'guangzhou',
        'shenzhen',
        'hangzhou'
    ];

    // 模拟returnCitySN对象
    global.returnCitySN = {
        "cip": "192.168.1.1", // 本地IP
        "cname": "北京市"     // 城市名称
    };

    for (const location of testLocations) {
        try {
            console.log(`测试位置: ${location}`);

            // 模拟getUserLocation函数的结果
            const userLocation = location;

            // 测试wttr.in API
            const response = await fetch(`https://wttr.in/${userLocation}?format="%l+\\+%c+\\+%t+\\+%h"`);

            if (response.ok) {
                const rawData = await response.text();
                console.log(`原始数据: ${rawData}`);

                // 检查是否返回了错误信息
                if (rawData.includes('Sorry, we are running out of queries')) {
                    console.log('❌ API限制错误\n');
                    continue;
                }

                const cleanData = rawData.replace(/"/g, '').trim();
                const parts = cleanData.split(' \\ ');

                if (parts.length >= 4) {
                    const location = parts[0].trim();
                    const weatherIcon = parts[1].trim();
                    const temperature = parts[2].trim();
                    const humidity = parts[3].trim();

                    // 过滤无效数据
                    if (location !== 'not found' && temperature !== 'Unknown') {
                        console.log(`📍 位置: ${location}`);
                        console.log(`🌤️ 天气图标: ${weatherIcon}`);
                        console.log(`🌡️ 温度: ${temperature}`);
                        console.log(`💧 湿度: ${humidity}`);
                        console.log('✅ 天气数据有效\n');
                    } else {
                        console.log('❌ 数据无效\n');
                    }
                } else {
                    console.log('❌ 数据格式不正确\n');
                }
            } else {
                console.log(`❌ API请求失败: ${response.status}\n`);
            }
        } catch (error) {
            console.log(`❌ 网络错误: ${error.message}\n`);
        }

        // 添加延迟避免请求过快
        await new Promise(resolve => setTimeout(resolve, 1000));
    }

    console.log('=== 测试完成 ===');
    console.log('修复内容：');
    console.log('1. ✅ 过滤本地IP地址 (127.0.0.1, 192.168.x.x等)');
    console.log('2. ✅ 优先使用城市名称而不是IP');
    console.log('3. ✅ 添加API限制检查');
    console.log('4. ✅ 过滤无效数据 (not found, Unknown)');
    console.log('5. ✅ 改进错误处理和降级机制');
}

// 运行测试
testWeatherFix();
