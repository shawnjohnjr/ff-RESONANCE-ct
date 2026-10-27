local s=connect()
local choices=inventoryChoices(s)
local keyCount=0
for i=0,s.count-1 do
 if readInteger(s.inventory+i*8)==29500 then keyCount=readInteger(s.inventory+i*8+4) end
end
choices[#choices+1]={id=29500,name='Magitek Armor Key / 魔導裝甲之鑰',quantity=keyCount,special=true}
local list=createStringlist()
for _,item in ipairs(choices) do list.add(string.format('%s | ID %d | 持有 %d',item.name,item.id,item.quantity)) end
local ok,index=pcall(showSelectionList,'道具修改／取得鑰匙','一般道具限已持有；魔導裝甲之鑰可補足 1 把，其他重要道具不列入。',list,false)
list.destroy()
if not ok then error(index) end
if index==nil or index<0 then return end
local item=assert(choices[index+1],'Invalid item selection')
if item.special then grantMagitekKey();return end
local answer=inputQuery('設定道具數量',item.name..'（ID '..item.id..'），目前 '..item.quantity..'。輸入 1–99：',tostring(item.quantity))
if not answer then return end
local target=tonumber(answer)
setItem(s,item,target)
showMessage(item.name..'：'..item.quantity..' → '..target..'。請重開道具選單核對。')
