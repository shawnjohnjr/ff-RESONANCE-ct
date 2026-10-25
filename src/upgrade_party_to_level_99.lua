local s=connect()
local plan,party,n,units=partyPlan(s)
local answer=inputQuery('目前隊伍升至 Lv.99','只修改目前隊伍 '..n..' 名角色。請停在選單；輸入 99 執行，取消則不修改：','99')
if not answer then return end
assert(tonumber(answer)==99,'Enter 99 or cancel')
local report=setParty99(s,plan,party,n,units)
showMessage(table.concat(report,'\n')..'\n請重開角色選單核對，確認後另存新欄位。取消勾選不會還原。')
