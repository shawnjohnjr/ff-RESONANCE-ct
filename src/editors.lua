-- UE DataTable rows: sparse TMap<FName, uint8*> with allocation-bit checks.
local function tableRows(s,o,expected)
 assert(s.cname(o)=='DataTable' and s.oname(readPointer(o+0x28))==expected,'Data table changed; retry')
 local m=o+0x30;local p=readPointer(m);local n=readInteger(m+8);local cap=readInteger(m+12)
 assert(n and cap and n>=0 and n<=cap and cap<=10000,'Invalid table size')
 assert(n==0 or (p and p>65536),'Invalid row data')
 local bits=readPointer(m+0x20);if not bits or bits==0 then bits=m+0x10 end
 local bitCount=readInteger(m+0x28);assert(bitCount and bitCount>=n and bitCount<=10000,'Invalid allocation flags')
 local out={}
 for i=0,n-1 do
  local b=assert(readInteger(bits+math.floor(i/32)*4),'Unreadable allocation flags')
  if (b & (1 << (i%32)))~=0 then
   local a=p+i*24;local row=readPointer(a+8)
   assert(row and row>65536,'Invalid row pointer')
   out[#out+1]={key=s.name(readInteger(a)),p=row}
  end
 end
 return out
end
local function findTable(s,row)
 local found
 for _,t in ipairs(s.tables) do
  if t.row==row then
   assert(s.at(t.index)==t.object and s.oname(t.object)==t.name,'Table cache expired; reopen CT')
   assert(not found,'Multiple matching tables; stop')
   found=t.object
  end
 end
 return assert(found,'Required table not loaded: '..row)
end
local function inventoryChoices(s)
 local catalog={}
 for _,kind in ipairs({'CONSUMABLES_ITEM_DATA','EQUIPMENT_ITEM_DATA'}) do
  for _,r in ipairs(tableRows(s,findTable(s,kind),kind)) do
   local id=readInteger(r.p+8);local typ=readBytes(r.p+0x70,1)
   if id and id>0 and (typ==1 or typ==3) and r.key~='?' then
    assert(not catalog[id],'Duplicate item ID')
    catalog[id]={name=itemDisplayName(id,typ),kind=typ}
   end
  end
 end
 assert(s.count<=5000,'Inventory too large')
 local out,seen={},{}
 for i=0,s.count-1 do
  local a=s.inventory+i*8;local id=readInteger(a);local qty=readInteger(a+4)
  assert(id and qty and qty>=0,'Invalid inventory entry')
  local item=catalog[id]
  if item and qty>0 then
   assert(not seen[id],'Duplicate owned item ID');seen[id]=true
   out[#out+1]={id=id,quantity=qty,address=a,name=item.name,kind=item.kind}
  end
 end
 table.sort(out,function(a,b)return a.id<b.id end)
 return out
end
local function setItem(s,item,target)
 assert(target and target==math.floor(target) and target>=1 and target<=99,'Quantity must be 1..99')
 local now=connect()
 assert(now.save==s.save and now.manager==s.manager and now.inventory==s.inventory and now.count==s.count,'Inventory changed; reopen the picker')
 assert(readInteger(item.address)==item.id and readInteger(item.address+4)==item.quantity,'Item changed during input; retry')
 if target==item.quantity then return end
 assert(writeInteger(item.address+4,target),'Item write failed')
 if readInteger(item.address+4)~=target then
  writeInteger(item.address+4,item.quantity)
  error('Item read-back failed; attempted to restore original quantity')
 end
end
local function arrayAt(a,max)
 local p=readPointer(a);local n=readInteger(a+8);local cap=readInteger(a+12)
 assert(n and cap and n>=0 and n<=cap and cap<=max,'Invalid array')
 assert(n==0 or (p and p>65536),'Invalid array pointer')
 return p,n
end
local function partyPlan(s)
 local party,n=arrayAt(s.save+0x90,8);assert(n>0,'No party members')
 local units,un=arrayAt(s.save+0x60,64)
 local byId={}
 for i=0,un-1 do local a=units+i*0xA0;local id=readInteger(a);assert(id and not byId[id],'Invalid unit ID');byId[id]=a end
 local definitions={}
 for _,r in ipairs(tableRows(s,findTable(s,'UNIT_PARAMETER'),'UNIT_PARAMETER')) do definitions[readInteger(r.p+8)]={curve=readInteger(r.p+0x3C),name=r.key} end
 local curves={}
 for _,r in ipairs(tableRows(s,findTable(s,'UNIT_LEVEL_PARAMETER_LIST'),'UNIT_LEVEL_PARAMETER_LIST')) do curves[readInteger(r.p+8)]=readPointer(r.p+0x10) end
 local out,seen={},{}
 for i=0,n-1 do
  local id=readInteger(party+i*4)
  assert(id and id>=1001 and id<=1008 and not seen[id],'Unexpected party member');seen[id]=true
  local a=assert(byId[id],'Party member missing from save');local def=assert(definitions[id],'Missing unit definition')
  local levels={}
  for _,r in ipairs(tableRows(s,assert(curves[def.curve],'Missing curve'),'UNIT_LEVEL_PARAMETER')) do
   local lv=readInteger(r.p+8);local xp=readInteger(r.p+12)
   if lv and lv>=1 and lv<=99 then assert(not levels[lv] and xp and xp>=0,'Invalid level curve');levels[lv]=xp end
  end
  local sum=0;for lv=1,99 do sum=sum+assert(levels[lv],'Incomplete level curve') end
  assert(sum>0 and sum<=2147483647,'Invalid level-99 EXP')
  local old=readInteger(a+4);assert(old and old>=0,'Invalid current EXP')
  out[#out+1]={id=id,address=a,experience=old,target=sum,name=def.name,partyIndex=i}
 end
 return out,party,n,units
end
local function checkCode(a,bytes)
 local actual=readBytes(a,#bytes,true);assert(actual,'Game function unavailable')
 for i=1,#bytes do assert(actual[i]==bytes[i],'Game function mismatch; stop') end
end
local function checkLevelFunctions(s)
 checkCode(s.base+0x523BC00,{0x48,0x8B,0xC4,0x56,0x48,0x81,0xEC,0xD0,0,0,0})
 checkCode(s.base+0x524B3A0,{0x48,0x89,0x5C,0x24,0x18,0x48,0x89,0x74,0x24,0x20,0x57,0x48,0x81,0xEC,0xD0,1,0,0})
end
local function setParty99(s,plan,party,n,units)
 checkLevelFunctions(s)
 -- Preflight all targets with the game's own EXP-to-level calculation.
 for _,u in ipairs(plan) do
  assert(executeCodeEx(0,5000,s.base+0x523BC00,u.id,u.target)==99,'Game rejected level-99 threshold')
 end
 local report={}
 for _,u in ipairs(plan) do
  local now=connect();local pp,pn=arrayAt(now.save+0x90,8);local up=arrayAt(now.save+0x60,64)
  assert(now.save==s.save and now.manager==s.manager and pp==party and pn==n and up==units,'Party/save changed; stop')
  for _,member in ipairs(plan) do assert(readInteger(party+member.partyIndex*4)==member.id,'Party changed; stop') end
  assert(readInteger(u.address)==u.id and readInteger(u.address+4)==u.experience,'Character EXP changed; retry')
  if u.experience<u.target then
   -- Native SetPlayableUnitExperience(UnitId, EXP, isMaxStatusSet=false):
   -- updates save EXP and refreshes the live character parameters/skills.
   executeCodeEx(0,10000,s.base+0x524B3A0,u.id,u.target,0)
   assert(readInteger(u.address+4)==u.target,'EXP update did not finish; stop and check game')
  end
  local xp=readInteger(u.address+4)
  local lv=executeCodeEx(0,5000,s.base+0x523BC00,u.id,xp)
  assert(lv==99,'Level verification failed; stop and check game')
  report[#report+1]=string.format('%s（ID %d）：Lv.%d／EXP %d',u.name,u.id,lv,xp)
 end
 return report
end
