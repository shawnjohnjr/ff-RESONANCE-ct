local backupDir=assert(os.getenv('TEMP') or os.getenv('TMP'),'Cannot locate temporary backup directory')
local backupPath=backupDir..[[\FFRS-sasuke-quantity-backup.txt]]
print('FFRS backup: '..backupPath)
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
assert(rows[10298] and rows[10298].q>0,'先用 17 補入古老的刀')
assert(not _G.FFRS_SASUKE_BACKUP,'已有備份，請先用 20 還原')
showMessage('請先確認所有角色已卸下佐助刀／佐助刀·改，並停在選單。此操作只清空這兩件的背包數量。')
local b={save=s.save,pid=s.pid,values={}}
for id in pairs(ids) do if rows[id] then b.values[id]=rows[id].q end end
local f=assert(io.open(backupPath,'a'))
f:write(os.date(), ' save=',tostring(s.save),' pid=',tostring(s.pid),'\n')
for id,q in pairs(b.values) do f:write(id,' ',q,'\n') end
f:close()
_G.FFRS_SASUKE_BACKUP=b
for id in pairs(b.values) do
 assert(readInteger(rows[id].a)==id and readInteger(rows[id].a+4)==b.values[id],'Inventory changed')
 assert(writeInteger(rows[id].a+4,0) and readInteger(rows[id].a+4)==0,'Write failed; use 20 to restore')
end
showMessage('兩種佐助刀背包數量已暫時設為 0；古老的刀保留。離開房間再進入測試。用 20 還原。')
