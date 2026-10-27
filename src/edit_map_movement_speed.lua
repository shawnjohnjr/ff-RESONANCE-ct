local previous=_G.FFRS_MAP_SPEED_RUNTIME
if previous and previous.running then previous.stop()end
local s=connect(true);local b=battleObjects(s)
local speed=mapMovementSpeed(s,b,true)
local list=createStringlist()
for _,label in ipairs({'自動：徒步 3x／騎乘 3.5x（取消恢復）','1x — 恢復原速 / Restore original','1.5x','2x','3x'})do list.add(label)end
local ok,index=pcall(showSelectionList,'地圖移速 / Map movement speed','目前 '..speed.multiplier..'x。自動模式會跟隨上下騎乘；其他倍率為單次修改。',list,false)
list.destroy()
if not ok then b.clear();error(index)end
if index==nil or index<0 then b.clear();return end
if index==0 then startMapSpeedRuntime(s,b);return end
local multipliers={1,1.5,2,3}
local applied,walk,run,jog=pcall(speed.apply,assert(multipliers[index],'Invalid selection'))
b.clear()
if not applied then error(walk)end
showMessage(string.format('地圖移速 %sx：走路 %g／跑步 %g／慢跑 %g。停止再移動即可刷新。取消勾選不還原；還原請重新執行並選 1x。',multipliers[index],walk,run,jog))
