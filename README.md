## 📄 完整 README.md（請全部複製）

```markdown
# 雅寶社區 · 頂客論壇 (AHPAL.COM)

**版本**：v4.2 | **文章**：202 篇 | **遊戲**：23 款 | **更新**：2026-07-20

---

## 📖 專案簡介

雅寶社區 · 頂客論壇是一個 **AI 驅動的自動化內容平台**，結合：

- 🤖 **AI 文章生成**：支援 Google Gemini（尖峰）與 DeepSeek（離峰）雙 API 自動切換
- 🎮 **HTML5 遊戲**：23 款互動遊戲，免下載即開即玩
- ⚙️ **自動化部署**：一鍵完成內容生成 → 靜態檔案輸出 → Cloudflare 部署

---

## 🚀 快速開始

### 第一次使用

```powershell
# 1. 設定環境變數（API Key）
.\ahpal-static.ps1

# 2. 執行總指揮（完整流程）
.\ahpal-master.ps1
```

### 日常更新

```powershell
# 進入網站目錄
cd C:\Users\User\ahpal-static

# 查看變更
git status

# 提交變更
git add .
git commit -m "更新說明"
git push
```

---

## 🏗️ 技術架構

| 元件 | 技術 | 用途 |
|------|------|------|
| 總指揮 | PowerShell v6.3 | 控制流程、協調各元件 |
| 環境設定 | ahpal-static.ps1 | 設定 API Key 與輸出目錄 |
| 內容生成 | Python 3（模組化） | 呼叫 AI API、生成文章 |
| AI 模型 | Gemini Flash / DeepSeek | 生成高品質繁體中文文章 |
| 靜態託管 | Cloudflare Pages | CDN 加速、SSL、無限流量 |
| 版本控制 | Git + GitHub | 原始碼備份、自動部署 |

---

## 📂 目錄結構

```
C:\Users\User\
├── ahpal-master.ps1          # 總指揮腳本 v6.3
├── ahpal-static.ps1          # 環境設定檔
├── generate-games.ps1        # 遊戲生成腳本 v2.0
├── backup-system.ps1         # 備份腳本
├── check-articles.ps1        # 文章檢查腳本
├── check-all.ps1             # 全面系統檢查
├── config.ps1                # 統一設定檔
├── README.md                 # 專案說明
├── src/                      # Python 原始碼（v4.2 模組化）
│   ├── main.py               # 主要入口
│   ├── config.py             # 設定管理
│   ├── api_client.py         # API 呼叫層（含容錯切換）
│   ├── article_generator.py  # 文章生成核心
│   ├── html_builder.py       # HTML 建構器
│   ├── quality_checker.py    # 品質檢查
│   ├── sitemap_builder.py    # Sitemap 產生器
│   ├── state_manager.py      # 狀態管理（斷點續傳）
│   ├── logger.py             # 日誌管理
│   └── __init__.py           # 套件初始化
├── ahpal-static/             # 網站輸出目錄（部署來源）
│   ├── index.html            # 首頁
│   ├── categories.html       # 全部分類
│   ├── sitemap.xml           # 網站地圖
│   ├── game/                 # 23 款遊戲 + 15 篇攻略
│   ├── tech/                 # 16 篇文章
│   ├── life/                 # 15 篇文章
│   ├── review/               # 23 篇文章
│   ├── philosophy/           # 18 篇文章
│   └── trend/                # 20 篇文章
├── docs/                     # 技術文件
│   └── AI交接與新進工程師接手手冊.html
├── logs/                     # 日誌目錄（自動產生）
└── ahpal-backup/             # 備份目錄（自動產生）
```

---

## 📋 常用指令

| 用途 | 指令 |
|------|------|
| 完整部署（推薦） | `.\ahpal-master.ps1` |
| 快速更新（跳過備份） | `.\ahpal-master.ps1` → 選 `[2]` |
| 只生成遊戲 | `.\ahpal-master.ps1` → 選 `[3]` |
| 只生成文章（不部署） | `.\ahpal-master.ps1` → 選 `[4]` |
| 只做備份 | `.\ahpal-master.ps1` → 選 `[5]` |
| 只做 Git + 部署 | `.\ahpal-master.ps1` → 選 `[6]` |
| 檢查文章狀態 | `.\check-articles.ps1` |
| 全面系統檢查 | `.\check-all.ps1` |
| 強制使用 DeepSeek | `.\ahpal-master.ps1` → 按 `[A]` |
| 恢復自動切換 | `.\ahpal-master.ps1` → 按 `[B]` |
| 執行備份 | `.\backup-system.ps1` |
| 查看狀態摘要 | `python src/main.py --dry-run` |
| 重置狀態檔 | `python src/main.py --reset` |

---

## 🔄 雙 API 自動切換機制

| 時段 | API | 說明 |
|------|-----|------|
| 尖峰（09:00-18:00） | Google Gemini | 速度穩定，不受高峰影響 |
| 離峰（18:00-09:00） | DeepSeek | 成本低，速度快 |

系統具備**容錯切換**功能：當 Gemini 發生錯誤時，自動切換到 DeepSeek。

### 強制切換

在 `ahpal-master.ps1` 選單中：
- 按 `[A]`：強制使用 DeepSeek（尖峰時段也適用）
- 按 `[B]`：恢復自動切換模式

---

## 💾 斷點續傳

系統透過 `article-manifest.json` 記錄每篇文章的生成狀態，支援**斷點續傳**：

- ✅ 跳過已生成的文章（節省 API 成本）
- ✅ 只生成新增或異常的文章
- ✅ 中斷後可從中斷點繼續
- ✅ 記錄每篇文章的品質分數

---

## 🌐 部署與上線

### 自動部署（推薦）

```powershell
.\ahpal-master.ps1
```

### 手動部署

```powershell
npx wrangler pages deploy "C:\Users\User\ahpal-static" --project-name=ahpal-pages
```

### 部署後驗證

| 頁面 | 網址 |
|------|------|
| 首頁 | https://www.ahpal.com/ |
| 遊戲間 | https://www.ahpal.com/game/ |
| 全部分類 | https://www.ahpal.com/categories.html |
| Sitemap | https://www.ahpal.com/sitemap.xml |

---

## 🔧 環境設定

### 必要軟體

| 軟體 | 用途 | 安裝指令 |
|------|------|----------|
| Python 3 | 執行生成腳本 | [下載安裝](https://www.python.org/downloads/) |
| Node.js | 執行 Wrangler CLI | [下載安裝](https://nodejs.org/) |
| Wrangler | 部署到 Cloudflare | `npm install -g wrangler` |
| Git | 版本控制 | [下載安裝](https://git-scm.com/download/win) |

### API Key 設定

編輯 `ahpal-static.ps1`：

```powershell
# Google Gemini API Key（尖峰時段使用）
$env:GEMINI_API_KEY = "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# DeepSeek API Key（離峰時段使用）
$env:DEEPSEEK_API_KEY = "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

---

## ❓ 常見問題

### Q1：如何確認 API Key 是否正確？
執行 `.\ahpal-static.ps1` 查看環境狀態摘要。

### Q2：文章生成到一半卡住了怎麼辦？
按 `Ctrl + C` 中斷，檢查 API Key。系統支援斷點續傳，重新執行會從中斷點繼續。

### Q3：如何只重新生成某幾篇文章？
刪除對應的 HTML 檔案，然後執行 `.\ahpal-master.ps1` 選 `[4]`。

### Q4：網站更新後沒有看到變化？
清除瀏覽器快取（`Ctrl + Shift + R`），或檢查 Cloudflare Pages 部署是否成功。

### Q5：如何查看目前網站的文章總數？
```powershell
.\check-articles.ps1
# 或
python src/main.py --dry-run
```

---

## 📞 聯絡資訊

- **網站**：https://www.ahpal.com
- **儲存庫**：https://github.com/praystone/ahpal-website
- **技術文件**：docs/AI交接與新進工程師接手手冊.html

---

## 📜 版本歷史

| 版本 | 日期 | 更新內容 |
|------|------|----------|
| v4.2 | 2026-07-20 | 模組化重構（9 個 Python 模組）、斷點續傳、雙 API 容錯切換 |
| v4.1 | 2026-07-19 | 新增遊戲生成模組、強制 API 切換功能 |
| v4.0 | 2026-07-17 | 首版發布、202 篇文章、23 款遊戲 |

---

© 2026 雅寶社區 · 頂客論壇 (AHPAL.COM)

最後更新：2026 年 7 月 20 日
```

---

## ✅ 安裝步驟

```powershell
# 1. 刪除舊的 README.md（如果存在）
Remove-Item "C:\Users\User\README.md" -Force -ErrorAction SilentlyContinue

# 2. 建立新的 README.md（複製上面完整內容後執行）
# 請先複製上面的完整內容，然後執行：
notepad "C:\Users\User\README.md"
# 貼上內容後儲存

# 3. 驗證
Get-Content "C:\Users\User\README.md" | Measure-Object -Line
# 應該顯示 200+ 行
```

---

**請複製上方完整內容，貼到 README.md 中儲存！** 📄🦞