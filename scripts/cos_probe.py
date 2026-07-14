#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""一次性诊断:验证 COS 密钥对指定桶的读写能力。
依次测 list / put / get / delete,任一失败打印错误但继续,最后汇总。
环境变量:COS_SECRET_ID / COS_SECRET_KEY / COS_REGION / COS_BUCKET
退出码:全部通过 0,否则 1。
"""
import os, sys
from qcloud_cos import CosConfig, CosS3Client
from qcloud_cos.cos_exception import CosServiceError, CosClientError

REGION = os.environ.get('COS_REGION', 'ap-guangzhou')
BUCKET = os.environ['COS_BUCKET']
SID = os.environ['COS_SECRET_ID']
SKEY = os.environ['COS_SECRET_KEY']
KEY = '_probe/rw-check.txt'   # 测试对象,测完删除

client = CosS3Client(CosConfig(Region=REGION, SecretId=SID, SecretKey=SKEY, Scheme='https'))
results = {}


def run(name, fn):
    try:
        fn()
        results[name] = 'OK'
        print(f'[{name}] OK')
    except (CosServiceError, CosClientError) as e:
        code = getattr(e, 'get_error_code', lambda: '')() if hasattr(e, 'get_error_code') else ''
        results[name] = f'FAIL {code}'
        print(f'[{name}] FAIL: {code} {e}')
    except Exception as e:
        results[name] = f'FAIL {type(e).__name__}'
        print(f'[{name}] FAIL: {type(e).__name__}: {e}')


print(f'== 目标桶: {BUCKET} @ {REGION} ==')
run('LIST (读)', lambda: client.list_objects(Bucket=BUCKET, MaxKeys=5))
run('PUT  (写)', lambda: client.put_object(Bucket=BUCKET, Key=KEY,
                                           Body=b'cos read-write probe'))
run('GET  (读)', lambda: client.get_object(Bucket=BUCKET, Key=KEY)['Body']
    .get_raw_stream().read())
run('DELETE(写)', lambda: client.delete_object(Bucket=BUCKET, Key=KEY))

print('\n== 汇总 ==')
for k, v in results.items():
    print(f'  {k}: {v}')
readable = results.get('LIST (读)') == 'OK' and results.get('GET  (读)') == 'OK'
writable = results.get('PUT  (写)') == 'OK' and results.get('DELETE(写)') == 'OK'
print(f'\n结论: 可读={readable}  可写={writable}')
sys.exit(0 if (readable and writable) else 1)
