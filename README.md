# FINAL FANTASY RESONANCE — Cheat Engine Table

**繁體中文** | [English](README.en.md)

適用 Steam **build 24250053**。已於 macOS 標準版 CrossOver、Windows Cheat Engine 7.7 x64 測試。

## 功能

| 項目 | 功能 |
|---|---|
| 01 | 唯讀檢查目前 Gil 與背包記錄筆數 |
| 02 | 設定 Gil：0–9,999,999 |
| 03 | 唯讀背包清單：內部道具 ID 與數量 |
| 04 | 選擇已持有道具並修改數量：1–99 |
| 05 | 將目前隊伍角色升至 Lv.99，透過遊戲函式重新計算角色能力 |
| 06 | 全角色終盤裝備包：補足 8 種武器、3 種防具與 4 種飾品 |

所有項目彼此獨立，預設關閉。修改是一次性的，不會凍結數值；取消勾選不會還原。再次執行時先取消勾選，再重新勾選。

## 使用

1. 備份自己的遊戲存檔，進入地圖並停在選單；執行期間不要戰鬥、使用道具、購物或切換地圖。
2. 在遊戲所在的同一 CrossOver bottle 開啟 Windows CE，載入 [CT](FFRS_Steam_24250053_Starter.CT)。
3. 勾選「01 唯讀檢查」，對照遊戲選單。首次掃描物件需要等待，請勿重複點擊。
4. 選擇需要的功能。道具功能先選取清單項目，再輸入數量；取消則不修改。
5. 關閉再打開遊戲選單核對，確認後另存新欄位。

CT 自動連接 `FFRS-Win64-Shipping.exe`，檢查執行檔版本，從目前世界找出使用中的存檔資料。版本不符時停止，不保證適用其他更新版本。

### 道具選單

即時讀取遊戲資料表，以**英文 / 繁體中文名稱、ID、持有數量**列出目前背包內的消耗品與裝備。名稱使用本機 build 24250053 的官方 `en`／`zh-Hant` 語系，以道具 ID 精確對應，共收錄 507 組名稱（其中 2 個官方繁中欄位仍是日文，已補上標明「暫譯」的中文）；實機載入的 505 筆消耗品與裝備資料全部有雙語對應。未知 ID 顯示「Unknown item / 未翻譯道具」並保留 ID。

例如：`Potion / 治療劑`、`Phoenix Down / 鳳凰尾巴`、`Crimson Saber / 深紅烈焰`。重要道具、Artifact 與未持有道具不列入修改清單。

數量範圍 1–99 是本工具的保守限制，並非宣稱遊戲所有道具的最大堆疊量。此功能不新增道具，也不刪除背包記錄。選擇後若背包位置、筆數或原數量改變，會停止寫入。

### 全角色終盤裝備包

第 06 項透過遊戲的 `AddInventory` 函式補足背包數量：8 種武器各至少 1 件，以下防具與飾品各至少 8 件。已持有更多時不減少、不重複加送。只加入背包，不自動裝備、不解鎖角色，也不變更角色等級。

| 主角群 | 武器 | ID |
|---|---|---:|
| 雷因 | Ragnarok+ / 諸神黃昏·改 | 10197 |
| 拉斯韋爾 | Sasuke’s Blade+ / 佐助刀·改 | 10297 |
| 菲娜 | Artemis Bow+ / 狩神弓·改 | 10397 |
| 莉德 | Thor’s Hammer+ / 雷神之鎚·改 | 10496 |
| 尼科爾 | Last Resort+ / 最後底牌·改 | 10597 |
| 魔人菲娜 | Fire Birch+ / 烈焰鞭·改 | 10696 |
| 傑科 | Arcturus+ / 大角星·改 | 10797 |
| 櫻 | Wizard’s Rod+ / 巫師法杖·改 | 10897 |

8 種武器皆包含遊戲內的傷害上限 99,999 效果。依 8 位角色的武器類型確認相容；效果仍受遊戲的戰鬥條件影響。

- 防具：Tatenashi Armor+ / 楯無之鎧·改（11397）、Mirage Vest+ / 幻影背心·改（11097）、Lordly Robes+ / 領主長袍·改（11597）。
- 飾品：Super Ribbon / 超級緞帶（12101）、Ultima Reactor / 最終究極反應爐（12095）、Genji Gloves / 源氏護手（12096）、Omega Badge / 歐米茄勛章（12103）。

這是按裝備能力、附加效果與可裝備類型挑選的通用終盤組合，各戰鬥仍可有更合適的專用搭配。提供三類防具供角色依相容類型選用。

執行前會核對全部裝備 ID 與分類，逐筆新增後讀回；背包若在期間改變會停止。中途失敗時可能已有部分裝備加入，不會自動回滾，應先檢查背包。

### Lv.99

只處理目前隊伍中的主角群，不解鎖未加入角色、不修改幻兵。由各角色升級表累計至 Lv.99 所需 EXP，先以遊戲的等級計算函式核對，再呼叫 `SetPlayableUnitExperience` 更新存檔 EXP 與即時角色能力。

不需要打完一場戰鬥才生效。**目前 HP／MP 不會自動補滿**；最大 HP／MP 與能力會重新計算。已達目標經驗值的角色不重複寫入。若執行中途失敗，應檢查角色狀態；這不是跨角色的原子交易，也不會自動復原已完成角色。

## CrossOver 啟動時提示缺少 VC++ x64

### 本次遇到的原因

在標準版 CrossOver 26.3、Steam build 24250053 的測試環境，啟動器顯示：

```text
The following component(s) are required to run this program:
Microsoft Visual C++ 2015-2022 Redistributable (x64)
```

當時 bottle 已安裝 Microsoft VC++ runtime；問題是啟動器檢查到的 DLL 版本仍不符合要求。以下為本次檢查結果，不代表所有 CrossOver 版本都相同：

| 檢查項目 | 版本 |
|---|---|
| 此遊戲啟動器要求的最低版本 | 14.42.34438 |
| CrossOver 內建的 `msvcp140_2.dll`、`vcruntime140_1.dll` | 14.42.34433.0 |
| bottle 中已安裝的 Microsoft 原生 runtime DLL | 14.51.36247.0 |

因此，只確認「已安裝 VC++」還不夠，也需要確認啟動時選用了哪一套 DLL。這次讓遊戲優先使用已安裝的 Microsoft 原生 DLL 後，順利進入著色器編譯與遊戲地圖。

### 成功使用的啟動方式

1. 正常退出其他 CrossOver 版本中的 Steam／遊戲，再用**標準版 CrossOver** 開啟遊戲所在 bottle 的 Steam 並登入。
2. 確認同一 bottle 已具備相容的 **x64** Microsoft Visual C++ v14 Redistributable。若尚未安裝，從 [Microsoft 官方下載頁](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170) 取得 x64 安裝程式，透過 CrossOver 在該 bottle 執行。套件架構應配合 Windows 遊戲的 x64 架構。
3. 遊戲尚未執行時，在 macOS「終端機」使用下列命令。先按自己的安裝位置調整前三個變數；若 CrossOver 裝在系統 Applications，第一行改成 `CROSSOVER_APP="/Applications/CrossOver.app"`。

```sh
CROSSOVER_APP="$HOME/Applications/CrossOver.app"
BOTTLE_NAME="Steam"
GAME_EXE='C:\Program Files (x86)\Steam\steamapps\common\FINAL FANTASY RESONANCE\FFRS.exe'

SteamAppId=3259780 SteamGameId=3259780 \
  "$CROSSOVER_APP/Contents/SharedSupport/CrossOver/bin/wine" \
  --bottle "$BOTTLE_NAME" --no-update \
  --dll 'msvcp140,msvcp140_1,msvcp140_2,vcruntime140,vcruntime140_1=n,b' \
  --debugmsg '-all' \
  --cx-app "$GAME_EXE"
```

`n,b` 表示先嘗試 Microsoft 原生 DLL，再嘗試 CrossOver/Wine 內建實作；它不會自行安裝缺少的 runtime。`--no-update` 避免這次啟動觸發 bottle 更新。命令明確使用標準版 CrossOver 的執行檔。

此 DLL 選擇設定只作用於這次啟動及其繼承設定的子程序，沒有寫入永久的 bottle DLL 覆寫設定。下次直接按 Steam 的「開始遊戲」不一定會沿用，需要再次使用此命令。本次未重新安裝遊戲，也未修改 CrossOver MGVF 的設定。

若標準版與 MGVF 共用同一個 bottle，安裝／修復 runtime 仍會改動共用的 Windows 環境。本次 bottle 已有合適的原生 runtime，成功的關鍵是這個單次啟動的 DLL 選擇設定。以上是此 build 的實測處理方式；更新遊戲或 CrossOver 後應重新確認版本與錯誤原因。

### 後續修正：直接點 CrossOver 原本的遊戲圖示

上面的終端機命令只解決單次啟動。後續已把相同參數保存在 CrossOver 的 **FINAL FANTASY RESONANCE 共用捷徑**，不再需要每次輸入命令或另開 macOS 啟動器，也不需要 Cheat Engine。

本次原圖示指向 Windows `.url` 檔案，內容是 `steam://rungameid/3259780`，並非直接執行 `FFRS.exe`。當 Steam 已在執行時，不能依賴替網址捷徑新增的環境變數傳給既有 Steam 程序。GUI「運行命令」雖有環境變數欄位，本次最終採用 CrossOver 隨附的 `cxmenu` 工具，替換原圖示的實際啟動命令。

實際處理流程：

1. 備份 bottle 的 `cxmenu.conf`、`cxbottle.conf`，以及 Resonance 在 Windows 桌面與開始選單中的兩個 `.url` 原檔。
2. 將這兩個原檔移到掃描範圍以外的備份目錄。這可避免 CrossOver 重新掃描 Windows 捷徑時，把自訂命令覆蓋回 Steam 網址捷徑；原檔保留供還原。
3. 使用標準版安裝目錄下的 `bin/cxmenu --bottle … --create … --type raw --command … --icon … --description … --install`，更新 `cxmenu.conf` 中**原有的兩個 Resonance 項目**，保留圖示名稱與圖示。`--create` 在本次指定的是既有項目識別路徑，並非另建不同名稱的遊戲圖示。
4. 命令固定指向標準版 CrossOver 的 `bin/wine`，直接執行 `FFRS.exe`，並帶入上方相同的 `SteamAppId`、`SteamGameId`、`--no-update` 與 `--dll …=n,b` 參數。不要用會隨目前 CrossOver 版本改變的程式路徑。
5. 比對前後設定：只有 Resonance 的兩個選單項目改變，`cxbottle.conf` 位元組相同，其他遊戲（包含忍者龍劍傳 4）的捷徑未變。關閉遊戲後，從 CrossOver 原本的圖示啟動；使用者確認正常進入標題畫面，沒有 VC++ 錯誤。

**共用範圍：** 本機標準版與 MGVF 共用 Steam bottle 及選單設定，因此兩邊看到的是同一份 Resonance 捷徑。經使用者確認後，只修改這個遊戲的捷徑，固定由標準版啟動；沒有修改 MGVF 程式、圖形選項、全 bottle DLL 覆寫或其他遊戲設定。不要把這種共用捷徑修正描述成只在一個 GUI 中生效。

**日後使用：** 先讓該 bottle 的標準版 Steam 開啟並登入，再點 CrossOver 裡的 **FINAL FANTASY RESONANCE**。此修正不會替 Steam 收藏庫的「開始遊戲」按鈕加入參數。移動 CrossOver／遊戲、重建捷徑或更新後若設定改變，需重新確認儲存的命令。

**還原：** 將備份的兩個 `.url` 放回各自原位置，還原 `cxmenu.conf` 中對應的兩個項目，再用 CrossOver 的選單工具重新匯出／整理。若其間還有其他捷徑變動，不要直接覆蓋整份舊 `cxmenu.conf`。本機路徑與備份沒有放進此公開 repo。

## 驗證狀態（2026-10-26）

- 六個 Lua 項目通過 CE 語法檢查。
- 雙語選單：505 筆實機資料表名稱／ID／分類對應通過；目前背包 9 項選單與數量輸入提示的雙語標籤通過，取消後背包資料完全不變。
- Gil：600 → 1,000,000，重新讀取確認成功。
- 道具：以 CT 第 04 項的實際腳本測試藥水 13 → 14 → 13；還原後整份背包位元組一致。
- 道具選擇取消、非法數量、過期的背包與數量檢查通過，未改動背包。
- 第 05 項：雷因與拉斯韋爾 0 → 15,848,325 EXP，遊戲等級計算與即時角色欄位均為 Lv.99；使用者確認兩人選單顯示 Lv.99。
- 升級後即時角色能力已更新；已達 Lv.99 時重複執行，存檔角色資料位元組不變。
- 裝備包實機測試：15 種裝備共新增 64 件，全數讀回正確；既有背包數量、Gil、角色資料未變。取消不寫入，重複執行新增 0 件，背包位元組不變。新增裝備全數可由雙語選單資料列出。
- **道具／新裝備畫面顯示與存檔重載後的持續性尚未驗證。** 道具測試以代入選擇及輸入值執行原 CT 腳本完成，未宣稱選擇對話框的人工操作已驗證。

## 原始碼

- `src/game_connection.lua`：版本檢查、目前存檔與資料表定位。
- `src/item_names.lua`：官方英文／繁體中文道具名稱與分類；只含名稱，不含敘述或劇情。
- `src/unreal_tables.lua`：Unreal 資料表的尋找、稀疏資料列讀取與驗證。
- `src/inventory_items.lua`：已持有道具清單、數量寫入與背包變更檢查。
- `src/party_progression.lua`：角色陣列驗證、隊伍成員與 Lv.99 經驗值規劃。
- `src/memory_checks.lua`：原生遊戲函式的機器碼特徵檢查。
- `src/party_upgrade.lua`：升級函式驗證、角色升級與結果讀回。
- `src/inspect_save.lua`：唯讀存檔檢查。
- `src/set_gil.lua`：設定金錢。
- `src/list_inventory.lua`：列出背包 ID 與數量。
- `src/edit_item_quantity.lua`：雙語道具選單與數量修改。
- `src/upgrade_party_to_level_99.lua`：目前隊伍升至 Lv.99。
- `src/grant_endgame_equipment.lua`：補足全角色終盤裝備。
- `build.py`：產生可獨立使用的 CT。

`build.py` 的 `TABLE_ENTRIES` 明確列出各項目的固定 ID、顯示名稱、來源檔案與輔助程式依賴；不以檔名編號或清單順序推測依賴。顯示順序可調整，既有 ID 應保留。

`GAMEPLAY_HELPER_SOURCES` 列出共用檔案的組合順序。道具操作依賴資料表與名稱對照；升級操作依賴角色規劃與記憶體檢查。這些 Lua 檔案在產生時串接到同一作用域，保留 `local` 函式，不需要額外的 Lua 套件載入器。現有進階項目仍帶入完整輔助程式組，保持已驗證的 CT 內容完全一致。

新增共用函式時，依職責放入上述檔案；新增輔助檔則加入 `GAMEPLAY_HELPER_SOURCES`，放在呼叫它的檔案之前。輔助檔應以換行結尾。來源不存在時，產生器會在寫出 CT 前停止。

新增功能時：在 `src/` 建立依功能命名的 Lua 檔，於 `TABLE_ENTRIES` 加入唯一 ID 與來源路徑，再執行產生器。共享的定位與資料操作邏輯放在對應輔助檔，功能檔負責操作流程與介面。產生器會拒絕重複 ID、重複來源及遺漏的來源檔案。

請修改 Lua 原始碼並重新產生 CT，避免直接編輯產生的 CT。僅整理程式碼時，可比較產生前後 CT 的 SHA-256；涉及執行邏輯變更時，再進行 CE 語法檢查與相應實機驗證。

使用 Python 3：

```sh
python3 build.py
```

專案不包含遊戲檔案、個人存檔、記憶體傾印或本機測試紀錄，也不會修改 CrossOver 設定。CT 不含啟動自動執行的 Lua；只有手動啟用項目時才執行。

資料結構來源與授權見 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。本專案為非官方工具，與 Square Enix 無關。
