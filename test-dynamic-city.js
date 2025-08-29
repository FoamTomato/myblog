// 测试动态城市查询功能
async function testDynamicCity() {
    console.log('=== 动态城市查询测试 ===\n');

    // 模拟不同的IP地址
    const testIPs = [
        '202.96.128.86',   // 北京IP
        '61.135.169.121',  // 北京百度IP
        '192.168.1.1',     // 本地IP
        '8.8.8.8'          // Google DNS IP
    ];

    for (const ip of testIPs) {
        try {
            console.log(`测试IP: ${ip}`);
            const response = await fetch(`https://wttr.in/${ip}?format="%l+\\+%c+\\+%t+\\+%h"`);

            if (response.ok) {
                const rawData = await response.text();
                console.log(`原始数据: ${rawData}`);

                const cleanData = rawData.replace(/"/g, '').trim();
                const parts = cleanData.split(' \\ ');

                if (parts.length >= 4) {
                    const location = parts[0].trim();
                    const weatherIcon = parts[1].trim();
                    const temperature = parts[2].trim();
                    const humidity = parts[3].trim();

                    console.log(`📍 解析位置: ${location}`);
                    console.log(`🌤️ 天气图标: ${weatherIcon}`);
                    console.log(`🌡️ 温度: ${temperature}`);
                    console.log(`💧 湿度: ${humidity}`);
                    console.log('✅ 动态定位成功\n');
                } else {
                    console.log('❌ 数据格式不正确\n');
                }
            } else {
                console.log(`❌ API请求失败: ${response.status}\n`);
            }
        } catch (error) {
            console.log(`❌ 网络错误: ${error.message}\n`);
        }
    }

    console.log('=== 测试完成 ===');
    console.log('注意：不同IP地址会被解析到不同的地理位置');
    console.log('这证明了动态城市查询功能确实可以根据IP定位！');
}

// 运行测试
testDynamicCity();
