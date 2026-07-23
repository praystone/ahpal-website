# ============================================================
# state_manager.py - 狀態管理模組 v4.3
# ============================================================

import os
import json
from pathlib import Path

class StateManager:
    """管理文章生成狀態"""
    
    def __init__(self, state_file="build-state.json"):
        """初始化狀態管理器"""
        # 狀態檔案路徑（專案根目錄）
        self.state_file = Path(__file__).parent.parent / state_file
        self.state = self._load_state()
    
    def _load_state(self):
        """載入狀態檔案"""
        if self.state_file.exists():
            try:
                with open(self.state_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except:
                return {"files": {}, "generated": [], "failed": []}
        return {"files": {}, "generated": [], "failed": []}
    
    def _save_state(self):
        """儲存狀態檔案"""
        with open(self.state_file, 'w', encoding='utf-8') as f:
            json.dump(self.state, f, indent=2, ensure_ascii=False)
    
    def is_generated(self, filename):
        """
        檢查檔案是否已生成
        參數：
            filename: 檔案名稱（如 tech/xxx.html）
        回傳：
            bool: 是否已生成
        """
        # 檢查是否在 generated 列表中
        if filename in self.state.get("generated", []):
            return True
        
        # 檢查是否在 files 字典中
        if filename in self.state.get("files", {}):
            return True
        
        # 檢查實際檔案是否存在
        output_dir = os.environ.get("AHPAL_OUTPUT_DIR", "C:\\Users\\User\\ahpal-static")
        file_path = Path(output_dir) / filename
        if file_path.exists():
            # 如果檔案存在但不在狀態中，加入狀態
            if filename not in self.state.get("generated", []):
                self.mark_generated(filename)
            return True
        
        return False
    
    def mark_generated(self, filename):
        """標記檔案為已生成"""
        if "generated" not in self.state:
            self.state["generated"] = []
        if filename not in self.state["generated"]:
            self.state["generated"].append(filename)
        self._save_state()
    
    def mark_failed(self, filename, error=None):
        """標記檔案生成失敗"""
        if "failed" not in self.state:
            self.state["failed"] = []
        if filename not in self.state["failed"]:
            self.state["failed"].append({
                "filename": filename,
                "error": str(error) if error else "未知錯誤"
            })
        self._save_state()
    
    def get_pending_articles(self, keywords_list):
        """
        獲取待生成的文章列表
        參數：
            keywords_list: 所有文章的清單
        回傳：
            list: 待生成的文章清單
        """
        pending = []
        for item in keywords_list:
            filename = item.get("filename")
            if filename and not self.is_generated(filename):
                pending.append(item)
        return pending
    
    def get_summary(self):
        """取得狀態摘要"""
        return {
            "total": len(self.state.get("generated", [])) + len(self.state.get("failed", [])),
            "generated": len(self.state.get("generated", [])),
            "failed": len(self.state.get("failed", []))
        }
    
    def reset(self):
        """重置狀態（清除所有記錄）"""
        self.state = {"files": {}, "generated": [], "failed": []}
        self._save_state()
    
    def get_generated_files(self):
        """取得所有已生成檔案清單"""
        return self.state.get("generated", [])

# 單例模式
_state_manager = None

def get_state_manager():
    """取得 StateManager 單例"""
    global _state_manager
    if _state_manager is None:
        _state_manager = StateManager()
    return _state_manager