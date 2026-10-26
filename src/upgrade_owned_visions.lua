assert(not (_G.FFRS_VISION_ACQUISITION and _G.FFRS_VISION_ACQUISITION.running),'Wait for entry 10 to finish')
local previous=_G.FFRS_VISION_UPGRADE
assert(not previous or not previous.running,'A vision upgrade is already running')
local battle=_G.FFRS_BATTLE_AUTOMATION
assert(not battle or not battle.running,'請先關閉第 07、08 項 / Turn off entries 07 and 08 first')
local s=connect();local snapshot=visionSnapshot(s)
assert(#snapshot.visions>0,'No owned visions')
local function choose(title,prompt,values)
 local list=createStringlist();for _,value in ipairs(values)do list.add(value)end
 local ok,index=pcall(showSelectionList,title,prompt,list,false);list.destroy()
 if not ok then error(index)end
 return index
end
local labels={'全部已持有幻兵 / All owned visions'}
for _,v in ipairs(snapshot.visions)do labels[#labels+1]=visionName(v.id)..' | ID '..v.id end
local which=choose('強化已持有幻兵 / Upgrade owned visions','選擇幻兵；不會取得未持有幻兵。 / Select owned visions only.',labels)
if which==nil or which<0 then return end
local selected=which==0 and 0 or assert(snapshot.visions[which],'Invalid vision selection').id
local modes={'awakening','synchro','both'}
local mode=choose('強化項目 / Upgrade type','MR 只修改目前隊伍，不修改其他角色。 / MR affects the current party only.',{
 '覺醒升至遊戲上限 / Maximum awakening',
 '目前隊伍 MR 升至遊戲上限 / Maximum MR for current party',
 '兩項都升滿 / Both',
})
if mode==nil or mode<0 then return end
mode=assert(modes[mode+1],'Invalid upgrade mode')
showMessage('按 OK 後切回遊戲並保持前景，停在幻兵選單。完成後會顯示結果。\nAfter OK, keep the game foreground at the vision menu. A completion message will appear.\n取消勾選只停止尚未完成項目，不會還原已完成強化。')
startVisionUpgrade(s,snapshot,selected,mode)
