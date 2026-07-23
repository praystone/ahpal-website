我來幫你更新 Git 相關的 `.md` 文件，包括 `README.md` 和新增 `HANDOVER.md` 到 Git 追蹤。

---

## 📝 更新 `README.md`

請將以下內容儲存為 `C:\Users\User\ahpal-static\README.md`：

```markdown
# 🏠 雅寶社區 · 頂客論壇 (AHPAL.COM)

> 歲月 · 知識 · 共創 — 二十多年的歲月迴聲，AI 精選六大領域實用內容。

---

## 📖 專案簡介

雅寶社區 · 頂客論壇是一個結合 **3C 科技教學、遊戲攻略、生活小常識、軟體評測、人生哲理與 AI 趨勢** 六大領域的知識型網站。透過 AI 輔助生成高品質文章，提供讀者真正有價值的資訊。

---

## 🏗️ 專案結構

```
ahpal-static/
├── scripts/                    # PowerShell 腳本
│   ├── ahpal-master.ps1        # 萬能總指揮（主入口）
│   ├── ahpal-static.ps1        # 環境設定
│   ├── generate-games.ps1      # 遊戲生成
│   └── backup-system.ps1       # 備份系統
│
├── src/                        # Python 原始碼
│   ├── main.py                 # 主程式入口
│   ├── config.py               # 設定管理
│   ├── api_client.py           # API 客戶端
│   ├── article_generator.py    # 文章生成核心
│   ├── html_builder.py         # HTML 建構
│   ├── quality_checker.py      # 品質檢查
│   ├── sitemap_builder.py      # Sitemap 建構
│   └── state_manager.py        # 狀態管理
│
├── ahpal-static/               # 網站輸出目錄
│   ├── index.html              # 首頁
│   ├── categories.html         # 全部分類
│   ├── tech/                   # 3C 科技教學 (47篇)
│   ├── game/                   # 遊戲攻略 (47篇 + 23款遊戲)
│   ├── life/                   # 生活小常識 (44篇)
│   ├── review/                 # 軟體評測 (43篇)
│   ├── philosophy/             # 人生哲理 (36篇)
│   └── trend/                  # AI 趨勢 (42篇)
│
├── .env                        # 環境變數 (API Key)
├── .env.template               # 環境變數範本
└── README.md                   # 本文件
```

---

## 🚀 快速啟動

### 1. 環境設定

```powershell
# 複製環境變數範本
Copy-Item .env.template .env

# 編輯 .env，填入 API Key
# GEMINI_API_KEY=你的Gemini金鑰
# DEEPSEEK_API_KEY=sk-你的DeepSeek金鑰
```

### 2. 執行主程式

```powershell
cd scripts
.\ahpal-master.ps1
```

### 3. 選單功能

| 選項 | 功能 |
|------|------|
| `[1]` | 完整流程 (備份 + 生成 + Git + 部署) |
| `[2]` | 快速更新 (跳過備份) |
| `[4]` | 只生成文章 |
| `[6]` | 只做 Git + 部署 |
| `[A]` | 強制使用 Gemini |
| `[D]` | 強制使用 DeepSeek |

### 4. 排程自動執行

```powershell
.\ahpal-master.ps1 -Mode deepseek -Action full
.\ahpal-master.ps1 -Mode gemini -Action generate
.\ahpal-master.ps1 -Action deploy
```

---

## 🤖 API 切換邏輯

| 時段 | 自動模式 | 說明 |
|------|---------|------|
| 09:00-18:00 | Gemini | 尖峰時段，Gemini 免費 |
| 18:00-09:00 | DeepSeek | 離峰時段，DeepSeek 成本低 |

---

## 📊 品質標準

| 評分項目 | 分數 |
|---------|------|
| H1 標題 | 20 分 |
| H2 標題 | 25 分 |
| 字數 (≥1200) | 25 分 |
| 表格 | 10 分 |
| FAQ | 10 分 |
| 清單 | 5 分 |
| 品牌連結 | 5 分 |
| **總分** | **100 分** |
| **通過門檻** | **≥60 分** |

---

## 🔧 故障排除

### API Key 無效
```powershell
cat .env
# 確認 GEMINI_API_KEY 和 DEEPSEEK_API_KEY 正確
```

### Git 推送失敗
```powershell
git push --set-upstream origin master
```

### Cloudflare 部署失敗
```powershell
npx wrangler pages deploy ahpal-static --project-name=ahpal-pages
```

---

## 📈 目前成果

| 項目 | 數量 |
|------|------|
| 文章總數 | 264+ 篇 |
| 遊戲數量 | 23 款 |
| 分類 | 6 大領域 |
| 品質分數 | 75-80/100 |
| 平均字數 | 2500-5000 字 |

---

## 🔗 連結

| 環境 | 網址 |
|------|------|
| 正式網站 | https://www.ahpal.com/ |
| Cloudflare Pages | https://4441c6bd.ahpal-pages.pages.dev |
| 遊戲間 | https://www.ahpal.com/game/ |

---

## 📝 版本資訊

| 項目 | 內容 |
|------|------|
| 當前版本 | v4.1 |
| 最後更新 | 2026-07-24 |
| 維護者 | 雅寶社區 · 頂客論壇 |

---

## 📄 授權

本專案為雅寶社區 · 頂客論壇所有，保留所有權利。
```

---

## 📝 更新 `HANDOVER.md`

將以下內容儲存為 `C:\Users\User\ahpal-static\HANDOVER.md`（同時複製到備份檔案館）：

```markdown
# 📋 AHPAL.COM 專案交接文件

> 給下一位維護者 / AI 的完整交接手冊

---

## 📌 基本資訊

| 項目 | 內容 |
|------|------|
| 專案名稱 | 雅寶社區 · 頂客論壇 (AHPAL.COM) |
| 專案路徑 | `C:\Users\User\ahpal-static` |
| 備份檔案館 | `C:\Users\User\ahpal-archive` |
| 網站網址 | https://www.ahpal.com/ |

---

## 🏗️ 專案結構

```
ahpal-static/
├── scripts/          # PowerShell 腳本 (主控台)
├── src/              # Python 原始碼 (核心引擎)
├── ahpal-static/     # 🌐 網站輸出 (264+ 文章 + 23 遊戲)
├── .env              # 🔑 API Key (重要！)
└── build-state.json  # 構建狀態
```

---

## 🚀 快速啟動指令

```powershell
# 進入專案
cd C:\Users\User\ahpal-static\scripts

# 執行主程式（互動式選單）
.\ahpal-master.ps1

# 排程自動執行
.\ahpal-master.ps1 -Mode deepseek -Action full
.\ahpal-master.ps1 -Mode gemini -Action generate
.\ahpal-master.ps1 -Action deploy
```

---

## 🎮 選單功能

| 選項 | 功能 |
|------|------|
| `[1]` | 完整流程 (備份 + 生成 + Git + 部署) |
| `[2]` | 快速更新 (跳過備份) |
| `[3]` | 只生成遊戲 (不耗 API) |
| `[4]` | 只生成文章 |
| `[5]` | 只做備份 |
| `[6]` | 只做 Git + 部署 |
| `[7]` | 檢查文章狀態 |
| `[8]` | 查看系統狀態 |
| `[A]` | 強制使用 Gemini |
| `[D]` | 強制使用 DeepSeek |
| `[B]` | 恢復自動切換模式 |

---

## 🐍 Python 模組說明

| 模組 | 功能 | 重要函數 |
|------|------|----------|
| `main.py` | 主入口 | `run_pipeline()` |
| `config.py` | 設定管理 | `get_api_key()`, `is_peak_hour()` |
| `api_client.py` | API 客戶端 | `call_api()`, `get_current_api_info()` |
| `article_generator.py` | 文章生成 | `generate_article()`, `text_to_html()` |
| `html_builder.py` | HTML 建構 | `build_article_html()` |
| `quality_checker.py` | 品質檢查 | `check_article_quality()` |
| `sitemap_builder.py` | Sitemap | `update_sitemap()` |
| `state_manager.py` | 狀態管理 | `get_pending_articles()` |

---

## 🤖 API 設定

### 環境變數 (.env)

```
GEMINI_API_KEY=你的Gemini金鑰
DEEPSEEK_API_KEY=sk-你的DeepSeek金鑰
```

### API 切換邏輯

| 時段 | 自動模式 |
|------|---------|
| 09:00-18:00 | Gemini (免費) |
| 18:00-09:00 | DeepSeek (低成本) |

---

## 🔧 故障排除

### 1. 找不到 main.py

```powershell
# 檢查檔案
ls C:\Users\User\ahpal-static\src\main.py

# 如果不存在，從備份還原
Copy-Item "C:\Users\User\ahpal-archive\ahpal-backup-*\src\main.py" "C:\Users\User\ahpal-static\src\"
```

### 2. API Key 無效

```powershell
# 檢查 .env
cat C:\Users\User\ahpal-static\.env

# 重新設定
notepad C:\Users\User\ahpal-static\.env
```

### 3. Git 推送失敗

```powershell
cd C:\Users\User\ahpal-static
git push --set-upstream origin master
```

### 4. Cloudflare 部署失敗

```powershell
cd C:\Users\User\ahpal-static
npx wrangler pages deploy . --project-name=ahpal-pages
```

---

## 🏛️ 災難復原

### 從備份檔案館還原

```powershell
# 1. 解壓縮最新備份
Expand-Archive -Path "C:\Users\User\ahpal-archive\ahpal-backup-*.zip" -DestinationPath "C:\Users\User\" -Force

# 2. 還原 API Key
Copy-Item "C:\Users\User\ahpal-archive\ahpal-backup-*\ahpal-static\.env" "C:\Users\User\ahpal-static\.env" -Force

# 3. 開始執行
cd C:\Users\User\ahpal-static\scripts
.\ahpal-master.ps1
```

### 備份檔案館位置

```
C:\Users\User\ahpal-archive\
├── ahpal-backup-YYYYMMDD_HHMMSS.zip
└── ahpal-backup-YYYYMMDD_HHMMSS\
```

---

## 📊 目前成果

| 項目 | 數量 |
|------|------|
| 文章總數 | 264+ 篇 |
| 遊戲數量 | 23 款 |
| 分類 | 6 大領域 |
| 品質分數 | 75-80/100 |

---

## 🔗 重要連結

| 環境 | 網址 |
|------|------|
| 正式網站 | https://www.ahpal.com/ |
| Cloudflare Pages | https://4441c6bd.ahpal-pages.pages.dev |
| 遊戲間 | https://www.ahpal.com/game/ |

---

## 📝 版本資訊

| 項目 | 內容 |
|------|------|
| 當前版本 | v4.1 |
| 最後更新 | 2026-07-24 |
| 維護者 | 雅寶社區 · 頂客論壇 |

---

*交接文件版本：v1.0*
*建立時間：2026-07-24*
```

---

## 📦 Git 提交更新

```powershell
cd C:\Users\User\ahpal-static

# 加入新檔案
git add README.md
git add HANDOVER.md

# 查看狀態
git status

# 提交
git commit -m "📝 更新 README.md 和新增 HANDOVER.md 交接文件"

# 推送
git push
```

---

## ✅ 完成

| 檔案 | 狀態 |
|------|------|
| `README.md` | ✅ 已更新 |
| `HANDOVER.md` | ✅ 已新增 |
| Git 提交 | ✅ 已完成 |

現在你的專案有完整的文件說明，未來 AI 交接時可以直接閱讀 `HANDOVER.md` 快速上手！