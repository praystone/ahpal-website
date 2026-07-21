🦞 **收到！立即為您更新 README.md！**

---

## 📄 更新後的 README.md

```markdown
# 🦞 雅寶社區 · 頂客論壇 (AHPAL.COM)

> AI 驅動的自動化內容平台 — 24/7 全自動營運引擎

---

## 📌 專案簡介

AHPAL.COM 是一個結合 **AI 文章生成**、**HTML5 遊戲** 與 **自動化部署** 的靜態內容平台。系統透過 Google Gemini 與 DeepSeek 雙 API 自動切換，實現低成本、高品質的內容生產，並透過 Cloudflare Pages 全球 CDN 加速發布。

---

## 🚀 核心功能

| 功能 | 說明 |
|------|------|
| 🤖 **AI 文章生成** | 支援 Gemini（尖峰）與 DeepSeek（離峰）雙 API 自動切換 |
| 🎮 **HTML5 遊戲** | 43 款互動遊戲，免下載即開即玩 |
| ⚙️ **自動化部署** | 一鍵完成內容生成 → 靜態檔案輸出 → Cloudflare Pages 部署 |
| ⏰ **自動排程** | Windows 排程器每 2 小時自動執行部署（18:00 - 09:00） |
| 📧 **自動通知** | Gmail HTML 精美報告，即時回報部署狀態 |
| 🔄 **斷點續傳** | 透過 manifest 記錄狀態，中斷後可從中斷點繼續 |
| 📊 **增量構建** | MD5 比對，節省 80-90% 構建時間 |

---

## 📊 系統數據（截至 2026.07.22）

| 指標 | 數值 |
|------|------|
| 總頁面數 | 288+ 個 |
| 文章總數 | 288 篇 |
| 遊戲數量 | 43 款 |
| 分類數量 | 6 個 |
| 部署頻率 | 每 2 小時一次（夜間） |

---

## 🛠️ 技術棧

| 元件 | 技術 |
|------|------|
| 總指揮 | PowerShell |
| 內容生成引擎 | Python 3（模組化架構） |
| AI 模型 | Google Gemini Flash / DeepSeek Chat |
| 靜態託管 | Cloudflare Pages |
| 版本控制 | Git + GitHub |
| 自動排程 | Windows 工作排程器 |
| 通知系統 | Gmail SMTP |

---

## 📁 目錄結構

```
C:\Users\User\ahpal-static\
├── src/                    # Python 原始碼（10 個模組）
├── scripts/                # PowerShell 腳本
├── game/                   # 43 款遊戲
├── tech/                   # 3C 科技教學
├── life/                   # 生活小常識
├── review/                 # 軟體評測
├── philosophy/             # 人生哲理
├── trend/                  # AI 趨勢
├── data/                   # 待新增文章佇列
├── docs/                   # 系統文件
├── index.html              # 首頁
├── categories.html         # 全部分類
├── sitemap.xml             # 網站地圖
├── article-manifest.json   # 文章狀態追蹤
├── .env                    # API Key（不上傳）
├── .env.template           # 環境變數範本
├── .gitignore              # Git 忽略規則
└── README.md               # 本文件
```

---

## ⚡ 快速開始

### 1. 環境設定

```powershell
# 複製專案
cd C:\Users\User
git clone https://github.com/praystone/ahpal-website.git ahpal-static

# 建立 .env 檔案
cd ahpal-static
Copy-Item .env.template .env
notepad .env   # 填入實際 API Key
```

### 2. 安裝必要軟體

| 軟體 | 用途 |
|------|------|
| Python 3 | 執行生成腳本 |
| Node.js | 執行 Wrangler CLI |
| Wrangler | 部署到 Cloudflare |
| Git | 版本控制 |

### 3. 執行部署

```powershell
cd C:\Users\User\ahpal-static
.\scripts\ahpal-master.ps1
```

---

## 📋 常用指令

| 用途 | 指令 |
|------|------|
| 一鍵完整部署 | `.\scripts\ahpal-master.ps1` |
| 只生成文章 | `.\scripts\ahpal-master.ps1` → `[4]` |
| 只部署 | `.\scripts\ahpal-master.ps1` → `[6]` |
| 強制 DeepSeek | `.\scripts\ahpal-master.ps1` → `[A]` |
| 新增文章 | 編輯 `data/pending-articles.json` → `.\scripts\add-articles.ps1` |
| 檢查文章 | `.\scripts\check-articles.ps1` |
| 系統檢查 | `.\scripts\check-all.ps1` |
| 執行備份 | `.\scripts\backup-system.ps1` |
| 手動部署 | `npx wrangler pages deploy . --project-name=ahpal-pages` |

---

## ⏰ 自動排程

| 設定 | 值 |
|------|-----|
| 排程名稱 | `AHPAL_AutoDeploy` |
| 執行頻率 | 每 2 小時一次 |
| 執行時段 | 18:00 - 09:00（夜間離峰） |
| 執行內容 | Git Pull → Cloudflare 部署 → Gmail 通知 |

---

## 🔐 環境變數 (.env)

```env
# Google Gemini API Key（尖峰時段使用）
GEMINI_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# DeepSeek API Key（離峰時段使用）
DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

⚠️ **.env 不會上傳到 GitHub，請妥善保管！**

---

## 📧 通知系統

每次部署完成後，系統會自動發送 HTML 格式的報告至：

- 📧 `praystone@gmail.com`

報告內容包含：
- Git Pull 狀態
- Cloudflare 部署狀態
- 部署網址
- 執行時間

---

## 🔄 雙 API 自動切換機制

| 時段 | API | 說明 |
|------|-----|------|
| 尖峰（09:00-18:00） | Google Gemini | 高穩定性 |
| 離峰（18:00-09:00） | DeepSeek | 低成本 |

系統具備容錯切換機制，當主要 API 失敗時會自動切換至備援 API。

---

## 📊 系統狀態追蹤

| 檔案 | 用途 |
|------|------|
| `article-manifest.json` | 文章狀態追蹤（斷點續傳） |
| `build-state.json` | 增量構建狀態 |
| `logs/` | 系統日誌 |

---

## 🔧 排程管理

```powershell
# 查看排程狀態
Get-ScheduledTask -TaskName "AHPAL_AutoDeploy"

# 查看執行歷史
Get-ScheduledTask -TaskName "AHPAL_AutoDeploy" | Get-ScheduledTaskInfo

# 手動觸發排程
Start-ScheduledTask -TaskName "AHPAL_AutoDeploy"

# 開啟圖形排程器
taskschd.msc
```

---

## 🛡️ 電源管理（伺服器模式）

為確保 24/7 不中斷運作，請確認以下設定：

```powershell
# AC 電源模式最佳化
powercfg -change -monitor-timeout-ac 0
powercfg -change -standby-timeout-ac 0
powercfg -change -disk-timeout-ac 0
```

| 設定 | 建議值 |
|------|--------|
| 螢幕關閉（AC） | 從不 |
| 系統睡眠（AC） | 從不 |
| 硬碟關閉（AC） | 0（永不） |
| 闔上螢幕（AC） | 不採取動作 |

---

## 📦 備份與還原

### 執行備份
```powershell
cd C:\Users\User\ahpal-static
.\scripts\backup-system.ps1
```

### 災難復原
```powershell
# 從 GitHub 複製
git clone https://github.com/praystone/ahpal-website.git ahpal-static

# 還原 .env
# 從備份複製 .env 到 ahpal-static/

# 重新生成內容
cd ahpal-static
.\scripts\generate-games.ps1
python src/main.py

# 部署
git add .
git commit -m "災難復原"
git push
```

---

## 🐛 常見問題

| 問題 | 解決方法 |
|------|----------|
| API Key 無效 | 更新 `.env` 中的 API Key |
| Gemini 配額用完 | 按 `[A]` 強制切換 DeepSeek |
| Git 推送失敗 | `git pull --rebase` |
| 排程器執行失敗 | 執行 `.\scripts\fix-scheduled-task.ps1` |
| 文章品質 0 分 | 執行 `.\scripts\check-articles.ps1 -Fix` |

---

## 🤝 貢獻者

| 角色 | 姓名 |
|------|------|
| 🦞 龍蝦總工程師 | 技術負責人 |
| 👔 總經理 | 營運團隊 |
| 👑 董事長 | 最高決策者 |

---

## 📄 授權

© 2026 雅寶社區 · 頂客論壇 (AHPAL.COM)

---

## 🔗 相關連結

| 連結 | 網址 |
|------|------|
| 生產環境 | https://www.ahpal.com |
| Cloudflare Pages | https://ahpal-pages.pages.dev |
| GitHub 儲存庫 | https://github.com/praystone/ahpal-website |

---

**文件版本：v5.0**
**最後更新：2026 年 7 月 22 日**
```

---

## 🚀 執行方式

```powershell
cd C:\Users\User\ahpal-static

# 用記事本開啟 README.md
notepad README.md

# 貼上上面的完整內容 → Ctrl+S 儲存

# 確認更新
cat README.md | Select-Object -First 10
```

---

## ✅ 更新內容對照

| 項目 | 更新前 | 更新後 |
|------|--------|--------|
| 文章數量 | 202 篇 | **288 篇** |
| 遊戲數量 | 23 款 | **43 款** |
| 排程頻率 | 每小時 | **每 2 小時（18:00-09:00）** |
| 系統架構 | 無 | ✅ **完整技術棧說明** |
| 排程管理 | 無 | ✅ **完整指令參考** |
| 電源管理 | 無 | ✅ **伺服器模式設定** |
| 常見問題 | 無 | ✅ **排錯指南** |

---

**README.md 已更新完成！** 🦞🚀
