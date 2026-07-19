# ============================================================
# state_manager.py - 文章狀態追蹤模組
# ============================================================
# 功能：管理文章生成狀態，支援斷點續傳與增量生成
# ============================================================

import json
import os
import hashlib
from datetime import datetime
from src.config import OUTPUT_DIR

class ArticleStateManager:
    """文章狀態管理器 - 使用 manifest.json 追蹤生成狀態"""
    
    def __init__(self, manifest_path=None):
        if manifest_path is None:
            manifest_path = os.path.join(OUTPUT_DIR, "article-manifest.json")
        self.manifest_path = manifest_path
        self.manifest = self._load()
    
    def _load(self):
        """載入狀態檔，若不存在則建立預設結構"""
        if os.path.exists(self.manifest_path):
            try:
                with open(self.manifest_path, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except (json.JSONDecodeError, IOError):
                print(f"⚠️ 狀態檔損毀，重新建立: {self.manifest_path}")
        
        return {
            "version": "1.0",
            "articles": {},
            "stats": {
                "total": 0,
                "generated": 0,
                "pending": 0,
                "failed": 0
            },
            "last_updated": None
        }
    
    def save(self):
        """儲存狀態檔"""
        self.manifest["last_updated"] = datetime.now().isoformat()
        try:
            with open(self.manifest_path, 'w', encoding='utf-8') as f:
                json.dump(self.manifest, f, indent=2, ensure_ascii=False)
        except IOError as e:
            print(f"❌ 儲存狀態檔失敗: {e}")
    
    def _get_file_hash(self, filepath):
        """計算檔案 MD5 哈希值"""
        if not os.path.exists(filepath):
            return None
        try:
            with open(filepath, 'rb') as f:
                return hashlib.md5(f.read()).hexdigest()
        except IOError:
            return None
    
    def is_article_ready(self, filename):
        """檢查文章是否已生成且完整（基於哈希值）"""
        filepath = os.path.join(OUTPUT_DIR, filename)
        if not os.path.exists(filepath):
            return False
        
        current_hash = self._get_file_hash(filepath)
        if current_hash is None:
            return False
        
        # 檢查狀態檔中的紀錄
        if filename not in self.manifest["articles"]:
            return False
        
        stored = self.manifest["articles"][filename]
        
        # 檢查檔案大小是否正常（≥ 5KB）
        file_size = os.path.getsize(filepath)
        if file_size < 5120:
            return False
        
        return stored.get("hash") == current_hash
    
    def mark_generated(self, filename, quality_score=0, metadata=None):
        """標記文章為已生成"""
        filepath = os.path.join(OUTPUT_DIR, filename)
        file_size = os.path.getsize(filepath) if os.path.exists(filepath) else 0
        
        self.manifest["articles"][filename] = {
            "hash": self._get_file_hash(filepath),
            "quality": quality_score,
            "generated_at": datetime.now().isoformat(),
            "size": file_size,
            "metadata": metadata or {}
        }
        
        # 更新統計
        self.manifest["stats"]["total"] = len(self.manifest["articles"])
        self.manifest["stats"]["generated"] = sum(
            1 for a in self.manifest["articles"].values() 
            if a.get("hash") is not None
        )
        
        self.save()
    
    def mark_failed(self, filename, error_message):
        """標記文章生成失敗"""
        if filename not in self.manifest["articles"]:
            self.manifest["articles"][filename] = {}
        
        self.manifest["articles"][filename]["failed"] = True
        self.manifest["articles"][filename]["error"] = error_message
        self.manifest["articles"][filename]["failed_at"] = datetime.now().isoformat()
        self.manifest["stats"]["failed"] += 1
        self.save()
    
    def get_pending_articles(self, keywords_list):
        """過濾出待生成的文章（基於狀態檔）"""
        pending = []
        for item in keywords_list:
            filename = item["filename"]
            if not self.is_article_ready(filename):
                pending.append(item)
        return pending
    
    def get_summary(self):
        """取得狀態摘要"""
        total = self.manifest["stats"]["total"]
        generated = self.manifest["stats"]["generated"]
        failed = self.manifest["stats"]["failed"]
        
        return {
            "total": total,
            "generated": generated,
            "pending": total - generated - failed,
            "failed": failed,
            "last_updated": self.manifest.get("last_updated")
        }

# 單例模式管理
_state_manager = None

def get_state_manager():
    global _state_manager
    if _state_manager is None:
        _state_manager = ArticleStateManager()
    return _state_manager