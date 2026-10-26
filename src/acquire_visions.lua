assert(not (_G.FFRS_VISION_ACQUISITION and _G.FFRS_VISION_ACQUISITION.running),'Vision acquisition already running')
assert(not (_G.FFRS_VISION_UPGRADE and _G.FFRS_VISION_UPGRADE.running),'Wait for entry 09 to finish')
assert(not (_G.FFRS_BATTLE_AUTOMATION and _G.FFRS_BATTLE_AUTOMATION.running),'請先關閉第 07、08 項 / Turn off entries 07 and 08')
local s=connect();local snapshot=visionSnapshot(s);local b=battleObjects(s)
local catalog=visionCatalog(s,b);local ids=missingVisions(snapshot,catalog,0)
if #ids==0 then showMessage('已持有全部 26 隻幻兵 / All 26 visions are already owned.');return end
local labels=createStringlist();labels.add('取得全部未持有幻兵 / Acquire all missing visions ('..#ids..')')
for _,id in ipairs(ids)do labels.add(visionName(id)..' | ID '..id)end
local ok,which=pcall(showSelectionList,'取得幻兵 / Acquire visions','僅新增未持有幻兵，保留既有成長。 / Only missing visions; existing growth is preserved.',labels,false)
labels.destroy();if not ok then error(which)end
if which==nil or which<0 then return end
local selected=which==0 and 0 or assert(ids[which],'Invalid vision selection')
local answer=inputQuery('取得幻兵 / Acquire visions',
 '請先備份存檔；停在地圖選單，並保持遊戲前景。\n新增幻兵為初始成長，可再用第 09 項強化。\n會更新收集成就進度；不代替祠堂／任務劇情。\n後續劇情重複取得的影響尚未完整驗證。\n\nBack up your save first. Stay in the field menu with the game foreground.\nNew visions have default growth; use entry 09 to upgrade.\nCollection achievements may advance. Shrine/quest events are not completed.\nLater duplicate story rewards have not been fully tested.\n\n輸入 YES 執行 / Type YES to proceed:','')
if not answer then return end
assert(answer:upper()=='YES','Enter YES or cancel')
startVisionAcquisition(s,snapshot,catalog,selected)
