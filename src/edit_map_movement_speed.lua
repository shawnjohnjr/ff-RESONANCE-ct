local s=connect(true);local b=battleObjects(s)
local speed=mapMovementSpeed(s,b)
local list=createStringlist()
for _,label in ipairs({'1x — 恢復原速 / Restore original','1.5x','2x','3x'})do list.add(label)end
local ok,index=pcall(showSelectionList,'地圖移速 / Map movement speed','目前 '..speed.multiplier..'x。只修改目前地圖角色；停止再移動即可刷新。',list,false)
list.destroy()
if not ok then b.clear();error(index)end
if index==nil or index<0 then b.clear();return end
local multipliers={1,1.5,2,3}
local applied,walk,run,jog=pcall(speed.apply,assert(multipliers[index+1],'Invalid selection'))
b.clear()
if not applied then error(walk)end
showMessage(string.format('地圖移速 %sx：走路 %g／跑步 %g／慢跑 %g。停止再移動即可刷新。取消勾選不還原；還原請重新執行並選 1x。',multipliers[index+1],walk,run,jog))
