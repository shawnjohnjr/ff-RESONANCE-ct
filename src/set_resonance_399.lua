local backupDir=assert(os.getenv('TEMP') or os.getenv('TMP'),'Cannot locate temporary backup directory')
local backupPath=backupDir..[[\FFRS-resonance-399-backup.txt]]
print('FFRS backup: '..backupPath)
-- One-time resonance counter adjustment. No timer or freeze.
local s=connect()
local address=s.save+0x58
local before=assert(readInteger(address),'Cannot read resonance counter')
assert(before>=0,'Invalid resonance counter')
if before>=399 then showMessage('目前共鳴計數為 '..before..'，已達 399 或以上，不修改。');return end
local backup=assert(io.open(backupPath,'a'))
backup:write(os.date('%Y-%m-%d %H:%M:%S'),' finishblowCount_before=',before,' target=399\n')
backup:flush();backup:close()
local now=connect()
assert(now.save==s.save and now.manager==s.manager,'Save changed; no changes made')
assert(readInteger(address)==before,'Counter changed; retry while idle')
assert(writeInteger(address,399),'Counter write failed')
assert(readInteger(address)==399,'Counter readback failed; inspect before proceeding')
print('RESONANCE_COUNTER',before,'->',399,'ONE_TIME')
showMessage('共鳴計數：'..before..' → 399。\n請正常施放一次共鳴，測試 400 次成就。\n沒有計時器或鎖定；原值已記錄。')
