local s=connect()
local pack={
 {10199,1,1,1},
 {10299,1,1,2},
 {10399,1,1,3},
 {10498,1,1,4},
 {10599,1,1,5},
 {10698,1,1,8},
 {10799,1,1,6},
 {10899,1,1,7},
 {11399,1,2,9},
 {11099,1,2,10},
 {11599,1,2,11},
 {12099,1,3,0},
}
local catalog={}
for _,r in ipairs(tableRows(s,findTable(s,'EQUIPMENT_ITEM_DATA'),'EQUIPMENT_ITEM_DATA')) do catalog[readInteger(r.p+8)]=r.p end
checkCode(s.base+0x5107500,{0x48,0x89,0x5C,0x24,0x08,0x57,0x48,0x83,0xEC,0x20,0x8B,0xDA,0x8B,0xF9})
local function inventoryMap(state)
 assert(state.count<=5000,'Inventory too large')
 local map={}
 for i=0,state.count-1 do
  local p=state.inventory+i*8;local id=readInteger(p);local qty=readInteger(p+4)
  assert(id and qty and qty>=0 and qty<=2147483647 and map[id]==nil,'Invalid/duplicate inventory record')
  map[id]=qty
 end
 return map
end
local expected=inventoryMap(s)
local counts={0,0,0}
for _,v in ipairs(pack) do counts[v[3]]=counts[v[3]]+1 end
local lines={'十二件各補足背包至少 1 件；不改試煉旗標，成就是否觸發待測。',''}
for _,v in ipairs(pack) do
 local row=assert(catalog[v[1]],'Equipment missing from this build')
 assert(readBytes(row+0x70,1)==3 and readBytes(row+0x80,1)==v[3] and readBytes(row+0x81,1)==v[4],'Equipment category mismatch')
 assert(itemNames[v[1]] and itemNames[v[1]].kind==3,'Equipment label missing')
 lines[#lines+1]=itemDisplayName(v[1],3)..' × '..v[2]
end
local answer=inputQuery('一般版十二武具',table.concat(lines,'\n')..'\n\n請停在選單並備份存檔。輸入 YES 執行，取消則不修改：','')
if not answer then return end
assert(answer:upper()=='YES','Enter YES or cancel')
local added=0
for _,v in ipairs(pack) do
 local current=connect()
 assert(current.save==s.save and current.manager==s.manager,'Save changed; stopped (earlier grants may remain)')
 local actual=inventoryMap(current)
 for id,qty in pairs(expected) do assert(actual[id]==qty,'Inventory changed; stopped (earlier grants may remain)') end
 for id,qty in pairs(actual) do assert(expected[id]==qty,'Inventory changed; stopped (earlier grants may remain)') end
 local old=actual[v[1]] or 0
 if old<v[2] then
  executeCodeEx(0,10000,s.base+0x5107500,v[1],v[2]-old)
  local after=connect();assert(after.save==s.save,'Save changed after grant; stop')
  expected[v[1]]=v[2]
  actual=inventoryMap(after)
  for id,qty in pairs(expected) do assert(actual[id]==qty,'Grant read-back failed; stop and check inventory') end
  for id,qty in pairs(actual) do assert(expected[id]==qty,'Unexpected inventory change; stop and check inventory') end
  added=added+v[2]-old
 end
end
showMessage('一般版十二武具完成，本次新增 '..added..' 件。請重開裝備選單，自行選擇各角色裝備；確認後另存新欄位。')
