local s=connect()
local pack={
 {10197,1,1,1},{10297,1,1,2},{10397,1,1,3},{10496,1,1,4},
 {10597,1,1,5},{10696,1,1,8},{10797,1,1,6},{10897,1,1,7},
 {11397,8,2,9},{11097,8,2,10},{11597,8,2,11},
 {11033,8,2,10}, -- Lorica Sancta / 神聖甲 (ホーリーメイル)
 {11329,8,2,9}, -- Lorica Apocalyptica / 終焉之鎧
 {12101,8,3,0},{12095,8,3,0},{12096,8,3,0},{12103,8,3,0},
 {12097,8,3,0}, -- Gold Hairpin+ / 黃金頭飾·改
 {12080,8,3,0}, -- Thunder God’s Earrings / 雷帝的耳環
 {12065,8,3,0}, -- Ribbon / 緞帶 (distinct from Super Ribbon)
 {12069,8,3,0}, -- Circlet of Enlightenment / 解脫之輪
 {12102,1,3,0}, -- Dragon Seal / 龍之紋章: prevents encounters when equipped
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
local lines={string.format('%d 種角色武器各至少 1 件；%d 種防具、%d 種飾品通常各至少 8 件（龍之紋章僅補足 1 件）。',counts[1],counts[2],counts[3]),'只補足背包數量，不自動裝備，不解鎖角色。',''}
for _,v in ipairs(pack) do
 local row=assert(catalog[v[1]],'Equipment missing from this build')
 assert(readBytes(row+0x70,1)==3 and readBytes(row+0x80,1)==v[3] and readBytes(row+0x81,1)==v[4],'Equipment category mismatch')
 assert(itemNames[v[1]] and itemNames[v[1]].kind==3,'Equipment label missing')
 lines[#lines+1]=itemDisplayName(v[1],3)..' × '..v[2]
end
local answer=inputQuery('全角色終盤裝備包',table.concat(lines,'\n')..'\n\n請停在選單並備份存檔。輸入 YES 執行，取消則不修改：','')
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
showMessage('終盤裝備包完成，本次新增 '..added..' 件。請重開裝備選單，自行選擇各角色裝備；確認後另存新欄位。')
