/* ============================================================
   雅寶遊戲間 - 共用 JavaScript v1.0
   ============================================================ */

// ---------- 通用工具函數 ----------
function $(id) { return document.getElementById(id); }

// ---------- 返回頂部 ----------
function scrollToTop() {
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

// ---------- 遊戲初始化輔助 ----------
function initGame(gameName, initFn) {
    console.log(`🎮 載入遊戲：${gameName}`);
    if (typeof initFn === 'function') {
        initFn();
    }
}

// ---------- 重新啟動輔助 ----------
function restartGame(initFn) {
    if (typeof initFn === 'function') {
        initFn();
    }
}
