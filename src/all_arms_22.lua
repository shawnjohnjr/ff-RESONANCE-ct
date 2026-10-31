local s=connect()
local ids={[10197]=true,[10199]=true,[10297]=true,[10299]=true,[10397]=true,[10399]=true,[10496]=true,[10498]=true,[10597]=true,[10599]=true,[10696]=true,[10698]=true,[10797]=true,[10799]=true,[10897]=true,[10899]=true,[11397]=true,[11399]=true,[11097]=true,[11099]=true,[11597]=true,[11599]=true,[12097]=true,[12099]=true}
local rows={}
assert(s.count<=5000,'Inventory too large')
for i=0,s.count-1 do
 local a=s.inventory+i*8;local id=readInteger(a)
 if ids[id] then
  assert(not rows[id],'Duplicate item');local q=readInteger(a+4)
  assert(q and q>=0 and q<100000,'Invalid quantity');rows[id]={a=a,q=q}
 end
end
local b=assert(_G.FFRS_ALL_ARMS_BACKUP,'本次 CE 沒有整套備份')
assert(b.save==s.save and b.pid==s.pid,'Save/process changed')
for id,q in pairs(b.values) do assert(rows[id],'Inventory entry missing; stop') end
local now=connect();assert(now.save==s.save and now.inventory==s.inventory and now.count==s.count,'Inventory changed')
for id,r in pairs(rows) do assert(readInteger(r.a)==id and readInteger(r.a+4)==r.q,'Quantity changed') end
for id,q in pairs(b.values) do
 local r=rows[id];local target=math.max(r.q,q)
 assert(writeInteger(r.a+4,target) and readInteger(r.a+4)==target,'Restore failed')
end
_G.FFRS_ALL_ARMS_BACKUP=nil
showMessage('已補回原數量，保留測試後新取得的武具。')
