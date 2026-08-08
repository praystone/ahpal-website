import re

file_path = 'music/rainy-night-flower-lo-fi-cover.html'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 正確的 HTML 表格
correct_table = '''
<table style="width:100%; border-collapse:collapse; margin:20px 0; font-size:14px;">
    <thead>
        <tr style="background-color:#005A9C; color:white;">
            <th style="padding:10px; border:1px solid #CBD5D1; text-align:left;">段落</th>
            <th style="padding:10px; border:1px solid #CBD5D1; text-align:left;">時間軸（約）</th>
            <th style="padding:10px; border:1px solid #CBD5D1; text-align:left;">樂器配置與編曲重點</th>
            <th style="padding:10px; border:1px solid #CBD5D1; text-align:left;">聽覺心理效果</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td style="padding:10px; border:1px solid #CBD5D1;"><strong>Intro (前奏)</strong></td>
            <td style="padding:10px; border:1px solid #CBD5D1;">0:00 - 0:35</td>
            <td style="padding:10px; border:1px solid #CBD5D1;">以老舊鋼琴彈奏分解和弦，搭配強烈的黑膠底噪（Vinyl Crackle）與極小聲的雨聲取樣。和聲進行為 Am7 - Dm9 - G7 - Cmaj7。</td>
            <td style="padding:10px; border:1px solid #CBD5D1;">營造「回憶開啟」的氛圍，如同從佈滿灰塵的窗戶望向雨景。節奏組尚未進入，時間感靜滯。</td>
        </tr>
        <tr style="background-color:#F7F9FC;">
            <td style="padding:10px; border:1px solid #CBD5D1;"><strong>Verse 1（第一段主歌）</strong></td>
            <td style="padding:10px; border:1px solid #CBD5D1;">0:36 - 1:30</td>
            <td style="padding:10px; border:1px solid #CBD5D1;">鼓組（Boom Bap 節奏）加入，但鼓刷聲明顯，搭配低音提琴（Double Bass）的 Walking Bass 線條。人聲以低沉、氣音為主。台羅拼音歌詞以字幕呈現。</td>
            <td style="padding:10px; border:1px solid #CBD5D1;">進入「敘述」狀態，電貝斯的撥奏聲像貓咪踩在潮濕的屋簷上，帶有爵士酒吧的閒適感。</td>
        </tr>
        <tr>
            <td style="padding:10px; border:1px solid #CBD5D1;"><strong>Chorus (副歌/雨夜花主題)</strong></td>
            <td style="padding:10px; border:1px solid #CBD5D1;">1:31 - 2:20</td>
            <td style="padding:10px; border:1px solid #CBD5D1;">加入了弦樂器的取樣，但聲音極度壓縮，像是從老收音機中傳出。歌聲情緒略為激昂，但仍維持在 Lo-fi 的動態範圍內。背景出現微弱的和聲（Vocal Chop）。</td>
            <td style="padding:10px; border:1px solid #CBD5D1;">讓主題「雨夜花」的綻放與凋零，與更為龐大的衝突感連結。但瞬間即逝的弦樂，宛如悲傷被科技媒介隔離後的投射。</td>
        </tr>
        <tr style="background-color:#F7F9FC;">
            <td style="padding:10px; border:1px solid #CBD5D1;"><strong>Outro（尾奏）</strong></td>
            <td style="padding:10px; border:1px solid #CBD5D1;">2:21 - 4:00</td>
            <td style="padding:10px; border:1px solid #CBD5D1;">節奏組漸弱，留下孤獨的鋼琴單音與 MQA（Master Quality Authenticated）的高頻壓縮感但卻故意用低音質輸出。最後以錄音機 STOP 鍵的機械聲結束。</td>
            <td style="padding:10px; border:1px solid #CBD5D1;">回歸空洞與寂寥。雨聲在結尾時變大，隨意中斷的音樂象徵著記憶的不可持續性，餘韻無窮。</td>
        </tr>
    </tbody>
</table>
'''

# 方法一：嘗試匹配包含 "三、 Lo-fi 編曲結構拆解" 的區塊
# 從該標題開始，到 "3.1 和聲色彩的現代化" 結束
pattern = r'(<h2>三、 Lo-fi 編曲結構拆解.*?)(<table.*?</table>)(.*?)(<h2>3\.1 和聲色彩的現代化)'
match = re.search(pattern, content, re.DOTALL)

if match:
    new_content = match.group(1) + correct_table + match.group(3) + match.group(4)
    content = content[:match.start()] + new_content + content[match.end():]
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('✅ 表格結構已修復（方法一）！')
else:
    # 方法二：直接查找並替換包含錯誤表格的區塊
    print('⚠️ 方法一未命中，嘗試方法二（直接查找錯誤表格）...')
    
    # 查找以 "<p><table" 開頭，以 "</table></p>" 結尾的區塊
    # 這個模式匹配當前頁面上的錯誤表格
    pattern2 = r'<p><table border="1".*?</table></p>'
    match2 = re.search(pattern2, content, re.DOTALL)
    
    if match2:
        content = content[:match2.start()] + correct_table + content[match2.end():]
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print('✅ 表格結構已修復（方法二）！')
    else:
        print('❌ 兩種方法皆未命中，請手動檢查檔案內容。')
