from pathlib import Path
import xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parent
common=(ROOT/'src/common.lua').read_text(encoding='utf-8')
readonly='''
local s=connect()
showMessage(string.format('唯讀檢查通過\\nGil：%d\\n背包記錄：%d\\n遊戲 build：24250053\\n未修改遊戲資料。',s.gil,s.count))
'''
money='''
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
'''
inventory='''
local s=connect()
assert(s.count<=5000,'Inventory too large for this viewer')
local lines={'唯讀背包資料（內部 ID，不代表道具名稱）',''}
for i=0,s.count-1 do
 local id=readInteger(s.inventory+i*8)
 local amount=readInteger(s.inventory+i*8+4)
 assert(id and amount and amount>=0,'Inventory changed while reading; retry on the map')
 lines[#lines+1]=string.format('ID %d：%d',id,amount)
end
showMessage(table.concat(lines,'\\n'))
'''
root=E.Element('CheatTable',CheatEngineTableVersion='45');entries=E.SubElement(root,'CheatEntries')
for i,(label,body) in enumerate([('01 唯讀檢查：目前 Gil 與背包筆數',readonly),('02 設定持有 Gil（輸入目標；寫入讀回已驗證）',money),('03 唯讀背包清單：內部 ID 與數量',inventory)],1):
 e=E.SubElement(entries,'CheatEntry');E.SubElement(e,'ID').text=str(i);E.SubElement(e,'Description').text='"'+label+'"';E.SubElement(e,'VariableType').text='Auto Assembler Script';E.SubElement(e,'AssemblerScript').text='[ENABLE]\n{$lua}\nif syntaxcheck then return end\n'+common+body+'\n{$asm}\n[DISABLE]\n'
E.SubElement(root,'UserdefinedSymbols');E.indent(root)
p=(ROOT/'FFRS_Steam_24250053_Starter.CT');E.ElementTree(root).write(p,encoding='utf-8',xml_declaration=True)
