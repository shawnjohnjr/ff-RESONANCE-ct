-- Owned visions only. Synchro belongs to each playable unit independently.
local function visionArray(a,max)
 local p,n,cap=readPointer(a),readInteger(a+8),readInteger(a+12)
 assert(n and cap and n>=0 and n<=cap and cap<=max,'Invalid vision/party array')
 assert(n==0 or p and p>65536,'Invalid vision/party pointer')
 return p,n
end
local function visionSnapshot(s)
 local p,n=visionArray(s.save+0x118,256)
 local party,pn=visionArray(s.save+0x90,8)
 local out={pointer=p,count=n,party=party,partyCount=pn,units={},visions={}}
 local seen={}
 for i=0,pn-1 do
  local id=readInteger(party+i*4)
  assert(id and id>=1001 and id<=1008 and not seen[id],'Unexpected party member')
  seen[id]=true;out.units[#out.units+1]=id
 end
 seen={}
 for i=0,n-1 do
  local a=p+i*0x58;local id=readInteger(a);local point=readInteger(a+4)
  assert(id and id>0 and not seen[id] and point and point>=0,'Invalid owned vision')
  seen[id]=true
  local v={id=id,address=a,awakening=point,synchro={}}
  local m=a+8;local data,count=visionArray(m,64)
  local bits=readPointer(m+0x20);local bitCount=readInteger(m+0x28)
  assert(bitCount and bitCount>=count and bitCount<=64,'Invalid synchro allocation bits')
  if not bits or bits==0 then bits=m+0x10 end
  for j=0,count-1 do
   local flags=assert(readInteger(bits+math.floor(j/32)*4),'Unreadable synchro map')
   if (flags & (1<<(j%32)))~=0 then
    local slot=data+j*16;local unit=readInteger(slot);local value=readInteger(slot+4)
    assert(unit and unit>=1001 and unit<=1008 and not v.synchro[unit] and value and value>=0,'Invalid synchro entry')
    v.synchro[unit]={point=value,address=slot+4}
   end
  end
  out.visions[#out.visions+1]=v
 end
 return out
end
local function visionPlan(snapshot,selected,mode,limits)
 assert(mode=='awakening' or mode=='synchro' or mode=='both','Unknown vision upgrade mode')
 if mode~='awakening' then assert(#snapshot.units>0,'No current party') end
 local plan={};local found=false
 for _,v in ipairs(snapshot.visions) do
  if selected==0 or selected==v.id then
   found=true
   for kind=0,1 do
    if kind==0 and mode~='synchro' or kind==1 and mode~='awakening' then
     local maximum,level=limits(v.id,kind)
     assert(maximum and maximum>0 and maximum<=10000000 and level and level>0 and level<=100,'Invalid vision growth limit')
     local function add(unit,point,address)
      assert(point<=maximum,'Current growth exceeds supported maximum; stop')
      if point<maximum then plan[#plan+1]={id=v.id,vision=v,kind=kind,unit=unit,before=point,target=maximum,level=level,address=address} end
     end
     if kind==0 then add(nil,v.awakening,v.address+4)
     else for _,unit in ipairs(snapshot.units) do
      local value=assert(v.synchro[unit],'Current party member missing from vision; stop')
      add(unit,value.point,value.address)
     end end
    end
   end
  end
 end
 assert(found,'Selected vision is not owned')
 return plan
end
