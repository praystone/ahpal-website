# ============================================================
# youtube_lm.py - YouTube + LM 整合處理模組 v1.0
# ============================================================
# 用途：從 YouTube 提取資訊，透過 LM 生成分析文章
# ============================================================

import os
import re
import sys
import argparse
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from src.config import OUTPUT_DIR
from src.api_client import call_api


def extract_video_id(url):
    """從 YouTube URL 提取影片 ID"""
    patterns = [
        r'(?:youtube\.com\/watch\?v=)([\w-]+)',
        r'(?:youtu\.be\/)([\w-]+)',
        r'(?:youtube\.com\/embed\/)([\w-]+)',
        r'(?:youtube\.com\/shorts\/)([\w-]+)'
    ]
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return None


def get_video_info(video_id):
    """獲取影片資訊（待整合 YouTube Data API）"""
    # TODO: 整合 YouTube Data API
    return {
        'title': f'影片標題 (ID: {video_id})',
        'description': '影片描述內容...',
        'channel': '頻道名稱',
        'duration': '10:30'
    }


def generate_analysis(video_info):
    """使用 LM 生成影片分析文章"""
    prompt = f"""
    請根據以下影片資訊生成一篇完整的 SEO 文章。

    影片標題：{video_info['title']}
    影片描述：{video_info['description']}
    頻道名稱：{video_info['channel']}

    請生成包含 H1、H2 結構的完整 HTML 文章，至少 1500 字。
    """
    system_prompt = "你是專業的內容分析師，擅長從影片內容中提取重點並轉化為高品質文章。"
    return call_api(prompt, system_prompt=system_prompt, max_tokens=8192)


def main():
    parser = argparse.ArgumentParser(description='YouTube + LM 整合處理')
    parser.add_argument('--url', required=True, help='YouTube 影片網址')
    parser.add_argument('--action', default='analyze', choices=['analyze', 'summarize'])
    args = parser.parse_args()

    print(f"🎬 處理影片：{args.url}")

    video_id = extract_video_id(args.url)
    if not video_id:
        print("❌ 無法提取影片 ID")
        return

    print(f"   📌 影片 ID：{video_id}")
    video_info = get_video_info(video_id)
    print(f"   📌 標題：{video_info['title']}")

    print("   🤖 正在生成分析文章...")
    content = generate_analysis(video_info)

    output_path = Path(OUTPUT_DIR) / "trend" / f"youtube-{video_id}.html"
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"   ✅ 已輸出：{output_path}")


if __name__ == "__main__":
    main()