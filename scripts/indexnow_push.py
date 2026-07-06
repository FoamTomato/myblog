#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
把本轮新增/更新的文章 URL 通过 IndexNow 协议主动推送给 Bing / Yandex 等。
只推新文,不重复推历史。复用 baidu_push 的 URL 收集逻辑(同一份 .new-posts.txt)。

用法:
  python scripts/indexnow_push.py                    # 读 .new-posts.txt 拼 URL 推送
  python scripts/indexnow_push.py <url1> <url2> ...  # 直接推指定 URL

环境变量:
  SITE            站点,默认 https://xiaohang.site
  INDEXNOW_KEY    IndexNow API key,默认取 source/ 下的 key 文件名(<key>.txt)
  PERMALINK       permalink 模板,默认 :year/:month/:day/:title/

key 文件: https://<SITE>/<INDEXNOW_KEY>.txt 内容 = <INDEXNOW_KEY>(证明域名所有权)
推送接口: POST https://api.indexnow.org/IndexNow  (application/json)
推送失败仅告警,不让发布流程失败。
"""
import os, sys, json, glob, urllib.request

# 复用 baidu_push 的 URL 收集(同目录同逻辑,避免重复实现)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from baidu_push import collect_urls_from_new_posts  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITE = os.environ.get('SITE', 'https://xiaohang.site').rstrip('/')
HOST = SITE.split('://', 1)[-1]
API = 'https://api.indexnow.org/IndexNow'


def detect_key():
    """优先环境变量,否则从 source/ 下的 *.txt key 文件推断(文件名去掉 .txt)。"""
    k = os.environ.get('INDEXNOW_KEY', '').strip()
    if k:
        return k
    # IndexNow key 文件名是 32 位十六进制,内容与文件名一致
    for p in glob.glob(os.path.join(ROOT, 'source', '*.txt')):
        stem = os.path.splitext(os.path.basename(p))[0]
        try:
            content = open(p, encoding='utf-8').read().strip()
        except Exception:
            continue
        if content == stem and len(stem) >= 8:
            return stem
    return ''


def push(urls):
    urls = [u.strip() for u in urls if u.strip()]
    if not urls:
        print('没有要推送的 URL,跳过')
        return
    key = detect_key()
    if not key:
        print('未找到 IndexNow key(INDEXNOW_KEY 或 source/<key>.txt),跳过')
        return
    payload = {
        'host': HOST,
        'key': key,
        'keyLocation': f'{SITE}/{key}.txt',
        'urlList': urls,
    }
    print('待推送 URL:')
    for u in urls:
        print('  ' + u)
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        API, data=data,
        headers={'Content-Type': 'application/json; charset=utf-8'})
    try:
        resp = urllib.request.urlopen(req, timeout=30)
        print(f'推送 {len(urls)} 条 -> IndexNow 返回: HTTP {resp.status}')
    except urllib.error.HTTPError as e:
        # 200/202 正常;其余按协议是告警(403 key 不匹配 / 422 URL 不属于该 host 等)
        body = ''
        try:
            body = e.read().decode()
        except Exception:
            pass
        print(f'::warning::IndexNow 推送返回 HTTP {e.code}(不影响发布): {body}')
    except Exception as e:
        print(f'::warning::IndexNow 推送失败(不影响发布): {type(e).__name__}: {e}')


if __name__ == '__main__':
    args = sys.argv[1:]
    urls = args if args else collect_urls_from_new_posts()
    push(urls)
