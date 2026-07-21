# ============================================================
# state_manager.py - 狀態管理模組（強化版）
# ============================================================
# 功能：追蹤檔案變更，支援增量構建
# ============================================================

import os
import json
import hashlib
from pathlib import Path
from datetime import datetime

# 狀態檔案路徑
STATE_FILE = Path(__file__).parent.parent / "build-state.json"

# ============================================================
# 單例模式
# ============================================================

_state_manager_instance = None

def get_state_manager():
    """取得 StateManager 單例"""
    global _state_manager_instance
    if _state_manager_instance is None:
        _state_manager_instance = StateManager()
    return _state_manager_instance

# ============================================================
# StateManager 類別
# ============================================================

class StateManager:
    def __init__(self):
        self.state = self.load()
    
    def load(self):
        """載入狀態檔案"""
        if STATE_FILE.exists():
            try:
                with open(STATE_FILE, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except:
                pass
        return {
            "version": "1.0",
            "last_build": None,
            "files": {},
            "stats": {"total": 0, "changed": 0, "unchanged": 0}
        }
    
    def save(self):
        """儲存狀態檔案"""
        self.state["last_build"] = datetime.now().isoformat()
        self.state["stats"]["total"] = len(self.state["files"])
        with open(STATE_FILE, 'w', encoding='utf-8') as f:
            json.dump(self.state, f, indent=2, ensure_ascii=False)
        print(f"   💾 狀態已儲存（{self.state['stats']['total']} 個檔案）")
    
    def get_file_hash(self, filepath):
        """計算檔案的 MD5 雜湊值"""
        if not os.path.exists(filepath):
            return None
        try:
            with open(filepath, 'rb') as f:
                return hashlib.md5(f.read()).hexdigest()
        except:
            return None
    
    def is_changed(self, filepath, current_hash=None):
        """檢查檔案是否變更"""
        if current_hash is None:
            current_hash = self.get_file_hash(filepath)
        if current_hash is None:
            return True
        file_key = str(filepath).replace("\\", "/")
        previous_hash = self.state["files"].get(file_key)
        return previous_hash != current_hash
    
    def update_file(self, filepath, hash_value=None):
        """標記檔案已建構"""
        if hash_value is None:
            hash_value = self.get_file_hash(filepath)
        if hash_value is None:
            return
        file_key = str(filepath).replace("\\", "/")
        self.state["files"][file_key] = hash_value
    
    def update_file_batch(self, filepaths):
        """批量標記檔案已建構"""
        for filepath in filepaths:
            self.update_file(filepath)
        self.save()
    
    def get_changed_files(self, file_list):
        """從檔案清單中篩選出變更的檔案"""
        changed = []
        for filepath in file_list:
            if self.is_changed(filepath):
                changed.append(filepath)
        return changed
    
    def mark_built(self, filepath):
        """標記已建構（alias）"""
        self.update_file(filepath)
        self.save()
    
    def mark_built_batch(self, filepaths):
        """批量標記已建構（alias）"""
        self.update_file_batch(filepaths)
    
    def reset(self):
        """重置狀態"""
        self.state = {
            "version": "1.0",
            "last_build": None,
            "files": {},
            "stats": {"total": 0, "changed": 0, "unchanged": 0}
        }
        self.save()
        print("   🔄 狀態已重置")
    
def get_summary(self):
    """取得狀態摘要"""
    total = len(self.state["files"])
    return {
        "total": total,
        "generated": total,
        "failed": 0,
        "last_build": self.state.get("last_build"),
        "version": self.state.get("version", "1.0")
    }

    def get_pending_articles(self, keywords_list):
        """取得待生成的文章清單（與原系統相容）"""
        pending = []
        
        for item in keywords_list:
            filename = item.get("filename")
            if filename:
                filepath = os.path.join(os.path.dirname(STATE_FILE), filename)
                # 檢查檔案是否不存在或已變更
                if not os.path.exists(filepath) or self.is_changed(filepath):
                    pending.append(item)
        
        return pending


# ============================================================
# 向後相容的函數
# ============================================================

def get_pending_articles(keywords_list):
    """向後相容：取得待生成文章清單"""
    return get_state_manager().get_pending_articles(keywords_list)

def mark_failed(filename, error_msg):
    """標記文章生成失敗"""
    print(f"   ❌ 失敗：{filename} - {error_msg}")