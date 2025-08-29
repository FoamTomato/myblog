# 🚀 Hexo 博客部署使用示例

本指南提供了各种部署场景的完整示例，帮助你快速掌握Hexo博客的自动化部署。

## 📋 目录

- [快速开始](#快速开始)
- [本地部署](#本地部署)
- [GitHub Actions自动部署](#github-actions自动部署)
- [自定义服务器部署](#自定义服务器部署)
- [监控和维护](#监控和维护)
- [故障排除](#故障排除)
- [最佳实践](#最佳实践)

## ⚡ 快速开始

### 环境准备

```bash
# 1. 克隆项目
git clone https://github.com/your-username/your-blog.git
cd your-blog

# 2. 配置环境变量
cp env-example.txt .env
vim .env

# 3. 测试部署环境
./test-deploy.sh all

# 4. 运行完整部署
./advanced-deploy.sh deploy
```

### 基本配置

```bash
# .env 文件配置
GIT_USER_NAME="你的GitHub用户名"
GIT_USER_EMAIL="你的GitHub邮箱"
GITHUB_TOKEN="你的GitHub Token"
DEPLOY_BRANCH="gh-pages"
OPENAI_API_KEY="你的AI密钥"
AMAP_API_KEY="你的地图密钥"
```

## 🏠 本地部署

### 方案一：基础部署

```bash
# 检查项目状态
./test-deploy.sh status

# 清理缓存
./deploy.sh -c

# 生成静态文件
./deploy.sh -g

# 部署到GitHub Pages
./deploy.sh -d
```

### 方案二：高级部署

```bash
# 查看帮助信息
./advanced-deploy.sh --help

# 完整部署流程
./advanced-deploy.sh deploy

# 包含源代码提交的部署
./advanced-deploy.sh deploy-all

# 跳过源代码检查
./advanced-deploy.sh deploy --skip-source-check

# 只构建不部署
./advanced-deploy.sh build

# 查看部署状态
./advanced-deploy.sh status

# 清理缓存文件
./advanced-deploy.sh cleanup

# 备份当前部署
./advanced-deploy.sh backup
```

### 自定义部署配置

```bash
# 编辑配置文件
vim deploy-config.sh

# 修改部署设置
DEPLOY_TARGET="github"  # github, custom
ENABLE_CACHE="true"
ENABLE_BACKUP="true"
BACKUP_RETENTION="7"

# 重新加载配置
source deploy-config.sh
```

## 🔄 GitHub Actions自动部署

### 基本自动部署

```yaml
# .github/workflows/deploy.yml
name: Deploy Hexo Blog

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Install Hexo CLI
        run: npm install -g hexo-cli

      - name: Generate static files
        run: |
          hexo clean
          hexo generate

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
```

### 高级CI/CD流程

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  quality-check:
    name: 代码质量检查
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: 质量检查
        run: ./test-deploy.sh all

  build-and-deploy:
    needs: quality-check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: 构建和部署
        run: ./advanced-deploy.sh deploy
```

### 多环境部署

```yaml
# 生产环境部署
- name: Deploy to Production
  if: github.ref == 'refs/heads/main'
  run: ./advanced-deploy.sh deploy

# 预发布环境部署
- name: Deploy to Staging
  if: github.ref == 'refs/heads/develop'
  run: |
    export DEPLOY_BRANCH="staging"
    ./advanced-deploy.sh deploy
```

## 🖥️ 自定义服务器部署

### 配置服务器信息

```bash
# 在 .env 中配置
CUSTOM_SERVER_HOST="your-server.com"
CUSTOM_SERVER_USER="deploy"
CUSTOM_SERVER_PATH="/var/www/html/blog"
```

### SSH密钥配置

```bash
# 生成SSH密钥
ssh-keygen -t rsa -b 4096 -C "deploy@your-server"

# 复制公钥到服务器
ssh-copy-id deploy@your-server

# 在GitHub Secrets中添加私钥
# GITHUB_TOKEN: your-github-token
# SERVER_SSH_KEY: (私钥内容)
```

### 服务器部署脚本

```bash
# 使用rsync部署
./advanced-deploy.sh deploy

# 或使用自定义部署脚本
rsync -avz --delete \
  --exclude=".git" \
  --exclude="node_modules" \
  public/ \
  deploy@your-server:/var/www/html/blog/
```

## 📊 监控和维护

### 部署状态监控

```bash
# 监控GitHub Pages状态
./monitor-deploy.sh -r your-username/your-repo -m

# 检查网站可访问性
./monitor-deploy.sh -u https://your-username.github.io/your-repo -s

# 性能分析
./monitor-deploy.sh -u https://your-username.github.io/your-repo -p
```

### 健康检查报告

```bash
# 生成健康检查报告
./monitor-deploy.sh -u https://your-username.github.io/your-repo \
  -p -o health-report.md

# 定期监控脚本
#!/bin/bash
while true; do
    ./monitor-deploy.sh -u https://your-username.github.io/your-repo -s
    sleep 3600  # 每小时检查一次
done
```

### 日志分析

```bash
# 查看部署日志
tail -f deploy.log

# 分析GitHub Actions日志
# 在GitHub仓库的Actions标签页查看

# 日志轮转
#!/bin/bash
LOG_FILE="deploy.log"
MAX_SIZE=10485760  # 10MB

if [[ -f "$LOG_FILE" ]] && [[ $(stat -f%z "$LOG_FILE") -gt $MAX_SIZE ]]; then
    mv "$LOG_FILE" "${LOG_FILE}.$(date +%Y%m%d_%H%M%S)"
    touch "$LOG_FILE"
fi
```

## 🔧 故障排除

### 常见问题解决

```bash
# 问题1: 权限被拒绝
chmod +x deploy.sh advanced-deploy.sh monitor-deploy.sh

# 问题2: 依赖安装失败
rm -rf node_modules package-lock.json
npm install

# 问题3: 构建失败
hexo clean
hexo generate --debug

# 问题4: 部署失败
git status
git remote -v
./test-deploy.sh git
```

### 调试模式

```bash
# 启用详细日志
export LOG_LEVEL=debug
./advanced-deploy.sh deploy

# 手动执行每一步
hexo clean
hexo generate
hexo deploy --debug

# 检查网络连接
curl -I https://api.github.com
curl -I https://your-username.github.io
```

### 回滚方案

```bash
# 回滚到上一个版本
git checkout gh-pages
git reset --hard HEAD~1
git push --force origin gh-pages

# 恢复备份
./advanced-deploy.sh backup
cp .backup/backup_$(date +%Y%m%d)/* public/
hexo deploy
```

## 🌟 最佳实践

### 开发流程

```bash
# 1. 创建特性分支
git checkout -b feature/new-post
git add .
git commit -m "Add new blog post"

# 2. 推送到远程
git push origin feature/new-post

# 3. 创建Pull Request
# 在GitHub上创建PR并合并

# 4. 主分支自动部署
# GitHub Actions会自动部署到GitHub Pages
```

### 内容管理

```bash
# 创建新文章
hexo new post "我的新文章"

# 生成草稿
hexo new draft "草稿文章"

# 发布草稿
hexo publish draft "草稿文章"

# 预览本地
hexo server --draft
```

### 性能优化

```bash
# 启用压缩
echo "ENABLE_MINIFY=true" >> .env
echo "ENABLE_COMPRESS=true" >> .env

# 图片优化
# 使用WebP格式
# 压缩图片大小

# CDN加速
# 配置CDN分发静态资源
```

### 安全配置

```bash
# 配置GitHub Token
# Settings > Developer settings > Personal access tokens
# 权限：repo, workflow

# 保护敏感信息
# 使用GitHub Secrets存储API密钥
# 不要在代码中明文存储密码

# HTTPS强制
# 在GitHub Pages设置中启用HTTPS
```

### 备份策略

```bash
# 启用自动备份
echo "ENABLE_BACKUP=true" >> .env
echo "BACKUP_RETENTION=30" >> .env

# 手动备份
./advanced-deploy.sh backup

# 定期清理备份
find .backup -name "backup_*" -mtime +30 -delete
```

## 📞 获取帮助

### 常用命令速查

```bash
# 项目管理
./test-deploy.sh all          # 测试环境
./advanced-deploy.sh status   # 查看状态

# 部署操作
./deploy.sh --all            # 基础部署
./advanced-deploy.sh deploy   # 高级部署
./advanced-deploy.sh deploy-all # 包含提交

# 监控维护
./monitor-deploy.sh -s       # 状态检查
./monitor-deploy.sh -p       # 性能分析
./monitor-deploy.sh -m       # 监控部署
```

### 资源链接

- [Hexo官方文档](https://hexo.io/docs/)
- [GitHub Pages文档](https://docs.github.com/pages)
- [GitHub Actions文档](https://docs.github.com/actions)
- [Hexo主题](https://hexo.io/themes/)

---

**最后更新**: 2024-01-17
**版本**: v2.0.0
