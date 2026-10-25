local s=connect()
local answer=inputQuery('設定持有 Gil','目前 '..s.gil..' Gil。輸入目標金額（0–9,999,999），取消則不修改：',tostring(s.gil))
if not answer then return end
local target=tonumber(answer)
assert(target and target==math.floor(target) and target>=0 and target<=9999999,'Enter a whole number from 0 to 9999999')
local current=connect()
assert(current.save==s.save and current.manager==s.manager and current.gil==s.gil,'Save or money changed during input; retry on the map')
if target==s.gil then showMessage('金額相同，未修改。');return end
assert(writeInteger(s.save+0x28,target),'Money write failed')
if readInteger(s.save+0x28)~=target then
 writeInteger(s.save+0x28,s.gil)
 error('Money read-back failed; attempted to restore original amount')
end
showMessage('已將持有 Gil 設為 '..target..'。請重開選單核對，確認後另存新欄位。取消勾選不會還原。')
