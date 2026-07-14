#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从腾讯云 COS 的 posts/ 前缀拉取 markdown 文章到 source/_posts,带三层去重:
  1) 增量:对比 .cos-sync-state.json 里记录的 key->ETag,只拉新增/变更的对象
  2) 内容级:对拉下来的正文算 sha256,与已入库文章(及本轮已写入)比对,相同则跳过
  3) 标题冲突:解析 front-matter 的 title,与现有文章标题撞车时给文件名加后缀

环境变量(GitHub Actions 注入):
  COS_SECRET_ID / COS_SECRET_KEY  子用户只读密钥
  COS_REGION   默认 ap-hongkong
  COS_BUCKET   默认 xiaohang-1403701833
  COS_PREFIX   默认 posts/

退出码 0。是否有新增通过 stdout 的 "CHANGED=1/0" 供 workflow 判断。
"""
import os, sys, re, json, hashlib, io

from qcloud_cos import CosConfig, CosS3Client

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POSTS_DIR = os.path.join(ROOT, 'source', '_posts')
PAGES_DIR = os.path.join(ROOT, 'source', 'pages')  # 纯 .html 独立静态页(skip_render)
STATE_FILE = os.path.join(ROOT, '.cos-sync-state.json')

REGION = os.environ.get('COS_REGION', 'ap-hongkong')
BUCKET = os.environ.get('COS_BUCKET', 'xiaohang-1403701833')
PREFIX = os.environ.get('COS_PREFIX', 'posts/')
SID = os.environ['COS_SECRET_ID']
SKEY = os.environ['COS_SECRET_KEY']


def log(m):
    print(m, flush=True)


def load_state():
    if os.path.exists(STATE_FILE):
        try:
            return json.load(open(STATE_FILE, encoding='utf-8'))
        except Exception:
            pass
    return {'objects': {}}  # key -> {etag, sha256, filename}


def save_state(state):
    json.dump(state, open(STATE_FILE, 'w', encoding='utf-8'),
              ensure_ascii=False, indent=2, sort_keys=True)


def body_sha256(text):
    """去掉 front-matter 后对正文算 hash,避免仅 date/updated 改动被当成内容变化。"""
    m = re.match(r'^---\n.*?\n---\n?(.*)$', text, re.S)
    body = m.group(1) if m else text
    return hashlib.sha256(body.strip().encode('utf-8')).hexdigest()


def parse_title(text):
    m = re.match(r'^---\n(.*?)\n---', text, re.S)
    if not m:
        return None
    tm = re.search(r'^title:\s*["\']?(.+?)["\']?\s*$', m.group(1), re.M)
    return tm.group(1).strip() if tm else None


# ────────────────────────────────────────────────────────────────
# HTML -> Hexo Markdown 文章
# 针对 SEO 生成流程产出的成品 HTML(<article><main> 正文 + <meta> 元数据
# + pygments/codehilite 代码块),自动抽正文转 Markdown、拼 front-matter,
# 使其成为进首页/分类/sitemap 的正式文章,而非独立静态页。
# ────────────────────────────────────────────────────────────────
import html as _html


def _meta(src, name, attr='name'):
    m = re.search(rf'<meta {attr}="{re.escape(name)}" content="([^"]*)"', src)
    return _html.unescape(m.group(1)) if m else ''


def _yaml_escape(s):
    """front-matter 标量值:含特殊字符时用双引号包裹并转义。"""
    s = (s or '').strip().replace('\n', ' ')
    if s and re.search(r'[:#\[\]{},&*!|>\'"%@`]', s):
        return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'
    return s


def html_to_markdown_post(src, key, default_date):
    """把成品 HTML 转成带 front-matter 的 Markdown 文本;无法识别正文时返回 None。"""
    # 1) 元数据
    description = _meta(src, 'description')
    pub = _meta(src, 'article:published_time', 'name') or default_date
    pub = pub.strip()[:10] or default_date
    # keywords -> tags(逗号分隔,可能为空)
    kw = _meta(src, 'keywords')
    tags = [t.strip() for t in re.split(r'[,，]', kw) if t.strip()]

    # 标题:优先 og:title / <h1> / <title>
    title = (_meta(src, 'og:title', 'property')
             or _meta(src, 'title', 'property'))
    if not title:
        h1 = re.search(r'<h1[^>]*>(.*?)</h1>', src, re.S)
        title = re.sub(r'<[^>]+>', '', h1.group(1)).strip() if h1 else ''
    if not title:
        tt = re.search(r'<title>(.*?)</title>', src, re.S)
        title = re.sub(r'<[^>]+>', '', tt.group(1)).strip() if tt else 'Untitled'
    title = _html.unescape(title)

    # 2) 正文容器:<main> 优先,退化到 <article> / <body>
    for pat in (r'<main[^>]*>(.*)</main>',
                r'<article[^>]*>(.*)</article>',
                r'<body[^>]*>(.*)</body>'):
        mm = re.search(pat, src, re.S)
        if mm:
            body = mm.group(1)
            break
    else:
        return None

    # 3) 代码块:先抽出占位保护,避免后续去标签误伤代码里的 < >
    blocks = []

    def stash_code(m):
        inner = re.sub(r'<br\s*/?>', '\n', m.group(1))
        inner = re.sub(r'<[^>]+>', '', inner)      # 剥 span
        code = _html.unescape(inner)
        lang = 'java'
        if re.search(r'^\s*#|application\.ya?ml|spring:', code) and ';' not in code:
            lang = 'yaml'
        blocks.append(f'```{lang}\n' + code.strip('\n') + '\n```')
        return f'\n\x00CODE{len(blocks) - 1}\x00\n'

    body = re.sub(r'<div class="codehilite"><pre>(.*?)</pre></div>',
                  stash_code, body, flags=re.S)
    body = re.sub(r'<pre[^>]*><code[^>]*>(.*?)</code></pre>',
                  stash_code, body, flags=re.S)

    # 行内 code
    body = re.sub(r'<code>(.*?)</code>',
                  lambda m: '`' + _html.unescape(re.sub(r'<[^>]+>', '', m.group(1))) + '`',
                  body, flags=re.S)

    # 表格
    def conv_table(m):
        t = m.group(0)
        heads = [_html.unescape(re.sub(r'<[^>]+>', '', h)).strip()
                 for h in re.findall(r'<th[^>]*>(.*?)</th>', t, re.S)]
        out = []
        if heads:
            out.append('| ' + ' | '.join(heads) + ' |')
            out.append('| ' + ' | '.join('---' for _ in heads) + ' |')
        for r in re.findall(r'<tr[^>]*>(.*?)</tr>', t, re.S):
            tds = re.findall(r'<td[^>]*>(.*?)</td>', r, re.S)
            if not tds:
                continue
            cells = [_html.unescape(re.sub(r'<[^>]+>', '', c)).strip().replace('\n', ' ')
                     for c in tds]
            out.append('| ' + ' | '.join(cells) + ' |')
        return '\n' + '\n'.join(out) + '\n'

    body = re.sub(r'<table>.*?</table>', conv_table, body, flags=re.S)

    def inline(s):
        s = re.sub(r'<strong>(.*?)</strong>', r'**\1**', s, flags=re.S)
        s = re.sub(r'<b>(.*?)</b>', r'**\1**', s, flags=re.S)
        s = re.sub(r'<em>(.*?)</em>', r'*\1*', s, flags=re.S)
        s = re.sub(r'<a [^>]*href="([^"]*)"[^>]*>(.*?)</a>', r'[\2](\1)', s, flags=re.S)
        s = re.sub(r'<br\s*/?>', '  \n', s)
        return s

    for lvl in (4, 3, 2):
        body = re.sub(rf'<h{lvl}[^>]*>(.*?)</h{lvl}>',
                      lambda m, l=lvl: f'\n{"#" * l} ' + inline(m.group(1)).strip() + '\n',
                      body, flags=re.S)
    body = re.sub(r'<img [^>]*alt="([^"]*)"[^>]*src="([^"]*)"[^>]*>', r'![\1](\2)', body)
    body = re.sub(r'<img [^>]*src="([^"]*)"[^>]*alt="([^"]*)"[^>]*>', r'![\2](\1)', body)
    body = re.sub(r'<img [^>]*src="([^"]*)"[^>]*>', r'![](\1)', body)

    def conv_bq(m):
        inner = re.sub(r'</?p>', '', inline(m.group(1))).strip()
        return '\n' + '\n'.join('> ' + ln for ln in inner.split('\n')) + '\n'

    body = re.sub(r'<blockquote>(.*?)</blockquote>', conv_bq, body, flags=re.S)
    body = re.sub(r'<ul>(.*?)</ul>',
                  lambda m: '\n' + '\n'.join('- ' + inline(i).strip().replace('\n', ' ')
                                             for i in re.findall(r'<li>(.*?)</li>', m.group(1), re.S)) + '\n',
                  body, flags=re.S)
    body = re.sub(r'<ol>(.*?)</ol>',
                  lambda m: '\n' + '\n'.join(f'{n}. ' + inline(i).strip().replace('\n', ' ')
                                             for n, i in enumerate(re.findall(r'<li>(.*?)</li>', m.group(1), re.S), 1)) + '\n',
                  body, flags=re.S)
    body = re.sub(r'<p>(.*?)</p>',
                  lambda m: '\n' + inline(m.group(1)).strip() + '\n', body, flags=re.S)
    body = re.sub(r'<hr\s*/?>', '\n---\n', body)
    body = re.sub(r'<[^>]+>', '', body)            # 去残留标签
    body = _html.unescape(body)
    body = re.sub(r'\x00CODE(\d+)\x00', lambda m: blocks[int(m.group(1))], body)  # 填回代码
    body = re.sub(r'\n{3,}', '\n\n', body).strip()

    fm = ['---', f'title: {_yaml_escape(title)}',
          f'date: {pub} 00:00:00', 'categories:', '  - 技术随笔']
    if tags:
        fm.append('tags:')
        fm += [f'  - {_yaml_escape(t)}' for t in tags]
    if description:
        fm.append(f'description: {_yaml_escape(description)}')
    fm.append('---')
    return '\n'.join(fm) + '\n\n' + body + '\n'


def existing_index():
    """扫已入库文章 -> (正文 hash 集合, 标题->文件名, 文件名集合)。"""
    hashes, titles, names = set(), {}, set()
    if not os.path.isdir(POSTS_DIR):
        os.makedirs(POSTS_DIR, exist_ok=True)
        return hashes, titles, names
    for fn in os.listdir(POSTS_DIR):
        if not fn.endswith('.md'):
            continue
        names.add(fn)
        try:
            t = open(os.path.join(POSTS_DIR, fn), encoding='utf-8').read()
        except Exception:
            continue
        hashes.add(body_sha256(t))
        ti = parse_title(t)
        if ti:
            titles.setdefault(ti, fn)
    return hashes, titles, names


def safe_filename(key, title, used_names):
    """由 COS key 的 basename 生成文件名;标题/文件名冲突时加数字后缀。
    .html/.htm 等成品页统一落成 .md(去掉原扩展名)。"""
    base = os.path.basename(key)
    base = re.sub(r'\.html?$', '', base, flags=re.I)  # 剥 .html/.htm
    if not base.endswith('.md'):
        base += '.md'
    stem, ext = base[:-3], '.md'
    cand = base
    i = 1
    while cand in used_names:
        cand = f'{stem}-{i}{ext}'
        i += 1
    return cand


def list_cos_objects(client):
    """分页列出 PREFIX 下所有 .md / .html 对象 -> [(key, etag)]。

    .md   -> 直接作为 Hexo 文章
    .html -> 成品页,自动转成带 front-matter 的 Markdown 文章
    两者最终都进首页/分类/sitemap。
    """
    out = []
    marker = ''
    while True:
        resp = client.list_objects(Bucket=BUCKET, Prefix=PREFIX,
                                   Marker=marker, MaxKeys=1000)
        for c in resp.get('Contents', []):
            key = c['Key']
            k = key.lower()
            if key.endswith('/') or not (k.endswith('.md') or k.endswith('.html')):
                continue
            out.append((key, c['ETag'].strip('"')))
        if resp.get('IsTruncated') == 'true':
            marker = resp.get('NextMarker', '')
        else:
            break
    return out


def main():
    cfg = CosConfig(Region=REGION, SecretId=SID, SecretKey=SKEY, Scheme='https')
    client = CosS3Client(cfg)

    state = load_state()
    seen = state.get('objects', {})
    ex_hashes, ex_titles, ex_names = existing_index()

    objs = list_cos_objects(client)
    log(f'COS posts/ 共 {len(objs)} 个 md 对象')

    changed = 0
    skipped_unchanged = skipped_dup = 0
    new_seen = {}
    written_files = []  # 本轮实际写入的文件名(用于发布后推送百度)

    for key, etag in objs:
        prev = seen.get(key)
        # 第 1 层:ETag 没变 -> 增量跳过
        if prev and prev.get('etag') == etag:
            new_seen[key] = prev
            skipped_unchanged += 1
            continue

        resp = client.get_object(Bucket=BUCKET, Key=key)
        raw = resp['Body'].get_raw_stream().read().decode('utf-8')

        # ── .html 成品页 -> 自动转成带 front-matter 的 Markdown 正式文章 ──
        if key.lower().endswith('.html'):
            default_date = '2026-01-01'
            md = html_to_markdown_post(raw, key, default_date)
            if not md:
                log(f'  [html-skip] {key} 未能解析出正文(无 main/article/body),跳过')
                new_seen[key] = {'etag': etag}
                continue
            text = md  # 交给下面统一的 md 去重/写入逻辑
        else:
            text = raw
        h = body_sha256(text)

        # 第 2 层:内容 hash 命中已有 -> 内容级去重
        if h in ex_hashes:
            log(f'  [dup-content] {key} 正文与已有文章相同,跳过')
            new_seen[key] = {'etag': etag, 'sha256': h,
                             'filename': (prev or {}).get('filename')}
            skipped_dup += 1
            continue

        # 第 3 层:标题冲突 -> 文件名加后缀(不覆盖已有不同内容的同名/同标题)
        title = parse_title(text)
        # 若该 key 之前已写过某文件名,优先复用它(更新场景,原地覆盖)
        fn = (prev or {}).get('filename')
        if fn and fn in ex_names:
            target = fn  # 覆盖更新
        else:
            fn = safe_filename(key, title, ex_names)
            target = fn
            ex_names.add(fn)

        open(os.path.join(POSTS_DIR, target), 'w', encoding='utf-8').write(text)
        ex_hashes.add(h)
        written_files.append(target)
        if title:
            ex_titles.setdefault(title, target)
        new_seen[key] = {'etag': etag, 'sha256': h, 'filename': target}
        log(f'  [write] {key} -> source/_posts/{target}'
            + (f'  (title="{title}")' if title else ''))
        changed += 1

    state['objects'] = new_seen
    save_state(state)

    # 记录本轮新增/更新的文件名 stem(供发布后拼 URL 主动推送百度)
    new_stems = [os.path.splitext(t)[0] for t in written_files]
    with open(os.path.join(ROOT, '.new-posts.txt'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_stems))

    log(f'\n新增/更新 {changed} 篇 | 增量跳过 {skipped_unchanged} | 内容去重 {skipped_dup}')
    print(f'CHANGED={1 if changed else 0}')
    # 供 GitHub Actions 读取
    gh_out = os.environ.get('GITHUB_OUTPUT')
    if gh_out:
        with open(gh_out, 'a') as f:
            f.write(f'changed={1 if changed else 0}\n')
            f.write(f'count={changed}\n')


if __name__ == '__main__':
    main()
