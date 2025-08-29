# Hexo 博客项目

这是一个基于 Hexo 的现代化技术博客，集成了多种AI框架和自动化部署解决方案。

## 📚 项目特色

### 🤖 AI框架集成
- **LangChain4j** - Java原生LangChain实现
- **Spring AI** - Spring官方AI框架
- **高德地图MCP** - 地理信息服务集成

### 🚀 自动化部署
- **多脚本支持** - 从简单到高级的部署方案
- **GitHub Actions** - CI/CD自动化
- **多环境支持** - 本地、GitHub Pages、自定义服务器

### 📝 技术栈
- **静态生成**: Hexo
- **主题**: Butterfly
- **AI框架**: LangChain4j, Spring AI
- **地图服务**: 高德地图MCP
- **部署**: GitHub Pages, Shell脚本, GitHub Actions

## 📖 文章目录

### AI应用系列
1. **[0.5.2 LangChain4j打造自己的LLM应用](./source/_posts/0.5.2-LangChain4j打造自己的LLM应用.md)**
   - LangChain4j框架详解
   - 聊天机器人实现
   - 文档问答系统

2. **[0.5.3 Spring AI打造自己的LLM应用](./source/_posts/0.5.3-SpringAI打造自己的LLM应用.md)**
   - Spring AI框架详解
   - 企业级AI应用开发
   - 监控和部署方案

3. **[0.5.4 Java高德地图MCP定制旅游路线](./source/_posts/0.5.4-Java高德地图MCP定制旅游路线.md)**
   - 高德地图Java SDK集成
   - 智能旅游路线规划
   - 地理信息服务应用

## 🛠️ 快速开始

### 环境要求
- Node.js >= 14.0.0
- npm 或 yarn
- Git

### 安装依赖
```bash
# 安装项目依赖
npm install

# 安装Hexo CLI
npm install -g hexo-cli
```

### 本地运行
```bash
# 启动本地服务器
hexo server

# 访问 http://localhost:4000
```

### 构建静态文件
```bash
# 生成静态文件
hexo generate

# 清理缓存
hexo clean
```

## 🚀 部署方案

## 🌐 网络配置

### 代理设置（自动）
✅ **代理现在是默认行为**，所有部署脚本都会自动检测并启用代理：

```bash
# 自动检测顺序:
# 1. 环境变量代理 (http_proxy, https_proxy)
# 2. Git代理配置
# 3. .proxy-config配置文件
# 4. 本地代理(127.0.0.1:7890)

# 查看当前代理状态
./proxy-setup.sh status

# 手动管理代理
./proxy-setup.sh enable   # 启用代理
./proxy-setup.sh disable  # 禁用代理
```

### 自定义代理配置
编辑 `.proxy-config` 文件来自定义代理设置：

```bash
# 编辑配置文件
vim .proxy-config

# 配置内容示例:
HTTP_PROXY="http://127.0.0.1:7890"
HTTPS_PROXY="http://127.0.0.1:7890"
ALL_PROXY="socks5://127.0.0.1:7890"
```

### 网络诊断和测试
```bash
# 检查网络连接
./network-diagnosis.sh --test-all

# 生成诊断报告
./network-diagnosis.sh --report

# 测试代理集成
./test-proxy-integration.sh --test-all
```

### 天气API配置
```bash
# 查看配置状态
./configure-weather-api.sh status

# 配置单个API
./configure-weather-api.sh xinzhi YOUR_API_KEY

# 批量配置所有API
./configure-weather-api.sh all

# 创建配置备份
./configure-weather-api.sh backup

# 测试API连接
./test-weather-api.sh xinzhi YOUR_API_KEY

# 查看wttr.in API使用指南
cat WTTR_API_GUIDE.md

## 🌤️ 天气服务状态

### ✅ 当前配置
- **时钟插件**：使用 wttr.in API（免费，无需API Key）
- **动态定位**：根据用户IP自动定位当前城市
- **自动更新**：每小时自动刷新天气数据
- **错误处理**：完善的降级机制
- **全球覆盖**：支持全球任意IP地址定位
- **数据格式**：位置 + 天气图标 + 温度 + 湿度

### 🎯 动态城市查询
**是的！会动态查询当前城市**

通过用户IP地址自动定位：
1. 获取用户真实IP：`returnCitySN["cip"]`
2. 自动解析地理位置：`https://wttr.in/{IP}`
3. 返回对应城市的天气信息
4. 每小时重新定位，适应用户位置变化
```

## 🏠 本地部署

### 方案一：基础部署
```bash
# 使用简单脚本
./deploy.sh --all

# 本地预览
./deploy.sh --preview

# 离线测试
./deploy.sh --offline
```

### 方案二：高级部署
```bash
# 只部署构建产物
./advanced-deploy.sh deploy

# 包含源代码提交
./advanced-deploy.sh deploy-all

# 跳过源代码检查
./advanced-deploy.sh deploy --skip-source-check
```

### 方案三：工作流部署
```bash
# 新文章发布
./workflow-deploy.sh new-post "文章标题"

# 批量更新
./workflow-deploy.sh bulk-update

# 性能优化
./workflow-deploy.sh performance-optimize

# SEO优化
./workflow-deploy.sh seo-optimize
```

### 方案二：GitHub Actions自动部署
1. 推送代码到main分支
2. 自动触发GitHub Actions
3. 部署到GitHub Pages

### 方案三：自定义服务器部署
```bash
# 配置服务器信息
vim deploy-config.sh

# 执行部署
./advanced-deploy.sh deploy
```

## 📋 配置说明

### 环境变量
复制配置文件：
```bash
cp env-example.txt .env
vim .env
```

主要配置项：
```bash
# Git配置
GIT_USER_NAME=你的用户名
GIT_USER_EMAIL=你的邮箱

# API密钥
OPENAI_API_KEY=your-openai-key
AMAP_API_KEY=your-amap-key

# 部署配置
DEPLOY_BRANCH=gh-pages
CNAME=your-domain.com
```

### GitHub配置
1. **创建Personal Access Token**
   - Settings > Developer settings > Personal access tokens
   - 权限：repo, workflow

2. **配置仓库Secrets**
   - Repository Settings > Secrets and variables > Actions
   - 添加：`GITHUB_TOKEN`

3. **配置GitHub Pages**
   - Repository Settings > Pages
   - Source: Deploy from a branch
   - Branch: `gh-pages` / `/`

## 🧪 测试部署

运行部署测试：
```bash
# 运行所有测试
./test-deploy.sh all

# 单独测试
./test-deploy.sh system    # 系统要求
./test-deploy.sh build     # 构建测试
./test-deploy.sh git       # Git配置
```

## 📁 项目结构

```
blog/
├── source/                 # 源文件
│   └── _posts/            # 博客文章
├── themes/                # 主题
├── public/                # 生成的静态文件
├── .github/
│   └── workflows/         # GitHub Actions
├── deploy.sh              # 基础部署脚本
├── advanced-deploy.sh     # 高级部署脚本
├── deploy-config.sh       # 部署配置
├── test-deploy.sh         # 部署测试脚本
├── DEPLOY_README.md       # 部署详细说明
└── _config.yml            # Hexo配置
```

## 🎨 主题配置

当前使用 Butterfly 主题，配置文件：
- `_config.butterfly.yml` - 主题配置
- `_config.yml` - 主配置文件

## 📊 功能特性

### AI应用功能
- ✅ 智能聊天机器人
- ✅ 文档问答系统
- ✅ 代码生成助手
- ✅ 多模型支持

### 地图服务功能
- ✅ POI搜索
- ✅ 路径规划
- ✅ 地理编码
- ✅ 距离计算

### 部署功能
- ✅ GitHub Pages自动部署
- ✅ 自定义服务器部署
- ✅ 备份和恢复
- ✅ 监控和通知

## 📖 详细文档

- **[部署指南](./DEPLOY_README.md)** - 完整的部署说明
- **[环境配置](./env-example.txt)** - 配置模板
- **[GitHub Actions](./.github/workflows/)** - 自动化配置

## 🤝 贡献指南

1. Fork 项目
2. 创建特性分支：`git checkout -b feature/AmazingFeature`
3. 提交更改：`git commit -m 'Add some AmazingFeature'`
4. 推送分支：`git push origin feature/AmazingFeature`
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📞 联系方式

- 项目地址：[GitHub Repository]
- 博客地址：[GitHub Pages]
- 作者邮箱：[your-email@example.com]

---

**最后更新**: 2024-01-17
**Hexo版本**: 7.x
**Node版本**: >= 14.0.0
