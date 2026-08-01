# ============================================================
# logger.py - 日誌管理模組
# ============================================================
# 功能：統一日誌輸出，支援檔案與控制台
# ============================================================

import logging
import os
from datetime import datetime

# 日誌目錄（部署時會被 .gitignore 排除）
LOG_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "logs")

def setup_logger(name="ahpal", log_level=logging.INFO):
    """設定日誌系統"""
    os.makedirs(LOG_DIR, exist_ok=True)
    
    # 日誌檔案：按日期分檔
    log_file = os.path.join(LOG_DIR, f"{name}-{datetime.now().strftime('%Y-%m-%d')}.log")
    
    # 設定根日誌器
    logger = logging.getLogger(name)
    logger.setLevel(log_level)
    
    # 避免重複添加 Handler
    if logger.handlers:
        return logger
    
    # 檔案 Handler（UTF-8 編碼）
    file_handler = logging.FileHandler(log_file, encoding='utf-8')
    file_handler.setLevel(log_level)
    
    # 控制台 Handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(log_level)
    
    # 格式化
    formatter = logging.Formatter(
        '%(asctime)s [%(levelname)s] %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    file_handler.setFormatter(formatter)
    console_handler.setFormatter(formatter)
    
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    
    return logger

# 預設日誌器
logger = setup_logger()

def get_logger(name=None):
    """取得日誌器實例"""
    if name:
        return setup_logger(name)
    return logger