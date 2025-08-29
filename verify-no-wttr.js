// 验证项目中是否还有wttr.in的调用
// 在浏览器控制台中运行此脚本

(function() {
    console.log('🔍 开始验证wttr.in使用情况...');
    console.log('=====================================');

    // 1. 检查所有JavaScript代码中的wttr引用
    function findWttrInCode() {
        const scripts = document.querySelectorAll('script');
        let foundWttr = false;

        scripts.forEach(script => {
            if (script.src) {
                // 检查外部脚本
                fetch(script.src)
                    .then(response => response.text())
                    .then(content => {
                        if (content.includes('wttr')) {
                            console.log('❌ 发现wttr引用 in:', script.src);
                            foundWttr = true;
                        }
                    })
                    .catch(err => console.log('无法检查脚本:', script.src));
            } else if (script.textContent && script.textContent.includes('wttr')) {
                console.log('❌ 发现内联脚本中的wttr引用');
                foundWttr = true;
            }
        });

        // 检查页面中的所有文本内容
        const allText = document.body.textContent;
        if (allText.includes('wttr.in')) {
            console.log('⚠️ 页面文本中包含wttr.in引用（可能是文档说明）');
        }

        return foundWttr;
    }

    // 2. 检查网络请求
    function monitorNetworkRequests() {
        console.log('📡 监控网络请求...');

        // 创建一个观察者来监控fetch请求
        const originalFetch = window.fetch;
        window.fetch = function(...args) {
            const url = args[0];
            if (typeof url === 'string' && url.includes('wttr.in')) {
                console.log('🚨 发现wttr.in网络请求:', url);
            }
            return originalFetch.apply(this, args);
        };

        // 监控XMLHttpRequest
        const originalOpen = XMLHttpRequest.prototype.open;
        XMLHttpRequest.prototype.open = function(method, url) {
            if (url.includes('wttr.in')) {
                console.log('🚨 发现wttr.in XMLHttpRequest:', url);
            }
            return originalOpen.apply(this, arguments);
        };
    }

    // 3. 检查localStorage设置
    function checkLocalStorage() {
        console.log('💾 检查localStorage设置...');

        const useSeniverse = localStorage.getItem('useSeniverseWeather');
        const useOpenWeather = localStorage.getItem('useOpenWeatherMap');

        console.log('useSeniverseWeather:', useSeniverse);
        console.log('useOpenWeatherMap:', useOpenWeather);

        if (useSeniverse === 'true') {
            console.log('✅ 当前使用心知天气');
        } else if (useOpenWeather === 'true') {
            console.log('⚠️ 当前使用OpenWeatherMap');
        } else {
            console.log('⚠️ 未设置天气服务，将使用默认设置');
        }
    }

    // 4. 检查时钟插件状态
    function checkClockPlugin() {
        console.log('🕐 检查时钟插件状态...');

        // 查找时钟相关的元素
        const clockElement = document.getElementById('hexo_electric_clock');
        if (clockElement) {
            console.log('✅ 发现时钟元素:', clockElement);

            // 检查时钟内容
            const weatherElements = clockElement.querySelectorAll('[class*="weather"]');
            weatherElements.forEach(el => {
                console.log('天气元素内容:', el.textContent);
                if (el.textContent.includes('wttr') || el.textContent.includes('127.0.0.1')) {
                    console.log('🚨 发现可疑内容:', el.textContent);
                }
            });
        } else {
            console.log('⚠️ 未发现时钟元素');
        }
    }

    // 5. 运行所有检查
    console.log('1️⃣ 检查代码中的wttr引用...');
    findWttrInCode();

    console.log('2️⃣ 设置网络请求监控...');
    monitorNetworkRequests();

    console.log('3️⃣ 检查本地存储...');
    checkLocalStorage();

    console.log('4️⃣ 检查时钟插件...');
    checkClockPlugin();

    console.log('');
    console.log('🎯 验证完成！');
    console.log('=====================================');
    console.log('💡 请刷新页面并查看控制台输出');
    console.log('💡 如果发现任何wttr.in调用，请截图反馈');

})();
