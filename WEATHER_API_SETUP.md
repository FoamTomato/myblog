# 🌤️ 天气API配置指南

本指南将帮助您为旅游路线应用配置可用的天气API服务。

## 📋 API服务对比

| 服务商 | 免费额度 | 稳定性 | 易用性 | 推荐指数 |
|--------|----------|--------|--------|----------|
| 心知天气 | 1000次/天 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 🥇 最推荐 |
| 和风天气 | 300次/天 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 🥈 推荐 |
| OpenWeatherMap | 1000次/天 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 🥉 备选 |
| 聚合数据 | 100次/天 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 🥉 备选 |

## 🔧 配置步骤

### 1. 注册获取API Key

#### 心知天气（推荐）
1. 访问：[心知天气开放平台](https://www.seniverse.com/)
2. 注册账号并登录
3. 创建新应用，获取API Key
4. 在HTML文件中找到以下代码：
```javascript
xinzhi: {
    name: '心知天气',
    url: 'https://api.seniverse.com/v3/weather/daily.json',
    params: {
        key: 'your_api_key_here', // 🔴 替换为您的API Key
        location: 'beijing',
        language: 'zh-Hans',
        unit: 'c',
        start: 0,
        days: 5
    }
}
```

#### 和风天气
1. 访问：[和风天气开发平台](https://dev.qweather.com/)
2. 注册账号并实名认证
3. 创建应用获取API Key
4. 在HTML文件中替换：
```javascript
heweather: {
    name: '和风天气',
    url: 'https://devapi.qweather.com/v7/weather/7d',
    params: {
        location: '101010100', // 北京城市ID
        key: 'your_api_key_here' // 🔴 替换为您的API Key
    }
}
```

#### OpenWeatherMap
1. 访问：[OpenWeatherMap](https://openweathermap.org/api)
2. 注册账号
3. 获取API Key
4. 在HTML文件中替换：
```javascript
openweather: {
    name: 'OpenWeatherMap',
    url: 'https://api.openweathermap.org/data/2.5/forecast',
    params: {
        appid: 'your_api_key_here', // 🔴 替换为您的API Key
        q: 'Beijing,cn',
        units: 'metric',
        cnt: 5
    }
}
```

#### 聚合数据
1. 访问：[聚合数据](https://www.juhe.cn/)
2. 注册账号
3. 搜索"天气"获取API
4. 在HTML文件中替换：
```javascript
juhe: {
    name: '聚合数据',
    url: 'https://apis.juhe.cn/simpleWeather/query',
    params: {
        city: '北京',
        key: 'your_api_key_here' // 🔴 替换为您的API Key
    }
}
```

### 2. 测试配置

配置完成后，刷新页面或点击"🔄 更新"按钮测试：

1. **成功情况**：显示实时天气数据
2. **失败情况**：显示默认天气数据（降级方案）

### 3. 故障排除

#### 问题1：API调用失败
- 检查API Key是否正确
- 确认API配额是否充足
- 检查网络连接是否正常

#### 问题2：显示默认数据
- 所有API都不可用时会自动降级
- 检查浏览器控制台的错误信息
- 确认API配置格式是否正确

#### 问题3：天气数据不准确
- 不同API的数据源可能不同
- 可以同时配置多个API做备用
- 检查城市名称或ID是否正确

## 🎯 高级配置

### 自定义API优先级

```javascript
// 在getWeatherData函数中修改API尝试顺序
const apis = ['xinzhi', 'heweather', 'openweather', 'juhe'];
```

### 添加新的天气API

```javascript
// 添加新的天气API配置
const WEATHER_APIS = {
    // 现有配置...
    newapi: {
        name: '新天气API',
        url: 'https://api.newweather.com/v1/forecast',
        params: {
            key: 'your_api_key_here',
            city: 'beijing',
            days: 5
        }
    }
};

// 添加对应的数据解析函数
function parseNewApiWeather(data) {
    if (!data.forecast) return null;

    return data.forecast.map((day, index) => ({
        date: `8月${27 + index}日`,
        weather: day.weather,
        temp: `${day.high}°/${day.low}°`,
        icon: weatherIcons[day.weather] || '☀️',
        desc: getDayDescription(index + 1)
    }));
}

// 在getWeatherData函数中添加解析逻辑
switch (apiName) {
    // 现有case...
    case 'newapi':
        weatherData = parseNewApiWeather(rawData);
        break;
}
```

### 自定义城市

```javascript
// 修改API配置中的城市参数
params: {
    // 心知天气
    location: 'shanghai', // 上海

    // 和风天气
    location: '101020100', // 上海城市ID

    // OpenWeatherMap
    q: 'Shanghai,cn', // 上海

    // 聚合数据
    city: '上海'
}
```

## 📊 API使用统计

配置完成后，可以在浏览器控制台查看使用情况：

```javascript
// 查看当前使用的API
console.log('当前天气API:', currentWeatherAPI);

// 查看API响应时间
// 系统会自动记录每个API的响应时间
```

## 🔄 更新机制

- **自动更新**：页面加载时自动获取最新天气
- **手动更新**：点击"🔄 更新"按钮
- **智能降级**：API失败时自动使用默认数据
- **缓存机制**：避免频繁请求API

## ⚠️ 注意事项

1. **API配额**：注意各平台的免费额度限制
2. **数据时效**：天气数据通常有15-30分钟的延迟
3. **网络安全**：API Key请妥善保管，避免泄露
4. **兼容性**：确保API支持CORS跨域请求
5. **错误处理**：系统会自动处理各种异常情况

## 🆘 获取帮助

如果配置过程中遇到问题：

1. 检查浏览器控制台的错误信息
2. 确认API Key是否正确配置
3. 尝试使用其他API服务
4. 查看各平台的API文档

---

**配置完成后，您的旅游路线应用将拥有实时的天气预报功能！** 🎉
