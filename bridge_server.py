#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================
# AHPAL 面板橋接服務 v1.1
# ============================================================

import http.server
import json
import subprocess
import os
import sys
import time

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

PORT = 8888
PENDING_FILE = "pending-articles.json"
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
SCRIPT_PATH = os.path.join(PROJECT_ROOT, "scripts", "add-articles.ps1")

class AHPALBridgeHandler(http.server.SimpleHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def do_POST(self):
        if self.path == "/trigger":
            try:
                content_length = int(self.headers.get('Content-Length', 0))
                post_data = self.rfile.read(content_length).decode('utf-8')
                data = json.loads(post_data)
                articles = data.get('articles', [])

                if not articles:
                    self._send_response(400, {"status": "error", "message": "沒有文章資料"})
                    return

                print(f"📥 收到 {len(articles)} 篇文章")

                formatted_articles = []
                for a in articles:
                    title = a.get('title') or a.get('keyword', '')
                    category = a.get('categoryLabel') or a.get('category', '')
                    formatted_articles.append({
                        "keyword": title,
                        "title": title,
                        "category": category
                    })

                pending_path = os.path.join(PROJECT_ROOT, "data", PENDING_FILE)
                with open(pending_path, 'w', encoding='utf-8') as f:
                    json.dump(formatted_articles, f, ensure_ascii=False, indent=2)
                print(f"✅ 已寫入 data/pending-articles.json")

                # 執行 add-articles.ps1
                print(f"▶️ 執行 add-articles.ps1")
                result = subprocess.run([
                    "powershell.exe",
                    "-ExecutionPolicy", "Bypass",
                    "-File", SCRIPT_PATH
                ], input="y\n", capture_output=True, text=True, encoding="utf-8", errors="ignore", cwd=PROJECT_ROOT)

                # 執行文章生成
                print(f"▶️ 執行文章生成")
                gen_result = subprocess.run([
                    "python", "-X", "utf8", "src/main.py"
                ], capture_output=True, text=True, encoding="utf-8", errors="ignore", cwd=PROJECT_ROOT)

                response = {
                    "status": "ok",
                    "total": len(articles),
                    "message": "文章已成功生成",
                    "add_output": result.stdout[-500:] if result.stdout else "",
                    "gen_output": gen_result.stdout[-500:] if gen_result.stdout else ""
                }
                self._send_response(200, response)

            except Exception as e:
                self._send_response(500, {"status": "error", "message": str(e)})
        else:
            self.send_response(404)
            self.end_headers()

    def _send_response(self, code, data):
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode('utf-8'))

def main():
    print("🦞 AHPAL 面板橋接服務 v1.1")
    print(f"🌐 服務啟動中... http://localhost:{PORT}")
    print("📌 按 Ctrl+C 停止服務")
    try:
        httpd = http.server.HTTPServer(("", PORT), AHPALBridgeHandler)
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 服務已停止")
        sys.exit(0)

if __name__ == "__main__":
    main()
