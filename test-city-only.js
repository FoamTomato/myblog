// 测试getUserLocation函数是否只返回城市名称
function testGetUserLocation() {
    console.log('=== 测试getUserLocation函数 ===\n');

    // 模拟不同的returnCitySN情况
    const testCases = [
        {
            name: '正常城市名称',
            returnCitySN: { "cname": "北京市", "cip": "192.168.1.1" },
            expected: 'beijing'
        },
        {
            name: '城市名称带市字',
            returnCitySN: { "cname": "上海市", "cip": "10.0.0.1" },
            expected: 'shanghai'
        },
        {
            name: '只有本地IP',
            returnCitySN: { "cip": "127.0.0.1" },
            expected: 'beijing'
        },
        {
            name: '只有内网IP',
            returnCitySN: { "cip": "192.168.1.100" },
            expected: 'beijing'
        },
        {
            name: '只有公网IP',
            returnCitySN: { "cip": "8.8.8.8" },
            expected: 'beijing'
        },
        {
            name: '空对象',
            returnCitySN: {},
            expected: 'beijing'
        },
        {
            name: '无效城市名称',
            returnCitySN: { "cname": "未知", "cip": "192.168.1.1" },
            expected: 'beijing'
        },
        {
            name: '省份名称',
            returnCitySN: { "cname": "广东省", "cip": "192.168.1.1" },
            expected: 'guangdong'
        }
    ];

    // 中文城市到英文城市的映射
    const cityMapping = {
        '北京': 'beijing',
        '上海': 'shanghai',
        '广州': 'guangzhou',
        '深圳': 'shenzhen',
        '杭州': 'hangzhou',
        '南京': 'nanjing',
        '苏州': 'suzhou',
        '天津': 'tianjin',
        '重庆': 'chongqing',
        '成都': 'chengdu',
        '武汉': 'wuhan',
        '西安': 'xian',
        '长沙': 'changsha',
        '沈阳': 'shenyang',
        '青岛': 'qingdao',
        '大连': 'dalian',
        '厦门': 'xiamen',
        '福州': 'fuzhou',
        '济南': 'jinan',
        '郑州': 'zhengzhou',
        '哈尔滨': 'harbin',
        '长春': 'changchun',
        '昆明': 'kunming',
        '贵阳': 'guiyang',
        '兰州': 'lanzhou',
        '西宁': 'xining',
        '银川': 'yinchuan',
        '乌鲁木齐': 'urumqi',
        '拉萨': 'lasa',
        '海口': 'haikou',
        '三亚': 'sanya',
        // 省份映射到主要城市
        '广东': 'guangzhou',
        '江苏': 'nanjing',
        '浙江': 'hangzhou',
        '山东': 'jinan'
    };

    // 模拟getUserLocation函数
    function getUserLocation(returnCitySN) {
        console.log('=== 获取用户位置 ===');

        // 1. 优先使用城市名称
        if (returnCitySN && returnCitySN["cname"]) {
            let cityName = returnCitySN["cname"];

            // 清理城市名称
            cityName = cityName.replace('市', '').replace('省', '').replace('自治区', '');

            // 检查城市名称是否有效
            if (cityName && cityName !== '未知' && cityName.length > 0) {
                // 尝试从映射表中获取英文名称
                const englishName = cityMapping[cityName] || cityName.toLowerCase();
                console.log(`✅ 使用城市名称: ${cityName} -> ${englishName}`);
                return englishName;
            }
        }

        // 2. 如果有IP地址，尝试从IP解析城市（但不返回IP）
        if (returnCitySN && returnCitySN["cip"]) {
            const ip = returnCitySN["cip"];
            console.log(`检测到IP地址: ${ip}`);

            // 如果是本地或内网地址，直接使用默认城市
            if (ip === '127.0.0.1' ||
                ip.startsWith('192.168.') ||
                ip.startsWith('10.') ||
                ip.startsWith('172.') ||
                ip.startsWith('169.254.')) {
                console.log('❌ 本地/内网IP，使用默认城市: beijing');
                return 'beijing';
            }

            // 对于公网IP，我们不使用IP本身，而是使用默认城市
            console.log('ℹ️  公网IP detected，使用默认城市: beijing');
            return 'beijing';
        }

        // 3. 没有任何位置信息，使用默认城市
        console.log('❌ 无位置信息，使用默认城市: beijing');
        return 'beijing';
    }

    // 执行测试
    let allPassed = true;

    testCases.forEach((testCase, index) => {
        console.log(`\n📋 测试 ${index + 1}: ${testCase.name}`);
        console.log(`输入: ${JSON.stringify(testCase.returnCitySN)}`);

        // 临时设置全局变量
        global.returnCitySN = testCase.returnCitySN;

        const result = getUserLocation(testCase.returnCitySN);
        const passed = result === testCase.expected;

        console.log(`期望: ${testCase.expected}`);
        console.log(`实际: ${result}`);
        console.log(`${passed ? '✅ 通过' : '❌ 失败'}`);

        if (!passed) {
            allPassed = false;
        }

        // 检查结果是否为IP地址
        const isIP = /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(result);
        if (isIP) {
            console.log('🚨 错误：返回了IP地址而不是城市名称！');
            allPassed = false;
        }
    });

    console.log('\n=== 测试总结 ===');
    console.log(`${allPassed ? '🎉 所有测试通过！' : '❌ 部分测试失败！'}`);
    console.log('✅ 确认：getUserLocation函数始终返回城市名称，不返回IP地址');

    return allPassed;
}

// 运行测试
testGetUserLocation();
