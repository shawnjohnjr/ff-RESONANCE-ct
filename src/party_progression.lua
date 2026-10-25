local function arrayAt(a,max)
 local p=readPointer(a);local n=readInteger(a+8);local cap=readInteger(a+12)
 assert(n and cap and n>=0 and n<=cap and cap<=max,'Invalid array')
 assert(n==0 or (p and p>65536),'Invalid array pointer')
 return p,n
end
local function partyPlan(s)
 local party,n=arrayAt(s.save+0x90,8);assert(n>0,'No party members')
 local units,un=arrayAt(s.save+0x60,64)
 local byId={}
 for i=0,un-1 do local a=units+i*0xA0;local id=readInteger(a);assert(id and not byId[id],'Invalid unit ID');byId[id]=a end
 local definitions={}
 for _,r in ipairs(tableRows(s,findTable(s,'UNIT_PARAMETER'),'UNIT_PARAMETER')) do definitions[readInteger(r.p+8)]={curve=readInteger(r.p+0x3C),name=r.key} end
 local curves={}
 for _,r in ipairs(tableRows(s,findTable(s,'UNIT_LEVEL_PARAMETER_LIST'),'UNIT_LEVEL_PARAMETER_LIST')) do curves[readInteger(r.p+8)]=readPointer(r.p+0x10) end
 local out,seen={},{}
 for i=0,n-1 do
  local id=readInteger(party+i*4)
  assert(id and id>=1001 and id<=1008 and not seen[id],'Unexpected party member');seen[id]=true
  local a=assert(byId[id],'Party member missing from save');local def=assert(definitions[id],'Missing unit definition')
  local levels={}
  for _,r in ipairs(tableRows(s,assert(curves[def.curve],'Missing curve'),'UNIT_LEVEL_PARAMETER')) do
   local lv=readInteger(r.p+8);local xp=readInteger(r.p+12)
   if lv and lv>=1 and lv<=99 then assert(not levels[lv] and xp and xp>=0,'Invalid level curve');levels[lv]=xp end
  end
  local sum=0;for lv=1,99 do sum=sum+assert(levels[lv],'Incomplete level curve') end
  assert(sum>0 and sum<=2147483647,'Invalid level-99 EXP')
  local old=readInteger(a+4);assert(old and old>=0,'Invalid current EXP')
  out[#out+1]={id=id,address=a,experience=old,target=sum,name=def.name,partyIndex=i}
 end
 return out,party,n,units
end
