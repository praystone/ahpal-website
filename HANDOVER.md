沒問題！以下是根據你目前最新狀態（**文章總數 2184 篇、遊戲 25 款、MASTER v8.6**）全面更新的 `README.md` 和 `HANDOVER.md`：

---

## 📁 根目錄 `README.md`（完整更新版）

```markdown
# 🏠 雅寶社區 · 頂客論壇 (AHPAL.COM)

> 歲月 · 知識 · 共創 — 二十五載歲月迴聲，AI 精選九大領域實用內容。

---

## 📖 專案簡介

雅寶社區 · 頂客論壇是一個結合 **3C 科技教學、遊戲攻略、生活小常識、軟體評測、人生哲理、AI 趨勢、音樂創作、歷史腦洞、動植物生態** 九大領域的知識型網站。透過 AI 輔助生成高品質文章，提供讀者真正有價值的資訊。

---

## 🏗️ 專案結構

```
ahpal-static/
├── scripts/                         # PowerShell 腳本（核心 10+ 個）
│   ├── ahpal-master.ps1             # ⭐ 萬能總指揮 v8.6（主入口）
│   ├── ahpal-static.ps1             # 環境設定
│   ├── add-articles.ps1             # ⭐ JSON 驅動新增文章
│   ├── generate-games.ps1           # 遊戲生成（25 款）
│   ├── backup-system.ps1            # 統一備份工具
│   ├── check-all.ps1                # 全面系統檢查
│   ├── preflight-check.ps1          # 🔴 死命令強制檢查
│   ├── analyze-directory.ps1        # 📊 目錄深度分析
│   ├── sync-to-gdrive.ps1           # Rclone 雲端同步
│   └── ai-handover-scan.ps1         # 🤖 AI 系統交接掃描
│
├── src/                             # Python 原始碼（11 個模組）
│   ├── main.py                      # 主程式入口 (v6.2)
│   ├── config.py                    # 設定管理
│   ├── api_client.py                # API 客戶端（雙 API 切換）
│   ├── article_generator.py         # 文章生成核心
│   ├── html_builder.py              # HTML 建構 (v7.4)
│   ├── quality_checker.py           # 品質檢查
│   ├── sitemap_builder.py           # Sitemap 建構
│   └── state_manager.py             # 狀態管理（斷點續傳）
│
├── data/                            # 文章清單
│   └── master-articles.json         # ⭐ 主文章清單（1740+ 篇）
│
├── ahpal-static/                    # 🌐 網站輸出目錄
│   ├── index.html                   # 首頁
│   ├── categories.html              # 全部分類
│   ├── sitemap.xml                  # Sitemap（2221 個 URL）
│   ├── history/                     # 📜 歷史腦洞（511 篇）
│   ├── tech/                        # 💻 3C 科技教學（93 篇）
│   ├── game/                        # 🎮 遊戲攻略（25 篇 + 25 款遊戲）
│   ├── life/                        # 🏠 生活小常識（472 篇）
│   ├── review/                      # 📊 軟體評測（79 篇）
│   ├── philosophy/                  # 🌟 人生哲理（77 篇）
│   ├── trend/                       # 🤖 AI 趨勢（64 篇）
│   ├── music/                       # 🎵 音樂創作（11 篇）
│   └── nature/                      # 🌳 動植物生態（793 篇）
│
├── ahpal-AI-archive/                # 🗄️ AI 檔案館（備份）
├── backups/                         # 自動備份目錄
├── docs/                            # 技術文件
├── .env                             # 🔑 API Key（不上傳 Git）
├── .env.template                    # 環境變數範本
├── .gitignore                       # Git 忽略規則
├── LICENSE                          # 📄 MIT 授權條款
├── README.md                        # 本文件
└── HANDOVER.md                      # 交接文件
```

---

## 🚀 快速啟動

### 1. 環境設定

```powershell
# 複製環境變數範本
cd C:\Users\User\ahpal-static
Copy-Item .env.template .env

# 編輯 .env，填入 API Key
notepad .env
```

### 2. 執行主程式

```powershell
cd C:\Users\User\ahpal-static
.\scripts\ahpal-master.ps1
```

### 3. 常用選單功能

| 選項 | 功能 |
|------|------|
| `[1]` | 完整流程（備份 + 處理待新增 + 生成 + Git + 部署）|
| `[2]` | 快速更新（處理待新增 + 生成 + Git + 部署）|
| `[3]` | 只生成遊戲（不耗 API）|
| `[4]` | 只生成文章（遊戲 + 處理待新增 + 文章，不部署）|
| `[5]` | 只做備份 |
| `[6]` | 只做 Git + 部署 |
| `[7]` | 檢查文章狀態 |
| `[8]` | 查看系統狀態 |
| `[9]` | 📊 目錄深度分析 |
| `[S]` | SEO 基礎檔案驗證 |
| `[E]` | 完整 SEO 檢查 |
| `[H]` | 🤖 AI 系統交接掃描 |
| `[T]` | 🛠️ 系統工具整合器 |
| `[W]` | 📡 產線健康監控 |
| `[F]` | 🔍 SEO 爬蟲防線 |
| `[A]` | 📝 內容品質審查 |
| `[D]` | 📊 SEO 數據彙整 |
| `[G]` | 🔧 強制使用 Gemini |
| `[K]` | 🔧 強制使用 DeepSeek |
| `[B]` | 🔄 恢復自動切換模式 |

---

## 🤖 API 切換邏輯

| 時段 | 自動模式 | 說明 |
|------|---------|------|
| 尖峰 09:00-18:00 | Gemini | 免費方案 |
| 離峰 18:00-09:00 | DeepSeek | 成本低 |

---

## 📊 目前成果（2026-08-23）

| 項目 | 數值 |
|------|------|
| 總文章數 | **2,184 篇** |
| 遊戲數量 | **25 款** |
| Sitemap URL | **2,221 個** |
| 平均品質分數 | **82.6 分** |
| MASTER 版本 | **v8.6** |

### 各分類統計

| 分類 | 篇數 |
|------|------|
| 📜 歷史腦洞 | 511 篇 |
| 🌳 動植物生態 | 793 篇 |
| 🏠 生活小常識 | 472 篇 |
| 💻 3C 科技教學 | 93 篇 |
| 📊 軟體評測 | 79 篇 |
| 🌟 人生哲理 | 77 篇 |
| 🤖 AI 趨勢 | 64 篇 |
| 🎮 遊戲攻略 | 25 篇 |
| 🎵 音樂創作 | 11 篇 |

---

## 🔧 故障排除

### 檢查 API 錯誤文章

```powershell
findstr /s /i /m "429 503 RESOURCE_EXHAUSTED" *.html
```

### Cloudflare 部署失敗

```powershell
npx wrangler pages deploy . --project-name=ahpal-pages
```

### Git 推送被拒絕

```powershell
git pull --rebase
git push
```

### 死命令檢查

```powershell
.\scripts\preflight-check.ps1
```

---

## 🔗 連結

| 環境 | 網址 |
|------|------|
| 正式網站 | https://www.ahpal.com/ |
| Cloudflare Pages | https://main.ahpal-pages.pages.dev |
| 遊戲間 | https://www.ahpal.com/game/ |
| GitHub | https://github.com/praystone/ahpal-website |

---

## 📄 相關文件

| 文件 | 說明 |
|------|------|
| `HANDOVER.md` | 完整交接手冊（給下一位維護者 / AI）|
| `docs/` | 技術文件目錄 |
| `LICENSE` | MIT 授權條款 |

---

**© 2026 雅寶社區 · 頂客論壇 (AHPAL.COM)**
```

---

## 📁 根目錄 `HANDOVER.md`（完整更新版）

```markdown
# 📋 AHPAL.COM 專案交接文件

> 給下一位維護者 / AI 的完整交接手冊

---

## 📌 基本資訊

| 項目 | 內容 |
|------|------|
| 專案名稱 | 雅寶社區 · 頂客論壇 (AHPAL.COM) |
| 專案路徑 | `C:\Users\User\ahpal-static` |
| AI 檔案館 | `C:\Users\User\ahpal-AI-archive` |
| 網站網址 | https://www.ahpal.com/ |
| 當前分支 | `main` |
| 當前版本 | **v12.0** |
| MASTER 版本 | **v8.6** |
| 總文章數 | **2,184 篇** |
| 遊戲數量 | **25 款** |

---

## 🏗️ 專案結構

```
ahpal-static/
├── scripts/          # PowerShell 腳本（核心 10+ 個）
├── src/              # Python 原始碼（11 個模組）
├── data/             # master-articles.json（1740+ 篇）
├── ahpal-static/     # 🌐 網站輸出（2,184 篇文章 + 25 款遊戲）
├── ahpal-AI-archive/ # 🗄️ AI 檔案館（備份）
├── backups/          # 自動備份目錄
├── docs/             # 技術文件
├── .env              # 🔑 API Key（重要！不上傳 Git）
├── .env.template     # 環境變數範本
├── LICENSE           # MIT 授權條款
└── build-state.json  # 構建狀態
```

---

## 🚀 快速啟動

```powershell
# 進入專案
cd C:\Users\User\ahpal-static

# 執行主程式（互動式選單）
.\scripts\ahpal-master.ps1

# 或直接執行完整流程
.\scripts\ahpal-master.ps1 -Action full

# 或跳過死命令檢查
.\scripts\ahpal-master.ps1 -Action full -SkipPreflight
```

---

## 🎮 MASTER v8.6 選單功能

### 主要功能

| 選項 | 功能 | 說明 |
|------|------|------|
| `[1]` | 完整流程 | 備份 + 處理待新增 + 生成 + Git + 部署 |
| `[2]` | 快速更新 | 處理待新增 + 生成 + Git + 部署（跳過備份）|
| `[3]` | 只生成遊戲 | 不耗 API，快速 |
| `[4]` | 只生成文章 | 遊戲 + 處理待新增 + 文章，不部署 |
| `[5]` | 只做備份 | 不生成、不部署 |
| `[6]` | 只做 Git + 部署 | 不生成 |
| `[7]` | 檢查文章狀態 | 執行 `check-all.ps1 -Report` |
| `[8]` | 查看系統狀態 | 顯示文章/遊戲/Git 狀態 |
| `[9]` | 目錄深度分析 | 文章分布/大小/佔比 |

### SEO 與系統工具

| 選項 | 功能 |
|------|------|
| `[S]` | SEO 基礎檔案驗證（robots.txt / ads.txt / sitemap.xml）|
| `[E]` | 完整 SEO 檢查（含文章狀態與檔案存在性）|
| `[H]` | 🤖 AI 系統交接掃描（完整備份與報告）|
| `[T]` | 🛠️ 系統工具整合器 v5.2 |

### 產線運維四件套

| 選項 | 功能 |
|------|------|
| `[W]` | 📡 產線健康監控（日誌摘要）|
| `[F]` | 🔍 SEO 爬蟲防線（預警檢查）|
| `[A]` | 📝 內容品質審查（抽樣稽核）|
| `[D]` | 📊 SEO 數據彙整（流量日報）|

### API 強制切換

| 選項 | 功能 |
|------|------|
| `[G]` | 🔧 強制使用 Gemini |
| `[K]` | 🔧 強制使用 DeepSeek |
| `[B]` | 🔄 恢復自動切換模式 |

---

## 🐍 Python 模組說明

| 模組 | 功能 | 重要函數 |
|------|------|----------|
| `main.py` | 主入口 (v6.2) | `run_pipeline()`, `--force deepseek` |
| `config.py` | 設定管理 | `get_api_key()`, `is_peak_hour()` |
| `api_client.py` | API 客戶端 | `call_api()`, `get_current_api_info()` |
| `article_generator.py` | 文章生成 | `generate_article()`, `text_to_html()` |
| `html_builder.py` | HTML 建構 (v7.4) | `build_article_html()`, `generate_category_pages()` |
| `quality_checker.py` | 品質檢查 | `check_article_quality()`（遊戲自動排除）|
| `sitemap_builder.py` | Sitemap | `update_sitemap()` |
| `state_manager.py` | 狀態管理 | 斷點續傳 |

---

## 🤖 API 設定

### 環境變數 (.env)

```env
GEMINI_API_KEY=你的Gemini金鑰
DEEPSEEK_API_KEY=sk-你的DeepSeek金鑰
```

### API 切換邏輯

| 時段 | 自動模式 | 價格 |
|------|---------|------|
| 09:00-18:00 | Gemini | 免費 |
| 18:00-09:00 | DeepSeek | 低 |

---

## 📊 目前成果（2026-08-23）

### 總覽

| 項目 | 數值 |
|------|------|
| 總文章數 | **2,184 篇** |
| 遊戲數量 | **25 款** |
| Sitemap URL | **2,221 個** |

### 各分類統計

| 分類 | 篇數 |
|------|------|
| 📜 歷史腦洞 | 511 篇 |
| 🌳 動植物生態 | 793 篇 |
| 🏠 生活小常識 | 472 篇 |
| 💻 3C 科技教學 | 93 篇 |
| 📊 軟體評測 | 79 篇 |
| 🌟 人生哲理 | 77 篇 |
| 🤖 AI 趨勢 | 64 篇 |
| 🎮 遊戲攻略 | 25 篇 |
| 🎵 音樂創作 | 11 篇 |

---

## 🔧 故障排除

### 1. MASTER 不生成文章

```powershell
# 檢查 master-articles.json
Get-Content data/master-articles.json | ConvertFrom-Json | Measure-Object

# 手動執行 add-articles.ps1
.\scripts\add-articles.ps1

# 強制生成
python src/main.py --force deepseek
```

### 2. 檢查 API 錯誤文章

```powershell
findstr /s /i /m "429 503 RESOURCE_EXHAUSTED" *.html
```

### 3. Cloudflare 部署失敗

```powershell
npx wrangler pages deploy . --project-name=ahpal-pages
```

### 4. Git 推送被拒絕

```powershell
git pull --rebase
git push
```

### 5. 死命令檢查失敗

```powershell
.\scripts\preflight-check.ps1
# 或跳過檢查
.\scripts\ahpal-master.ps1 -Action full -SkipPreflight
```

### 6. 分類頁面文章沒有置頂

```powershell
# 執行快速更新重新生成分類頁面
.\scripts\ahpal-master.ps1
# 選擇 [2] 快速更新
```

---

## 🏛️ 災難復原

### 從 AI 檔案館還原

```powershell
# 解壓縮最新備份
Expand-Archive -Path "C:\Users\User\ahpal-AI-archive\ahpal-static-stable-*.zip" -DestinationPath "C:\Users\User\" -Force

# 還原 API Key（手動）
# 複製 .env 檔案至 ahpal-static/
```

### 從本地備份還原

```powershell
# 解壓縮最新備份
Expand-Archive -Path "C:\Users\User\ahpal-backup\*.zip" -DestinationPath "C:\Users\User\" -Force
```

---

## 🔗 重要連結

| 環境 | 網址 |
|------|------|
| 正式網站 | https://www.ahpal.com/ |
| Cloudflare Pages | https://main.ahpal-pages.pages.dev |
| 遊戲間 | https://www.ahpal.com/game/ |
| GitHub | https://github.com/praystone/ahpal-website |

---

## 📄 相關文件

| 文件 | 說明 |
|------|------|
| `README.md` | 專案簡介 |
| `LICENSE` | MIT 授權條款 |
| `docs/` | 技術文件目錄 |

---

## 📝 版本資訊

| 項目 | 內容 |
|------|------|
| 當前版本 | **v12.0** |
| MASTER 版本 | **v8.6** |
| 最後更新 | 2026-08-23 |
| 維護者 | 雅寶社區 · 頂客論壇 |
| 總文章數 | **2,184 篇** |

---

**© 2026 雅寶社區 · 頂客論壇 (AHPAL.COM)**
```

---

## 📂 檔案存放位置

```powershell
C:\Users\User\ahpal-static\
├── README.md          # ✅ 專案簡介（已更新）
├── HANDOVER.md        # ✅ 完整交接文件（已更新）
├── LICENSE            # ✅ MIT 授權條款
├── .gitignore         # ✅ Git 忽略規則
└── docs/              # 技術文件目錄
```

---

## 🚀 同步到 Git

```powershell
cd C:\Users\User\ahpal-static

git add README.md HANDOVER.md LICENSE .gitignore
git commit -m "📝 更新 README.md 和 HANDOVER.md（v12.0 / 2,184 篇文章 / MASTER v8.6）"
git push origin main

Write-Host "✅ 同步完成！" -ForegroundColor Green
```

---

需要我再調整任何細節嗎？ 🦞