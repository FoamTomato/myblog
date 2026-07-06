#!/usr/bin/env bash
# 手动发布博客到自建服务器(非 GitHub Pages)。
# 线上由 117.72.182.195 上的 nginx 静态托管,root 指向 Docker 卷 opt_hexo-public。
# 直接把本地 build 出的 public/ rsync 进该卷即可,nginx 无需 reload。
#
# 用法:  npm run deploy
# 依赖:  已配置到 root@117.72.182.195 的免密 SSH
set -euo pipefail

HOST="${DEPLOY_HOST:-117.72.182.195}"
TARGET="/var/lib/docker/volumes/opt_hexo-public/_data/"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT"

echo "==> hexo clean && generate"
npx hexo clean
npx hexo generate

echo "==> rsync public/ -> root@${HOST}:${TARGET}"
rsync -az --delete \
  -e "ssh -o ConnectTimeout=15" \
  public/ "root@${HOST}:${TARGET}"

echo "==> verify live"
curl -sI "https://xiaohang.site/?_cb=$(date +%s)" | grep -i last-modified || true
echo "Done."
