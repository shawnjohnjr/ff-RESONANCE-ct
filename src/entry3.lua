local s=connect()
assert(s.count<=5000,'Inventory too large for this viewer')
local lines={'唯讀背包資料（內部 ID，不代表道具名稱）',''}
for i=0,s.count-1 do
 local id=readInteger(s.inventory+i*8)
 local amount=readInteger(s.inventory+i*8+4)
 assert(id and amount and amount>=0,'Inventory changed while reading; retry on the map')
 lines[#lines+1]=string.format('ID %d：%d',id,amount)
end
showMessage(table.concat(lines,'\n'))
