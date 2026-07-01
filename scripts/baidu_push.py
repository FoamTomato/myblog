#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
把本轮新增/更新的文章 URL 主动推送给百度(普通收录 API)。
只推新文,不重复推历史,省配额。

用法:
  python scripts/baidu_push.py                    # 读 .new-posts.txt(文件名 stem)拼 URL 推送
  python scripts/baidu_push.py <url1> <url2> ...  # 直接推指定 URL

环境变量:
  SITE              站点,默认 https://xiaohang.site
  BAIDU_PUSH_TOKEN  百度推送 token(必填,缺失则跳过不报错)
  PERMALINK         permalink 模板,默认 :year/:month/:day/:title/

推送接口: http://data.zz.baidu.com/urls?site=<SITE>&token=<TOKEN>
返回 {"success":N,"remain":M} 或错误。推送失败仅告警,不让发布流程失败。
"""
import os, sys, re, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POSTS_DIR = os.path.join(ROOT, 'source', '_posts')
SITE = os.environ.get('SITE', 'https://xiaohang.site').rstrip('/')
TOKEN = os.environ.get('BAIDU_PUSH_TOKEN', '')
PERMALINK = os.environ.get('PERMALINK', ':year/:month/:day/:title/')


def parse_fm(text):
    m = re.match(r'^---\n(.*?)\n---', text, re.S)
    if not m:
        return {}
    fm = m.group(1)
    out = {}
    dm = re.search(r'^date:\s*([0-9]{4})-([0-9]{2})-([0-9]{2})', fm, re.M)
    if dm:
        out['year'], out['month'], out['day'] = dm.groups()
    tm = re.search(r'^title:\s*["\']?(.+?)["\']?\s*$', fm, re.M)
    if tm:
        out['title'] = tm.group(1).strip()
    return out


def url_from_stem(stem):
    """由 _posts 文件名 stem 读 front-matter,按 permalink 拼完整 URL。"""
    path = os.path.join(POSTS_DIR, stem + '.md')
    if not os.path.exists(path):
        return None
    fm = parse_fm(open(path, encoding='utf-8').read())
    if not fm.get('year'):
        return None
    # permalink 的 :title 用的是文件名(hexo 默认 new_post_name :title.md),即 stem
    title_slug = fm.get('title') or stem
    p = (PERMALINK
         .replace(':year', fm['year']).replace(':month', fm['month'])
         .replace(':day', fm['day']).replace(':title', title_slug))
    p = p.strip('/')
    return f'{SITE}/{p}/'


def collect_urls_from_new_posts():
    f = os.path.join(ROOT, '.new-posts.txt')
    if not os.path.exists(f):
        return []
    stems = [l.strip() for l in open(f, encoding='utf-8') if l.strip()]
    urls = []
    for s in stems:
        u = url_from_stem(s)
        if u:
            urls.append(u)
        else:
            print(f'::warning::无法为 {s} 拼出 URL,跳过')
    return urls


def push(urls):
    urls = [u.strip() for u in urls if u.strip()]
    if not urls:
        print('没有要推送的 URL,跳过')
        return
    if not TOKEN:
        print('未设置 BAIDU_PUSH_TOKEN,跳过百度推送')
        return
    print('待推送 URL:')
    for u in urls:
        print('  ' + u)
    data = '\n'.join(urls).encode('utf-8')
    api = f'http://data.zz.baidu.com/urls?site={SITE}&token={TOKEN}'
    req = urllib.request.Request(api, data=data,
                                 headers={'Content-Type': 'text/plain'})
    try:
        resp = urllib.request.urlopen(req, timeout=30).read().decode()
        print(f'推送 {len(urls)} 条 -> 百度返回: {resp}')
    except Exception as e:
        print(f'::warning::百度推送失败(不影响发布): {type(e).__name__}: {e}')


if __name__ == '__main__':
    args = sys.argv[1:]
    urls = args if args else collect_urls_from_new_posts()
    push(urls)
