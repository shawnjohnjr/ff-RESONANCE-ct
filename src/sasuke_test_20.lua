local s=connect()
local ids={[10297]=true,[10299]=true}
local rows={}
for i=0,s.count-1 do
 local a=s.inventory+i*8; local id=readInteger(a)
 if ids[id] or id==10298 then
  assert(not rows[id],'Duplicate inventory ID')
  local q=readInteger(a+4);assert(q and q>=0 and q<100000,'Invalid quantity')
  rows[id]={a=a,q=q}
 end
end
local b=assert(_G.FFRS_SASUKE_BACKUP,'本次 CE 沒有備份，請勿猜測數量')
assert(b.save==s.save and b.pid==s.pid,'Save/process changed; stop')
for id,q in pairs(b.values) do assert(rows[id] and rows[id].q==0,'Quantity changed after test; do not overwrite') end
for id,q in pairs(b.values) do assert(writeInteger(rows[id].a+4,q) and readInteger(rows[id].a+4)==q,'Restore failed') end
_G.FFRS_SASUKE_BACKUP=nil
showMessage('兩種佐助刀已還原原數量。')
