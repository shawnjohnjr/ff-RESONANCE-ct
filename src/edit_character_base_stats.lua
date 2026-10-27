assert(not (_G.FFRS_BASE_STAT_ACTION and _G.FFRS_BASE_STAT_ACTION.running),'Stat edit already pending')
local function choose(title,prompt,labels)
 local list=createStringlist();for _,v in ipairs(labels)do list.add(v)end
 local ok,index=pcall(showSelectionList,title,prompt,list,false);list.destroy();if not ok then error(index)end
 if index==nil or index<0 then return nil end;return index+1
end
local s=connect();local snapshot=baseStatSnapshot(s)
local labels,ids={},{}
for _,u in ipairs(snapshot.units)do if u.join==0 then ids[#ids+1]=u.id;labels[#labels+1]=CHARACTER_NAMES[u.id]end end
local undo=_G.FFRS_BASE_STAT_UNDO
local canUndo=undo and undo.pid==s.pid and undo.save==s.save
if canUndo then labels[#labels+1]='還原上一次能力修改 / Undo last stat edit'end
local choice=choose('角色能力 / Character stats','選擇目前已加入的角色。修改永久加成，不是裝備後的最終數值。',labels)
if not choice then return end
local op
if canUndo and choice==#labels then
 local u=assert(snapshot.byId[undo.unit]);assert(u.values[undo.stat]==undo.after,'Value has changed since the edit; undo cancelled')
 op=baseStatPlan(snapshot,undo.unit,undo.stat,undo.before)
else
 local id=assert(ids[choice]);local u=snapshot.byId[id];local statLabels={}
 for _,stat in ipairs(BASE_STATS)do statLabels[#statLabels+1]=stat.label..'  +'..u.values[stat.id]end
 local index=choose(CHARACTER_NAMES[id],'選擇能力；右側為累計永久加成。',statLabels);if not index then return end
 local stat=BASE_STATS[index]
 local value=inputQuery('設定永久加成 / Set permanent bonus',stat.label..'：輸入新的累計加成（0–'..stat.max..'），不是本次增加量。',tostring(u.values[stat.id]))
 if value==nil then return end
 op=baseStatPlan(snapshot,id,stat.id,tonumber(value))
end
if op.delta==0 then showMessage('數值相同，無需修改。 / No change needed.');return end
startBaseStatEdit(s,snapshot,op,function()
 showMessage(CHARACTER_NAMES[op.unit.id]..' / '..op.stat.label..'：+'..op.before..' → +'..op.target..'\n請重開角色選單確認。取消勾選不會還原；再次執行可選還原上一次修改。')
end)
