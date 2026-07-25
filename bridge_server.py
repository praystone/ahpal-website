#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================
# AHPAL 面板橋接服務 v1.0
# 功能：接收面板指令 → 寫入 pending-articles.json → 觸發 PowerShell
# 作者：龍蝦總工程師（DeepSeek）
# ============================================================

import http.server
import json
import subprocess
import os
import sys
import time
from pathlib import Path

# 設定
PORT = 8888
PENDING_FILE = "pending-articles.json"
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
SCRIPT_PATH = os.path.join(PROJECT_ROOT, "scripts", "process-pending.ps1")

class AHPALBridgeHandler(http.server.SimpleHTTPRequestHandler):
    """處理面板傳來的請求"""

    def do_OPTIONS(self):
        """處理 CORS 預檢請求"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def do_GET(self):
        """處理 GET 請求：回報服務狀態"""
        if self.path == "/status":
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            status = {
                "status": "online",
                "version": "1.0",
                "pending_file_exists": os.path.exists(PENDING_FILE),
                "script_exists": os.path.exists(SCRIPT_PATH)
            }
            self.wfile.write(json.dumps(status, ensure_ascii=False).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        """處理 POST 請求：接收文章資料並觸發生成"""
        if self.path == "/trigger":
            try:
                # 1. 讀取請求內容
                content_length = int(self.headers.get('Content-Length', 0))
                post_data = self.rfile.read(content_length).decode('utf-8')
                data = json.loads(post_data)

                # 2. 驗證資料
                articles = data.get('articles', [])
                if not articles:
                    self._send_response(400, {"status": "error", "message": "沒有文章資料"})
                    return

                # 3. 寫入 pending-articles.json
                pending_data = {
                    "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
                    "total": len(articles),
                    "articles": articles
                }

                pending_path = os.path.join(PROJECT_ROOT, PENDING_FILE)
                with open(pending_path, 'w', encoding='utf-8') as f:
                    json.dump(pending_data, f, ensure_ascii=False, indent=2)

                # 4. 觸發 PowerShell 橋接腳本
                result = subprocess.run([
                    "powershell.exe",
                    "-ExecutionPolicy", "Bypass",
                    "-File", SCRIPT_PATH
                ], capture_output=True, text=True, cwd=PROJECT_ROOT)

                # 5. 回應結果
                response = {
                    "status": "ok",
                    "total": len(articles),
                    "message": "文章已加入生成佇列",
                    "powershell_output": result.stdout,
                    "powershell_error": result.stderr if result.stderr else None
                }
                self._send_response(200, response)

            except json.JSONDecodeError as e:
                self._send_response(400, {"status": "error", "message": f"JSON 格式錯誤: {str(e)}"})
            except Exception as e:
                self._send_response(500, {"status": "error", "message": str(e)})
        else:
            self.send_response(404)
            self.end_headers()

    def _send_response(self, code, data):
        """發送 JSON 回應"""
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode('utf-8'))

def main():
    """啟動服務"""
    print("🦞 AHPAL 面板橋接服務 v1.0")
    print("========================================")
    print(f"📂 專案目錄: {PROJECT_ROOT}")
    print(f"📄 腳本路徑: {SCRIPT_PATH}")
    print(f"📋 待生成檔案: {os.path.join(PROJECT_ROOT, PENDING_FILE)}")
    print("========================================")

    # 檢查腳本是否存在
    if not os.path.exists(SCRIPT_PATH):
        print("⚠️ 警告: process-pending.ps1 不存在，請先建立橋接腳本")
    else:
        print("✅ 橋接腳本已就位")

    print(f"🌐 服務啟動中... http://localhost:{PORT}")
    print("📌 請在面板中設定 API 地址為: http://localhost:8888/trigger")
    print("📌 按 Ctrl+C 停止服務")
    print("========================================")

    try:
        handler = AHPALBridgeHandler
        httpd = http.server.HTTPServer(("", PORT), handler)
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 服務已停止")
        sys.exit(0)
    except Exception as e:
        print(f"❌ 啟動失敗: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
