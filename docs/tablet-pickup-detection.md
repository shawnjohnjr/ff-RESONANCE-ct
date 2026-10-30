# 石板碎片的唯讀偵測研究

[English](tablet-pickup-detection.en.md)

本研究使用 Steam **build 24250053**，在 macOS CrossOver 與 Windows Cheat Engine 7.7 x64 上進行。目的為讀取已拾取／未拾取紀錄，協助尋找遺漏的石板；不修改物品數量、拾取旗標、存檔或遊戲記憶體。

**已驗證一個石板的精確對應，尚未建立全世界 99 個石板的完整索引。**

## 實際如何找到

1. 先從 SDK 找出 `CPP_MuchaGameSaveData.Map.mapGimmick`，讀取各地圖的拾取紀錄。最初也檢查事件旗標與寶箱資料表，但未能從這兩者直接辨識石板。
2. 選用攻略明確標示的位置：王都競技場入口通道最西端。玩家看到金色光點後先不拾取。
3. 從當前已載入的物件找到 `BP_MapGimmick_FieldItem_Medal_C`，確認 `m_ItemId = 25004`、`m_ItemNum = 1`、`m_IsOpen = 0`，以及 `m_UniqueId = 2`。
4. 匯出拾取前的紀錄。由玩家正常拾取一個石板，停留在同一地圖，再匯出一次。
5. 比對結果：

| 欄位 | 拾取前 | 拾取後 |
|---|---:|---:|
| 地圖編號 | 2016 | 2016 |
| UniqueID | 2 | 2 |
| 紀錄中的 ID | -1 / `0xFFFFFFFF` | -1 / `0xFFFFFFFF` |
| `IsOpen` | 0 | 1 |
| `isDisableTrap` | 0 | 0 |
| `IsUnlock` | 0 | 1 |
| 背包石板數量變化 | — | +1 |

這次前後比對沒有事件旗標變動。石板物件使用共通的拾取／寶箱紀錄；**不應假定每個石板都有一個獨立的劇情旗標**。也不能把這個樣本延伸為「所有石板永遠不涉及事件旗標」。

## 資料結構與位移

以下皆為此 build 的相對位移，不能當成跨版本固定值。UObject 位址會隨程序改變，工具會重新定位並檢查版本。

| 結構／欄位 | 位移或大小 |
|---|---:|
| `CPP_MuchaSaveDataManager.m_pGameSaveData` | `+0x60` |
| `CPP_MuchaGameSaveData.Map` | `+0x1A8` |
| `FSaveData_Map.mapGimmick` | `+0x70`，即 save `+0x218` |
| `TMap<int32, FSaveData_MapGimmick>` 元素步長 | `0x110`；key `+0`、value `+8` |
| `FSaveData_MapGimmick.treasureBox` | `+0x00`，內含 `TArray<FSaveData_TreasureBox>` |
| `FSaveData_TreasureBox` | 大小 `0x0C` |
| `ID` / `UniqueID` | `+0x00` / `+0x04` |
| `IsOpen` / `isDisableTrap` / `IsUnlock` | `+0x08` / `+0x09` / `+0x0A` |
| `CPP_MapGimmick.m_UniqueId` | actor `+0x328` |
| `CPP_MapGimmick_ItemObjectBase.m_ItemId` / `m_ItemNum` | actor `+0x3F8` / `+0x3FC` |
| `CPP_MapGimmick_FieldItem.m_IsOpen` | actor `+0x410` |
| `CPP_MuchaGameSaveData.inventory` | save `+0xA8`，元素為兩個 int32：ID、數量 |

遍歷 Unreal `TMap` 時必須檢查 sparse allocation bits，不能把已釋放的空槽視為紀錄。此配置的 sparse array data/num/capacity 位於 `+0/+8/+0xC`；allocation bit array 的 inline buffer `+0x10`、可選 heap pointer `+0x20`、bit count `+0x28`。工具檢查陣列界限、布林值及重複的 `(mapId, UniqueID)`。

## 重現方式

獨立工具：[tools/tablet_probe.lua](../tools/tablet_probe.lua)。連線 helper 取自本專案 `src/game_connection.lua`；此檔不需要載入修改功能的 CT。

在遊戲所在的同一 Windows／CrossOver 環境開啟 Cheat Engine Lua Engine。載入存檔，找到尚未拾取的石板，在同一地圖完成前後兩次快照，期間不要撿其他東西、讀檔、切圖或交付石板。將下列路徑換成自己的**絕對路徑**；CrossOver 可使用映射磁碟路徑。

```lua
probe = dofile([[C:\research\ff-RESONANCE-ct\tools\tablet_probe.lua]])
probe.snapshot([[C:\research\before.tsv]])
-- 等待「Read-only pickup snapshot complete」後，回遊戲正常拾取一個石板。
probe.snapshot([[C:\research\after.tsv]])
```

第一次定位 Unreal 物件可能較慢，請等待，不要重複執行。載入模組本身不會啟動掃描；`snapshot` 才連接程序並讀取資料。工具只寫入指定的本機 TSV，不安裝 timer、不注入遊戲函式、不寫入遊戲記憶體。不要將兩次快照存到同一個檔名；會覆寫原檔。

然後在有 Python 3 的環境比較：

```sh
python3 tools/compare_tablet_snapshots.py C:\research\before.tsv C:\research\after.tsv
```

在 macOS 終端機中，請改用該兩個 TSV 對應的 macOS 路徑。輸出會列出背包數量差與變動的 `(mapId, UniqueID)`；新增、消失與狀態改變會分別保留為 before/after 值。缺少完成標記、重複 key 或版本不同的快照會被拒絕。

**背包持有數不是累計收集數。** 將石板交給公主後，背包數量可能下降，不能用它單獨判斷成就進度。

## 如何判斷漏拿：精確對應與推定必須分開

- **精確對應：** 透過已載入 actor 的 `m_ItemId = 25004` 確認是石板，再建立 `(mapId, UniqueID)` 索引，讀取 `IsOpen`。目前公開驗證索引只有 [data/verified-tablets.json](../data/verified-tablets.json) 中的競技場樣本。
- **區域推定：** 某地圖所有已記錄的散落物品都未拾取，且數量與獨立攻略的石板數吻合，可以把它列為優先搜尋區域；這不是逐一驗證過的石板索引。
- **不能採用的判斷：** `ID == -1` 就當作石板。世界地圖的一般拾取物也可能具有這個值。
- **未出現在存檔中不等於已收集，也不等於未收集。** 地圖可能尚未造訪、物件尚未註冊，或受劇情與不同地圖變體影響。記憶體未載入某個 actor 也不能證明它已被撿走。
- save 的 `Map.mapId` 在這次測試曾保留先前的主區域編號。驗證競技場應以實際變動紀錄的 map key **2016** 與 actor 所屬地圖交叉核對，不要只使用這個位置欄位。

完整追蹤器仍需逐一建立石板 actor 與 map/UniqueID 的對照，處理相同地點的劇情版本，並在另一份存檔與乾淨啟動後重測。**這份研究沒有提供修改成就或自動收集功能。**

## 驗證範圍

原始探針已完成上述實機拾取前後驗證。整理後的獨立匯出工具另經 Lua 5.4 模擬記憶體測試，涵蓋 inline／heap allocation bits、空槽、異常布林值與存檔物件切換；Python 比對工具通過 5 項測試。這不等同於已在另一份存檔或乾淨啟動後重新完成實機驗證。

```sh
python3 tests/tablet_snapshot_test.py
lua tests/tablet_probe_test.lua
```

## 可公開的內容

本目錄只包含研究方法、唯讀工具與一個經人工確認的位置範例。沒有玩家存檔、完整背包、私人拾取清單、本機使用者路徑或實機 UObject 位址。執行工具產生的快照留在本機，不要直接上傳個人完整輸出。

## 參考與來源

- [PolarWizard/final-fantasy-resonance-fix](https://github.com/PolarWizard/final-fantasy-resonance-fix)：MIT 授權 SDK 結構參考，見本專案 [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md)。
- [PowerPyx 石板位置攻略](https://www.powerpyx.com/final-fantasy-resonance-all-tablet-shard-locations/)：提供競技場測試點（第 58 處），**沒有提供記憶體位移**。
- 研究方式：同一玩家在同一地圖，正常拾取前後的唯讀記憶體比對；單一樣本的成功不代表已完成全石板驗證。
