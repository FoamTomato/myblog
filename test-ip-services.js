// 测试IP定位服务功能
async function testIPServices() {
    console.log('=== 测试IP定位服务 ===\n');

    // 测试IP列表（包含更多中国主要城市的IP）
    const testIPs = [
        '202.96.128.86',    // 北京联通IP (应解析为北京)
        '61.135.169.125',   // 北京百度IP (应解析为北京)
        '211.136.0.1',      // 上海电信IP (应解析为上海)
        '58.247.0.1',       // 上海移动IP (应解析为上海)
        '113.108.0.1',      // 广州电信IP (应解析为广州)
        '183.232.0.1',      // 深圳移动IP (应解析为深圳)
        '220.181.0.1',      // 杭州阿里云IP (应解析为杭州)
        '8.8.8.8',          // Google DNS (美国)
        '1.1.1.1'           // Cloudflare (美国)
    ];

    // 模拟getCityFromIP函数（支持区级定位）
    async function getCityFromIP(ip) {
        const ipServices = [
            {
                name: 'ipapi.co',
                url: `https://ipapi.co/${ip}/json/`,
                parseCity: (data) => {
                    if (data.city && data.country_code === 'CN') {
                        // 优先使用区级信息，如果没有则使用城市
                        const location = data.region || data.city;

                        // 中文城市和区县映射（精确到区）
                        const locationMapping = {
                            // 北京
                            'Beijing': 'beijing',
                            'Chaoyang District': 'beijing/chaoyang',
                            'Haidian District': 'beijing/haidian',
                            'Xicheng District': 'beijing/xicheng',
                            'Dongcheng District': 'beijing/dongcheng',
                            'Fengtai District': 'beijing/fengtai',
                            'Shijingshan District': 'beijing/shijingshan',
                            'Tongzhou District': 'beijing/tongzhou',
                            'Daxing District': 'beijing/daxing',
                            'Fangshan District': 'beijing/fangshan',
                            'Mentougou District': 'beijing/mentougou',
                            'Huairou District': 'beijing/huairou',
                            'Miyun District': 'beijing/miyun',
                            'Yanqing District': 'beijing/yanqing',

                            // 上海
                            'Shanghai': 'shanghai',
                            'Huangpu District': 'shanghai/huangpu',
                            'Xuhui District': 'shanghai/xuhui',
                            'Changning District': 'shanghai/changning',
                            'Jing\'an District': 'shanghai/jingan',
                            'Putuo District': 'shanghai/putuo',
                            'Hongkou District': 'shanghai/hongkou',
                            'Yangpu District': 'shanghai/yangpu',
                            'Minhang District': 'shanghai/minhang',
                            'Baoshan District': 'shanghai/baoshan',
                            'Jiading District': 'shanghai/jiading',
                            'Pudong New Area': 'shanghai/pudong',
                            'Jinshan District': 'shanghai/jinshan',
                            'Songjiang District': 'shanghai/songjiang',
                            'Qingpu District': 'shanghai/qingpu',
                            'Fengxian District': 'shanghai/fengxian',
                            'Chongming District': 'shanghai/chongming',

                            // 广州
                            'Guangzhou': 'guangzhou',
                            'Tianhe District': 'guangzhou/tianhe',
                            'Yuexiu District': 'guangzhou/yuexiu',
                            'Haizhu District': 'guangzhou/haizhu',
                            'Panyu District': 'guangzhou/panyu',
                            'Huadu District': 'guangzhou/huadu',
                            'Baiyun District': 'guangzhou/baiyun',
                            'Huangpu District': 'guangzhou/huangpu',
                            'Nansha District': 'guangzhou/nansha',
                            'Liwan District': 'guangzhou/liwan',

                            // 深圳
                            'Shenzhen': 'shenzhen',
                            'Futian District': 'shenzhen/futian',
                            'Luohu District': 'shenzhen/luohu',
                            'Nanshan District': 'shenzhen/nanshan',
                            'Yantian District': 'shenzhen/yantian',
                            'Bao\'an District': 'shenzhen/baoan',
                            'Longgang District': 'shenzhen/longgang',
                            'Longhua District': 'shenzhen/longhua',
                            'Guangming District': 'shenzhen/guangming',
                            'Pingshan District': 'shenzhen/pingshan',

                            // 杭州
                            'Hangzhou': 'hangzhou',
                            'Shangcheng District': 'hangzhou/shangcheng',
                            'Xiacheng District': 'hangzhou/xiacheng',
                            'Gongshu District': 'hangzhou/gongshu',
                            'Jianggan District': 'hangzhou/jianggan',
                            'Binjiang District': 'hangzhou/binjiang',
                            'Yuhang District': 'hangzhou/yuhang',
                            'Fuyang District': 'hangzhou/fuyang',
                            'Linping District': 'hangzhou/linping',
                            'Xiaoshan District': 'hangzhou/xiaoshan',

                            // 其他主要城市
                            'Nanjing': 'nanjing',
                            'Suzhou': 'suzhou',
                            'Tianjin': 'tianjin',
                            'Chongqing': 'chongqing',
                            'Chengdu': 'chengdu',
                            'Wuhan': 'wuhan',
                            'Xian': 'xian',
                            'Changsha': 'changsha',
                            'Shenyang': 'shenyang',
                            'Qingdao': 'qingdao',
                            'Dalian': 'dalian',
                            'Xiamen': 'xiamen',
                            'Fuzhou': 'fuzhou',
                            'Jinan': 'jinan',
                            'Zhengzhou': 'zhengzhou'
                        };

                        // 尝试精确匹配区县，如果没有则使用城市
                        const exactMatch = locationMapping[location];
                        if (exactMatch) {
                            return exactMatch;
                        }

                        // 如果没有精确匹配，尝试城市匹配
                        const cityMapping = {
                            'Beijing': 'beijing',
                            'Shanghai': 'shanghai',
                            'Guangzhou': 'guangzhou',
                            'Shenzhen': 'shenzhen',
                            'Hangzhou': 'hangzhou',
                            'Nanjing': 'nanjing',
                            'Suzhou': 'suzhou',
                            'Tianjin': 'tianjin',
                            'Chongqing': 'chongqing',
                            'Chengdu': 'chengdu',
                            'Wuhan': 'wuhan',
                            'Xian': 'xian',
                            'Changsha': 'changsha',
                            'Shenyang': 'shenyang',
                            'Qingdao': 'qingdao',
                            'Dalian': 'dalian',
                            'Xiamen': 'xiamen',
                            'Fuzhou': 'fuzhou',
                            'Jinan': 'jinan',
                            'Zhengzhou': 'zhengzhou'
                        };
                        return cityMapping[data.city] || data.city.toLowerCase();
                    }
                    return null;
                }
            },
            {
                name: 'ip-api.com',
                url: `http://ip-api.com/json/${ip}`,
                parseCity: (data) => {
                    if (data.status === 'success' && data.countryCode === 'CN' && data.city) {
                        // 优先使用区级信息，如果没有则使用城市
                        const location = data.district || data.city;

                        // 中文城市和区县映射（精确到区）
                        const locationMapping = {
                            // 北京
                            'Beijing': 'beijing',
                            'Chaoyang': 'beijing/chaoyang',
                            'Haidian': 'beijing/haidian',
                            'Xicheng': 'beijing/xicheng',
                            'Dongcheng': 'beijing/dongcheng',
                            'Fengtai': 'beijing/fengtai',
                            'Shijingshan': 'beijing/shijingshan',
                            'Tongzhou': 'beijing/tongzhou',
                            'Daxing': 'beijing/daxing',
                            'Fangshan': 'beijing/fangshan',
                            'Mentougou': 'beijing/mentougou',
                            'Huairou': 'beijing/huairou',
                            'Miyun': 'beijing/miyun',
                            'Yanqing': 'beijing/yanqing',

                            // 上海
                            'Shanghai': 'shanghai',
                            'Huangpu': 'shanghai/huangpu',
                            'Xuhui': 'shanghai/xuhui',
                            'Changning': 'shanghai/changning',
                            'Jing\'an': 'shanghai/jingan',
                            'Putuo': 'shanghai/putuo',
                            'Hongkou': 'shanghai/hongkou',
                            'Yangpu': 'shanghai/yangpu',
                            'Minhang': 'shanghai/minhang',
                            'Baoshan': 'shanghai/baoshan',
                            'Jiading': 'shanghai/jiading',
                            'Pudong': 'shanghai/pudong',
                            'Jinshan': 'shanghai/jinshan',
                            'Songjiang': 'shanghai/songjiang',
                            'Qingpu': 'shanghai/qingpu',
                            'Fengxian': 'shanghai/fengxian',
                            'Chongming': 'shanghai/chongming',

                            // 广州
                            'Guangzhou': 'guangzhou',
                            'Tianhe': 'guangzhou/tianhe',
                            'Yuexiu': 'guangzhou/yuexiu',
                            'Haizhu': 'guangzhou/haizhu',
                            'Panyu': 'guangzhou/panyu',
                            'Huadu': 'guangzhou/huadu',
                            'Baiyun': 'guangzhou/baiyun',
                            'Huangpu': 'guangzhou/huangpu',
                            'Nansha': 'guangzhou/nansha',
                            'Liwan': 'guangzhou/liwan',

                            // 深圳
                            'Shenzhen': 'shenzhen',
                            'Futian': 'shenzhen/futian',
                            'Luohu': 'shenzhen/luohu',
                            'Nanshan': 'shenzhen/nanshan',
                            'Yantian': 'shenzhen/yantian',
                            'Bao\'an': 'shenzhen/baoan',
                            'Longgang': 'shenzhen/longgang',
                            'Longhua': 'shenzhen/longhua',
                            'Guangming': 'shenzhen/guangming',
                            'Pingshan': 'shenzhen/pingshan',

                            // 杭州
                            'Hangzhou': 'hangzhou',
                            'Shangcheng': 'hangzhou/shangcheng',
                            'Xiacheng': 'hangzhou/xiacheng',
                            'Gongshu': 'hangzhou/gongshu',
                            'Jianggan': 'hangzhou/jianggan',
                            'Binjiang': 'hangzhou/binjiang',
                            'Yuhang': 'hangzhou/yuhang',
                            'Fuyang': 'hangzhou/fuyang',
                            'Linping': 'hangzhou/linping',
                            'Xiaoshan': 'hangzhou/xiaoshan',

                            // 其他主要城市
                            'Nanjing': 'nanjing',
                            'Suzhou': 'suzhou',
                            'Tianjin': 'tianjin',
                            'Chongqing': 'chongqing',
                            'Chengdu': 'chengdu',
                            'Wuhan': 'wuhan',
                            'Xi\'an': 'xian',
                            'Changsha': 'changsha',
                            'Shenyang': 'shenyang',
                            'Qingdao': 'qingdao',
                            'Dalian': 'dalian',
                            'Xiamen': 'xiamen',
                            'Fuzhou': 'fuzhou',
                            'Jinan': 'jinan',
                            'Zhengzhou': 'zhengzhou'
                        };

                        // 尝试精确匹配区县，如果没有则使用城市
                        const exactMatch = locationMapping[location];
                        if (exactMatch) {
                            return exactMatch;
                        }

                        // 如果没有精确匹配，尝试城市匹配
                        const cityMapping = {
                            'Beijing': 'beijing',
                            'Shanghai': 'shanghai',
                            'Guangzhou': 'guangzhou',
                            'Shenzhen': 'shenzhen',
                            'Hangzhou': 'hangzhou',
                            'Nanjing': 'nanjing',
                            'Suzhou': 'suzhou',
                            'Tianjin': 'tianjin',
                            'Chongqing': 'chongqing',
                            'Chengdu': 'chengdu',
                            'Wuhan': 'wuhan',
                            'Xi\'an': 'xian',
                            'Changsha': 'changsha',
                            'Shenyang': 'shenyang',
                            'Qingdao': 'qingdao',
                            'Dalian': 'dalian',
                            'Xiamen': 'xiamen',
                            'Fuzhou': 'fuzhou',
                            'Jinan': 'jinan',
                            'Zhengzhou': 'zhengzhou'
                        };
                        return cityMapping[data.city] || data.city.toLowerCase();
                    }
                    return null;
                }
            }
        ];

        for (const service of ipServices) {
            try {
                console.log(`  尝试 ${service.name}...`);
                const response = await fetch(service.url);

                if (response.ok) {
                    const data = await response.json();
                    const city = service.parseCity(data);

                    if (city) {
                        console.log(`  ✅ ${service.name} 成功: ${city}`);
                        return city;
                    } else {
                        console.log(`  ⚠️  ${service.name} 返回数据无效`);
                    }
                } else {
                    console.log(`  ❌ ${service.name} 请求失败: ${response.status}`);
                }
            } catch (error) {
                console.warn(`  ❌ ${service.name} 错误:`, error.message);
            }

            // 短暂延迟
            await new Promise(resolve => setTimeout(resolve, 500));
        }

        return null;
    }

    // 测试每个IP
    for (const ip of testIPs) {
        console.log(`测试IP: ${ip}`);
        try {
            const city = await getCityFromIP(ip);
            if (city) {
                console.log(`✅ 解析成功: ${city}\n`);
            } else {
                console.log(`❌ 解析失败\n`);
            }
        } catch (error) {
            console.log(`❌ 测试错误: ${error.message}\n`);
        }

        // IP之间延迟
        await new Promise(resolve => setTimeout(resolve, 1000));
    }

    console.log('=== 测试完成 ===');
}

// 运行测试
testIPServices();

// 额外测试区级定位功能
async function testDistrictLevel() {
    console.log('\n=== 区级定位测试 ===');

    // 测试一些可能返回区级信息的IP
    const districtTestIPs = [
        '114.247.50.1',     // 北京联通 (可能返回朝阳区等)
        '101.89.0.1',       // 上海电信 (可能返回浦东新区等)
        '183.60.0.1',       // 广州移动 (可能返回天河区等)
        '119.147.0.1'       // 深圳电信 (可能返回南山区等)
    ];

    console.log('注意: 区级定位需要IP服务提供区级信息，不是所有IP都能解析到区级');
    console.log('如果只返回城市级信息，说明该IP的定位服务没有提供区级数据');

    for (const ip of districtTestIPs) {
        console.log(`\n测试IP: ${ip}`);
        try {
            const location = await getCityFromIP(ip);
            if (location) {
                console.log(`✅ 解析成功: ${location}`);
                if (location.includes('/')) {
                    console.log(`🎯 成功获取区级定位: ${location}`);
                } else {
                    console.log(`📍 获取城市级定位: ${location}`);
                }
            } else {
                console.log(`❌ 解析失败`);
            }
        } catch (error) {
            console.log(`❌ 测试错误: ${error.message}`);
        }

        // 延迟避免请求过快
        await new Promise(resolve => setTimeout(resolve, 1500));
    }

    console.log('\n=== 区级定位测试完成 ===');
}

// 运行区级定位测试
testDistrictLevel();
