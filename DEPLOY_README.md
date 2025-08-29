# Hexo 博客自动部署指南

本项目提供了多种自动部署到 GitHub Pages 的解决方案，支持本地部署和 CI/CD 自动化部署。

## 🚀 快速开始

### 方式一：使用简单脚本（推荐新手）

```bash
# 完整部署流程
./deploy.sh --all

# 或者单独执行
./deploy.sh -c -g -d  # 清理 + 生成 + 部署
```

### 方式二：使用高级脚本（推荐）

```bash
# 完整部署
./advanced-deploy.sh deploy

# 只构建
./advanced-deploy.sh build

# 查看状态
./advanced-deploy.sh status

# 清理缓存
./advanced-deploy.sh cleanup
```

## 📋 前置要求

### 系统要求
- Node.js >= 14.0.0
- npm 或 yarn
- Git
- curl (用于通知)

### 检查系统
```bash
# 检查Node.js版本
node -v

# 检查npm
npm -v

# 检查Git
git --version
```

## ⚙️ 配置说明

### 1. 环境变量配置

创建 `.env` 文件：
```bash
# Git配置
GIT_USER_NAME="你的名字"
GIT_USER_EMAIL="你的邮箱"

# 部署配置
DEPLOY_BRANCH="gh-pages"
SOURCE_BRANCH="main"

# 高德地图API密钥（如果使用相关功能）
AMAP_API_KEY="your-amap-api-key"

# 自定义域名（可选）
CNAME="your-domain.com"

# 通知配置（可选）
NOTIFICATION_WEBHOOK="https://hooks.slack.com/xxx"
```

### 2. 配置文件

编辑 `deploy-config.sh` 中的配置项：
```bash
# 部署目标
DEPLOY_TARGET="github"  # github, custom

# 自定义服务器配置（用于非GitHub Pages）
CUSTOM_SERVER_HOST="your-server.com"
CUSTOM_SERVER_USER="username"
CUSTOM_SERVER_PATH="/var/www/html"
```

### 3. GitHub 配置

#### 设置GitHub Token（用于GitHub Actions）
1. 进入 GitHub Settings > Developer settings > Personal access tokens
2. 创建新的 Token，权限包括 `repo` 和 `workflow`
3. 在仓库 Settings > Secrets and variables > Actions 中添加：
   - `GITHUB_TOKEN`: 你的GitHub Token

#### 配置GitHub Pages
1. 进入仓库 Settings > Pages
2. Source 选择 "Deploy from a branch"
3. Branch 选择 `gh-pages` 分支和 `/` 根目录

## 🔄 部署流程

### 本地部署

#### 方式一：手动部署
```bash
# 1. 清理缓存
hexo clean

# 2. 生成静态文件
hexo generate

# 3. 部署到GitHub Pages
hexo deploy
```

#### 方式二：使用脚本
```bash
# 一键部署
./advanced-deploy.sh deploy

# 查看部署状态
./advanced-deploy.sh status

# 备份当前部署
./advanced-deploy.sh backup
```

### GitHub Actions 自动部署

项目已配置 GitHub Actions，会在推送到 `main` 分支时自动部署：

1. **推送代码**：
   ```bash
   git add .
   git commit -m "更新博客内容"
   git push origin main
   ```

2. **查看部署状态**：
   - 进入 GitHub 仓库的 Actions 标签页
   - 查看最新的 workflow 运行状态
   - 部署成功后可访问 `https://你的用户名.github.io/仓库名`

## 🛠️ 高级配置

### 缓存配置
```bash
# 启用缓存
ENABLE_CACHE=true
CACHE_DIR=.hexo_cache
```

### 性能优化
```bash
# 启用压缩
ENABLE_MINIFY=true
ENABLE_COMPRESS=true
```

### 通知配置
```bash
# Slack通知
ENABLE_NOTIFICATION=true
NOTIFICATION_WEBHOOK="https://hooks.slack.com/xxx"
```

### 备份配置
```bash
# 自动备份
ENABLE_BACKUP=true
BACKUP_DIR=.backup
BACKUP_RETENTION=7  # 保留7天
```

## 📊 监控和故障排除

### 查看部署日志
```bash
# 本地部署日志
tail -f deploy.log

# GitHub Actions日志
# 在GitHub仓库的Actions标签页查看
```

### 常见问题

#### 1. 部署失败：权限问题
```bash
# 检查Git权限
git remote -v
git config --list

# 重新设置远程仓库
git remote set-url origin https://你的用户名:你的token@github.com/你的用户名/仓库名.git
```

#### 2. 构建失败：依赖问题
```bash
# 清理缓存重新安装
rm -rf node_modules package-lock.json
npm install
```

#### 3. 页面不更新
```bash
# 强制刷新浏览器缓存
# 或者检查GitHub Pages设置
```

#### 4. 域名配置
```bash
# 在deploy-config.sh中设置
CNAME="your-domain.com"

# 或者在source目录创建CNAME文件
echo "your-domain.com" > source/CNAME
```

## 🔧 自定义扩展

### 添加预构建和后构建步骤
```bash
# 在deploy-config.sh中设置
PRE_BUILD_COMMAND="echo '开始构建...'"
POST_BUILD_COMMAND="echo '构建完成！'"
```

### 自定义部署脚本
```bash
#!/bin/bash
# 自定义部署逻辑
# 可以参考advanced-deploy.sh的实现
```

## 📝 部署脚本说明

### `deploy.sh` - 基础部署脚本
- 简单的部署流程
- 适合快速部署
- 错误处理完善

### `advanced-deploy.sh` - 高级部署脚本
- 功能丰富
- 支持多种部署方式
- 包含备份和通知功能

### `deploy-config.sh` - 配置文件
- 集中管理配置
- 支持环境变量
- 易于自定义

## 🌟 最佳实践

1. **定期备份**：启用自动备份功能
2. **监控部署**：设置通知，及时发现问题
3. **测试部署**：在测试分支上测试后再部署到主分支
4. **版本控制**：所有配置文件纳入版本控制
5. **文档更新**：及时更新部署文档

## 📞 支持

如果遇到问题，请：

1. 查看部署日志
2. 检查配置文件
3. 参考常见问题
4. 在GitHub Issues中提交问题

---

**最后更新时间**: 2024-01-17
**版本**: v1.0.0
