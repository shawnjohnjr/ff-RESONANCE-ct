# 維護與版本遷移指南 / Maintenance and version migration

適用對象：維護這份 CT 的開發者。目前驗證版本為 Steam build **24250053**。

## 1. 先區分三種位址

| 類型 | 目前做法 | 改版時要做什麼 |
| --- | --- | --- |
| 模組基底 | 執行時取得 `FFRS-Win64-Shipping.exe` 的載入位址 | 不記錄上次執行的絕對位址 |
| 函式 RVA | 模組基底 + 固定 RVA，重要入口以 `checkCode` 驗證 | 重新定位、反組譯，確認簽名、參數及副作用 |
| 物件／欄位 | 動態找物件，再使用已驗證欄位偏移 | 重驗類別、所有權、物件生命期、陣列大小及欄位含義 |

RVA 與欄位偏移都與版本有關。ASLR 位址搬移與遊戲改版是不同問題。
`src/game_connection.lua` 目前檢查 PE timestamp 與 image size；它不是完整檔案雜湊。
檢查通過不等於新版本相容，未知版本不得只放寬檢查後直接發佈。

## 2. 新版本先做唯讀盤點

1. 保存已驗證版本的 CT、Git revision 與測試紀錄，使用另存的測試存檔。
2. 記錄 Steam build、EXE SHA-256、PE timestamp、image size、CE 與 CrossOver 版本。
3. 確認名稱池、GUObjectArray、World、物件序號與類別繼承仍可正確讀取。
4. 對需要遷移的功能逐一核對，不因一項可用就推論其他功能可用。
5. 只操作指定的標準版 CrossOver；不得把遷移工作擴及 MGVF 或其他遊戲設定。

這份指南不表示 CT 已具備自動改版相容能力。

## 3. 每個原生函式與欄位需要的證據

新增或修改時，在所屬模組旁記錄：

- 可讀名稱、所屬類別、RVA／偏移，以及支持該判讀的 SDK 或反組譯位置。
- 呼叫參數、回傳值、呼叫執行緒與必要前提。
- 物件來源與所有權鏈；不可使用一次測試觀察到的絕對物件位址。
- 寫入哪些欄位、是否會重建效果、改變快照、發送 UI 通知或觸發存檔。
- 失效時的處理：等待、停止，或由使用者重新啟用；不得繼續猜測寫入。
- 已確認事實與尚待驗證的推論，分開寫清楚。

AOB 可以協助找出候選函式，但仍需驗證唯一性、指令邊界、呼叫慣例與語義。
不要只把舊 RVA 換成第一個搜尋結果。欄位位置不能靠相同數值判定。

## 4. 第 15 項的維護地圖

| 模組 | 職責 |
| --- | --- |
| `party_limit_state.lua` | 每場／每位成員只補一次的狀態 |
| `party_limit_roster.lua` | 目前世界的戰鬥管理器、我方角色與生命期驗證 |
| `party_limit_snapshot.lua` | 指令資源快照的定位、驗證及同步寫入 |
| `party_limit_runtime.lua` | 前景與場景檢查、排程、讀回、停止及有界紀錄 |
| `enable_party_limit.lua` / `disable_party_limit.lua` | 不搶焦點的啟停入口 |

關鍵細節見 [槽量還原調查](party-limit-investigation.md)。目前資料鏈：

`World → CPP_BtlManager → m_DelegateEventList → CPP_BtlDelEventCmd → snapshot[0] → resource row`

資源列用的是 **battle actor unique ID**，不是角色 ID 1001–1008。
目前只支援一份未排隊指令的快照；有多份時等待，不猜哪份可以改。

**陷阱：** 即時槽量 `parameter + 0x118` 可以成功寫入並讀回滿槽，但換指令時
遊戲會從資源快照恢復舊值。因此補槽必須在同一次受保護的遊戲執行緒呼叫中，
同步快照的 Limit 欄位與原本的槽量設定函式。不要同步 HP、MP 或整份角色結構。
不要用持續鎖滿掩蓋還原問題，那會改變「每場一次、消耗正常」的行為。

本項寫入程式只由既有遊戲執行緒派送器呼叫，不修改遊戲原生指令。
臨時診斷攔截不得留在正式 CT；調查後恢復原指令，並核對還原結果。

## 5. 遷移實作順序

1. 先寫唯讀解析與驗證，讓錯誤物件、重複 ID、壞陣列與未知狀態被拒絕。
2. 更新相關功能的 code fingerprint、RVA 與欄位，保留集中、具名的模組邊界。
3. 使用遊戲執行緒執行原生操作；寫入前重驗場景與物件生命期，避免查找和執行之間換場。
4. 先測單一成員的小幅、可還原變動，再測全員與跨場。
5. 只有新版本的必要驗證完成後，才更新 `connect` 的版本門檻。
6. 透過 `build.py` 重建完整版與獨立表，禁止只修生成後的 XML。

## 6. 發佈前檢查

- 執行相關 `tests/*_test.lua`，編譯 CT 的 Lua 區塊並解析 XML。
- 比較未修改項目的生成腳本，避免打包順序改動造成其他項目回歸。
- 第 15 項：全員滿槽 → 普通攻擊換人後仍保留 → 使用極限技正常扣槽 →
  下一場不用重勾即補滿。
- 測前景／背景、取消勾選、一般選單及退出遊戲；未測的案例明列為未驗證。
- 核對包含擴充槽的實際上限；未測過較高上限，不宣稱已實測。
- 不開完成／錯誤彈窗；診斷使用狀態欄位和有界紀錄，不搶遊戲焦點。
- README 記錄版本、測試範圍、限制；只有已實測的版本才稱為支援版本。
- 保留可回退的已驗證 CT。提交／推送依使用者授權，不把測試草稿當正式發佈。

## English maintenance checklist

The currently tested executable is Steam build **24250053**. Runtime module bases
and object addresses are discovered dynamically; function RVAs and field offsets
remain version-specific. The PE timestamp/image-size gate is not a full executable
hash and cannot prove semantic compatibility.

For a new build:

1. Preserve the working CT and Git revision; record build ID, executable SHA-256,
   PE metadata, CE and CrossOver versions. Use a separate test save.
2. Revalidate names, object registry, world ownership, class inheritance and object
   lifetime identities before performing writes.
3. Locate each affected function and verify its calling convention, thread,
   side effects and code fingerprint. A unique AOB match is only a candidate.
4. Revalidate field meaning and container bounds. Never promote a session-specific
   object address or a matching integer into a permanent pointer/offset.
5. Keep changes in named source modules and rebuild with `build.py`. Do not edit
   only generated CT XML. Keep unrelated entries byte-for-byte unchanged when possible.
6. Run the focused Lua tests and compile all generated chunks. Validate the actual
   game transitions; immediate write/readback alone is insufficient.
7. For entry 15, test full party gauges, ordinary-attack turn changes, normal Limit
   consumption and automatic refill in the next battle without retoggling. Record
   any untested caps or lifecycle scenarios explicitly.
8. Remove diagnostic patches, keep bounded logs and silent status reporting, update
   both READMEs, and retain the last verified CT for rollback. Do not touch MGVF.

Entry 15's key invariant: the live Limit value and the command resource snapshot
must be updated together on the guarded game thread. Snapshot rows use battle
unique IDs, not character IDs. Only the Limit field is synchronized; HP/MP and
other snapshot state remain untouched. This preserves once-per-battle behavior
without an infinite-gauge hook. See the linked investigation for observed native
restore sites and the failed approaches that led to this design.
