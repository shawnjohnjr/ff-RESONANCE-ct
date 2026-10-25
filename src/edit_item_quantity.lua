local s=connect()
local choices=inventoryChoices(s)
assert(#choices>0,'No supported owned items found')
local list=createStringlist()
for _,item in ipairs(choices) do list.add(string.format('%s | ID %d | 持有 %d',item.name,item.id,item.quantity)) end
local ok,index=pcall(showSelectionList,'修改已持有道具','選擇道具（English / 繁體中文）；重要道具與未持有道具不在此清單。',list,false)
list.destroy()
if not ok then error(index) end
if index==nil or index<0 then return end
local item=assert(choices[index+1],'Invalid item selection')
local answer=inputQuery('設定道具數量',item.name..'（ID '..item.id..'），目前 '..item.quantity..'。輸入 1–99：',tostring(item.quantity))
if not answer then return end
local target=tonumber(answer)
setItem(s,item,target)
showMessage(item.name..'：'..item.quantity..' → '..target..'。請重開道具選單核對。')
