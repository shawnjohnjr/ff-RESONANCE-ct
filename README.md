# FINAL FANTASY RESONANCE — Cheat Engine Table

適用 Steam **build 24250053**。已於 macOS 標準版 CrossOver、Windows Cheat Engine 7.7 x64 測試。

## 功能

- 唯讀檢查目前 Gil 與背包記錄筆數。
- 設定 Gil：整數 0–9,999,999，一次性寫入，不會凍結金額；取消勾選不會還原。
- 唯讀背包清單：顯示內部道具 ID 與數量，尚未提供名稱對照。

## 使用

1. 備份自己的遊戲存檔，進入可操作的地圖。
2. 在遊戲所在的同一 CrossOver bottle 開啟 Windows CE，載入 [CT](FFRS_Steam_24250053_Starter.CT)。
3. 勾選「01 唯讀檢查」，對照遊戲選單。第一次掃描需等待，請勿重複點擊。
4. 勾選「02 設定持有 Gil」並輸入目標金額。
5. 重開遊戲選單核對；確認後另存新欄位。

CT 會自動連接 FFRS-Win64-Shipping.exe，檢查執行檔版本，從目前世界找出使用中的存檔資料。所有功能預設關閉，沒有啟動自動執行腳本。版本不符時停止，不保證適用其他更新版本。

## 驗證狀態

2026-10-26：三個 Lua 項目通過 CE 語法檢查；實機唯讀檢查通過；使用 CT 原金錢腳本將 600 Gil 改成 1,000,000 Gil，重新讀取確認為 1,000,000。

**遊戲選單顯示、存檔及重新載入後的持續性仍待驗證。** 尚未提供 HP、MP、經驗值或道具寫入功能。

## 原始碼

`src/common.lua` 包含版本檢查與目前存檔物件定位；`build.py` 產生三個 CT 項目。使用 Python 3 執行：

```sh
python3 build.py
```

專案不包含遊戲檔案、個人存檔、記憶體傾印或測試紀錄，也不會修改 CrossOver 設定。

資料結構來源與授權見 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。本專案為非官方工具，與 Square Enix 無關。
