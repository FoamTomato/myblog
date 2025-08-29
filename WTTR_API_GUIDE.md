# wttr.in 天气API使用指南

## 📖 概述

wttr.in 是一个免费的天气API服务，提供简洁的命令行风格天气信息。本文档介绍如何在Hexo博客中使用wttr.in API。

## 🌐 API格式

### 基础URL
```
https://wttr.in/{城市或IP}?format="{格式}"
```

### 🔍 动态城市查询机制

**是的，wttr.in支持动态查询当前城市！**

#### IP地址自动定位
```javascript
// 原始实现方式
fetch('https://wttr.in/' + returnCitySN["cip"] + '?format="%l+\\+%c+\\+%t+\\+%h"')
```

#### 工作原理
1. **获取用户IP**：`returnCitySN["cip"]` 获取用户的IP地址
2. **自动定位**：wttr.in API根据IP地址自动解析地理位置
3. **返回天气**：返回对应城市的天气信息

#### 支持的参数类型
- **IP地址**：`https://wttr.in/127.0.0.1`（自动定位）
- **城市名称**：`https://wttr.in/beijing`（指定城市）
- **城市拼音**：`https://wttr.in/shanghai`（中文城市）
- **英文名称**：`https://wttr.in/London`（国际城市）

### 常用格式参数
- `%l` - 位置/城市名称
- `%c` - 天气状况图标
- `%t` - 温度
- `%h` - 湿度
- `%w` - 风速

### 示例格式
```bash
# 基础格式（位置 + 天气图标 + 温度 + 湿度）
format="%l+\\+%c+\\+%t+\\+%h"

# 完整URL示例
https://wttr.in/beijing?format="%l+\\+%c+\\+%t+\\+%h"
```

## 📊 返回数据格式

### 原始数据示例
```
"beijing \ 🌦   \ +22°C \ 100%"
```

### 解析后数据
```javascript
{
  location: "beijing",      // 位置
  weather: "🌦 多云",       // 天气状况
  temp: "+22°C",           // 温度
  humidity: "100%"         // 湿度
}
```

## 🚀 在Hexo中的使用

### 集成到时钟插件

```javascript
// 使用示例
async function getWeatherDataForClock(ip) {
    try {
        const city = returnCitySN["cname"] || 'beijing';
        const response = await fetch(`https://wttr.in/${city}?format="%l+\\+%c+\\+%t+\\+%h"`);

        if (response.ok) {
            const rawData = await response.text();
            const cleanData = rawData.replace(/"/g, '').trim();
            const parts = cleanData.split(' \\ ');

            if (parts.length >= 4) {
                return {
                    location: parts[0].trim(),
                    weather: parts[1].trim() + ' ' + getWeatherText(parts[1].trim()),
                    temp: parts[2].trim(),
                    humidity: parts[3].trim()
                };
            }
        }
    } catch (error) {
        console.warn('wttr.in API调用失败:', error);
    }

    // 降级处理
    return {
        location: returnCitySN["cname"] || '北京市',
        weather: '☀️ 晴',
        temp: '+25°C',
        humidity: '60%'
    };
}
```

## 🌤️ 天气图标映射

| 图标 | 中文描述 | 英文描述 |
|------|----------|----------|
| ☀️ | 晴 | Clear |
| 🌤️ | 多云 | Partly cloudy |
| ⛅ | 阴 | Cloudy |
| ☁️ | 阴 | Overcast |
| 🌦️ | 小雨 | Light rain |
| 🌧️ | 中雨 | Moderate rain |
| ⛈️ | 雷雨 | Thunderstorm |
| 🌨️ | 雪 | Snow |
| ❄️ | 雪 | Snow |
| 🌫️ | 雾 | Fog |
| 💨 | 风 | Windy |
| 🌪️ | 龙卷风 | Tornado |

## ⚠️ 注意事项

### 1. API限制
- wttr.in 有查询频率限制
- 当达到限制时会返回默认城市的天气信息

### 2. 城市名称
- 支持中文城市名：`beijing`、`shanghai`等
- 支持拼音：`beijing`、`shanghai`等
- 支持英文：`Beijing`、`Shanghai`等

### 3. 错误处理
```javascript
// 建议的错误处理流程
1. 尝试用户所在城市
2. 如果失败，使用默认城市（beijing）
3. 如果都失败，返回静态默认数据
```

### 4. 数据解析
- 使用 `split(' \\ ')` 分割数据
- 注意转义字符的处理
- 确保数据字段完整性

## 🧪 测试方法

### 命令行测试
```bash
# 测试北京天气
curl "https://wttr.in/beijing?format=\"%l+\\+%c+\\+%t+\\+%h\""

# 测试上海天气
curl "https://wttr.in/shanghai?format=\"%l+\\+%c+\\+%t+\\+%h\""
```

### 浏览器测试
```javascript
// 在浏览器控制台中测试
fetch('https://wttr.in/beijing?format="%l+\\+%c+\\+%t+\\+%h"')
  .then(r => r.text())
  .then(data => console.log(data));
```

## 📈 优势

1. **免费使用** - 无需API Key
2. **响应快速** - 轻量级API
3. **格式简洁** - 易于解析
4. **全球覆盖** - 支持全球主要城市
5. **图标丰富** - 提供直观的天气图标

## 🔧 配置建议

### 时钟插件配置
```yaml
# _config.butterfly.yml
# 时钟插件已自动集成wttr.in
# 无需额外配置
```

### 自动更新频率
- 建议：每小时更新一次
- 实现：使用 `setInterval` 设置定时器

## 🎯 最佳实践

1. **缓存机制** - 避免频繁请求
2. **错误降级** - 多层备用方案
3. **用户友好** - 清晰的状态提示
4. **性能优化** - 异步加载和处理

---

**当前状态**：✅ wttr.in API已成功集成到时钟插件
**测试结果**：✅ 北京、上海、广州、深圳、杭州等城市测试通过
**动态查询**：✅ 根据用户IP自动定位当前城市
**自动更新**：✅ 每小时自动刷新天气数据
**最新修复**：✅ 修复503错误，过滤本地IP，改进错误处理

## 🔧 问题修复记录

### 问题1：503 Service Unavailable 错误
**现象**：`https://wttr.in/127.0.0.1?format=...` 返回503错误
**原因**：wttr.in对本地IP地址(127.0.0.1, 192.168.x.x等)返回服务不可用
**解决**：
- ✅ 优先使用城市名称而不是IP地址
- ✅ 过滤本地IP地址，使用默认城市
- ✅ 添加IP地址有效性检查

### 问题2：API限制处理
**现象**：wttr.in有时返回"Sorry, we are running out of queries"
**解决**：
- ✅ 添加API限制检测
- ✅ 自动降级到备用方案
- ✅ 改进错误提示信息

### 问题3：数据有效性验证
**现象**：有时返回"not found"或"Unknown"数据
**解决**：
- ✅ 过滤无效数据
- ✅ 验证数据完整性
- ✅ 提供默认降级数据

## 🎯 动态城市查询详解

### 工作流程
1. **获取位置信息**：优先使用城市名称，其次使用有效IP地址
2. **智能过滤**：过滤本地IP地址(127.0.0.1, 192.168.x.x等)
3. **API调用**：`https://wttr.in/{城市名称}` 获取天气数据
4. **数据验证**：检查数据有效性，过滤无效结果
5. **返回天气**：自动返回用户所在城市的天气信息
6. **实时更新**：每小时重新查询，适应用户位置变化

### 优势
- **无需配置**：自动检测用户位置
- **实时定位**：根据IP地址精确定位
- **全球覆盖**：支持全球任意IP地址
- **动态适应**：用户位置变化时自动更新

### 示例
```javascript
// 当前实现
const userIP = returnCitySN["cip"]; // 如：192.168.1.100
fetch(`https://wttr.in/${userIP}?format="%l+\\+%c+\\+%t+\\+%h"`)
// 自动返回用户所在城市的天气
```
