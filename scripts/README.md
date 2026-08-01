============================================================
  📁 AHPAL Scripts 目錄使用說明
  版本：v1.0
  更新日期：2026-08-01
============================================================

📂 目錄位置：C:\Users\User\ahpal-static\scripts

📊 腳本總數：28 個

============================================================
⭐ 核心腳本（日常必用）
============================================================

1. ahpal-master.ps1 (14.3 KB)
   功能：萬能總指揮 v7.0
   用途：主選單，整合所有功能
   用法：.\scripts\ahpal-master.ps1

2. add-articles.ps1 (6.1 KB)
   功能：JSON 驅動新增文章
   用途：從 data/pending-articles.json 批次新增文章
   用法：.\scripts\add-articles.ps1

3. preflight-check.ps1 (13.2 KB)
   功能：紅皮書死命令檢查
   用途：推送前強制檢查，確保文章品質
   用法：.\scripts\preflight-check.ps1
   參數：-Fix (自動修復)

4. generate-games.ps1 (52.8 KB)
   功能：生成 23 款遊戲
   用途：重建遊戲頁面，包含 Giscus 討論區
   用法：.\scripts\generate-games.ps1

============================================================
🔧 檢查與維護腳本
============================================================

5. check-all.ps1 (17.0 KB)
   功能：全面系統檢查（含品質評分）
   用途：掃描所有文章，檢查異常、品質、品牌
   用法：.\scripts\check-all.ps1 -Report
   參數：-Fix (刪除品質未達標文章)

6. check-articles.ps1 (8.6 KB)
   功能：文章檢查與修復
   用途：檢查文章大小、品牌名稱、API 錯誤
   用法：.\scripts\check-articles.ps1 -Fix

7. validate-seo.ps1 (4.6 KB) v2.1
   功能：SEO 驗證閘門
   用途：檢查 robots.txt、ads.txt、sitemap.xml
   用法：.\scripts\validate-seo.ps1
   參數：-Master (完整檢查 + Git 狀態)

8. check-deepseek-balance.ps1 (5.6 KB)
   功能：DeepSeek 餘額監控
   用途：查詢 API 餘額，低於門檻發送告警
   用法：.\scripts\check-deepseek-balance.ps1 -SendAlert

9. check-quota.ps1 (1.3 KB)
   功能：YouTube API 配額監控
   用途：監控每日上傳配額
   用法：.\scripts\check-quota.ps1

============================================================
📦 備份與同步腳本
============================================================

10. sync-to-gdrive.ps1 (5.3 KB)
    功能：雲端同步黃金標準
    用途：同步文章、腳本、影音到 ahpalke_drive
    用法：.\scripts\sync-to-gdrive.ps1
    參數：-Task articles|videos|scripts|all

11. backup-golden.ps1 (3.8 KB)
    功能：整站優良備份
    用途：建立黃金基準版本備份
    用法：.\scripts\backup-golden.ps1

12. backup-system.ps1 (12.1 KB)
    功能：系統備份工具
    用途：備份腳本、原始碼、網站檔案
    用法：.\scripts\backup-system.ps1 -Compress

13. backup-to-archive.ps1 (1.1 KB)
    功能：備份到 AI 檔案館
    用途：快速備份到 ahpal-AI-archive
    用法：.\scripts\backup-to-archive.ps1

14. ai-handover-scan.ps1 (22.5 KB)
    功能：AI 交接完整掃描與備份
    用途：產生完整系統分析報告
    用法：.\scripts\ai-handover-scan.ps1

15. backup-videos-to-gdrive.ps1 (3.0 KB)
    功能：備份影片到 Google Drive
    用途：將影片備份到 sax0936 帳戶
    用法：.\scripts\backup-videos-to-gdrive.ps1

============================================================
🎬 影音產線腳本
============================================================

16. video-finalize.ps1 (4.4 KB)
    功能：影音後製管線
    用途：浮水印、合軌、轉檔
    用法：.\scripts\video-finalize.ps1 -InputVideo "path"

17. youtube-pipeline.ps1 (2.6 KB)
    功能：NotebookLM 影音管線
    用途：文章 → NotebookLM → 音訊
    用法：.\scripts\youtube-pipeline.ps1 -ArticlePath "path"

18. youtube-upload-realtime.ps1 (3.7 KB)
    功能：YouTube 即時上傳
    用途：將影片上傳至 YouTube
    用法：.\scripts\youtube-upload-realtime.ps1 -VideoFile "path" -Title "標題"

19. batch-upload-throttled.ps1 (2.8 KB)
    功能：流量管制批次上傳
    用途：每日上限 85 支 Shorts 影片上傳
    用法：.\scripts\batch-upload-throttled.ps1

============================================================
⚙️ 其他工具腳本
============================================================

20. ahpal-static.ps1 (3.2 KB)      - 環境設定載入
21. config.ps1 (1.2 KB)             - 備用設定檔
22. deploy.ps1 (1.7 KB)             - 自動部署工具
23. deploy-rclone.ps1 (3.8 KB)      - Rclone 一鍵部署
24. generate-and-deploy.ps1 (1.0 KB) - 文章生成 + 自動部署
25. manage-schedules.ps1 (6.2 KB)   - 排程任務管理
26. process-pending.ps1 (3.4 KB)    - 待生成文章處理
27. sync-ahpalke-scheduled.ps1 (1.9 KB) - 定時同步
28. clean-and-push.ps1 (1.2 KB)     - Git 歷史清理

============================================================
🚀 快速指令參考
============================================================

.\scripts\ahpal-master.ps1              # 萬能總指揮
.\scripts\add-articles.ps1              # 新增文章（JSON 驅動）
.\scripts\preflight-check.ps1           # 死命令檢查
.\scripts\sync-to-gdrive.ps1            # 同步到 Google Drive
.\scripts\validate-seo.ps1              # SEO 驗證
.\scripts\check-all.ps1 -Report         # 全面檢查 + 報告
.\scripts\backup-golden.ps1             # 整站優良備份
.\scripts\ai-handover-scan.ps1          # AI 交接掃描

============================================================
📌 版本資訊
============================================================
腳本目錄版本：v1.0
最後更新：2026-08-01
維護者：龍蝦總工程師 🦞

============================================================
