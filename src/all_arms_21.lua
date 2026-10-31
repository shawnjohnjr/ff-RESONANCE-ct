local backupDir=assert(os.getenv('TEMP') or os.getenv('TMP'),'Cannot locate temporary backup directory')
local backupPath=backupDir..[[\FFRS-all-arms-quantity-backup.txt]]
print('FFRS backup: '..backupPath)
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
assert(not _G.FFRS_ALL_ARMS_BACKUP,'已有備份；請先還原')
local b={save=s.save,pid=s.pid,values={}}
for id,r in pairs(rows) do b.values[id]=r.q end
-- Retain the earlier Sasuke backup so its removed upgraded blade is not lost.
local previous=_G.FFRS_SASUKE_BACKUP
if previous then
 assert(previous.save==s.save and previous.pid==s.pid,'Earlier backup belongs to a different save')
 for id,q in pairs(previous.values) do b.values[id]=math.max(b.values[id] or 0,q) end
end
local f=assert(io.open(backupPath,'a'))
f:write(os.date(),' save=',tostring(s.save),' pid=',tostring(s.pid),'\n')
for id,q in pairs(b.values) do f:write(id,' ',q,'\n') end
f:close()
local now=connect();assert(now.save==s.save and now.inventory==s.inventory and now.count==s.count,'Inventory changed')
for id,r in pairs(rows) do assert(readInteger(r.a)==id and readInteger(r.a+4)==r.q,'Quantity changed') end
_G.FFRS_ALL_ARMS_BACKUP=b
for id,r in pairs(rows) do assert(writeInteger(r.a+4,0) and readInteger(r.a+4)==0,'Write failed; use 22 to restore') end
_G.FFRS_SASUKE_BACKUP=nil
showMessage('十二武具的一般版與改版已清空背包數量。古老版保留。請離開房間再進入；22 可補回原數量。')
