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
