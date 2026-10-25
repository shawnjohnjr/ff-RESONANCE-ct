-- Execute native vision setters on the game thread, using the existing dispatcher.
local function startVisionUpgrade(s,snapshot,selected,mode)
 local previous=_G.FFRS_VISION_UPGRADE
 assert(not previous or not previous.running,'A vision upgrade is already running')
 local battle=_G.FFRS_BATTLE_AUTOMATION
 assert(not battle or not battle.running,'Turn off entries 07 and 08 before upgrading visions')
 local b=battleObjects(s)
 local class
 local count=assert(readInteger(s.base+0x9D84DD0+0x14))
 for i=0,count-1 do
  local o=s.at(i)
  if o and o>65536 and s.oname(o)=='CPP_BFL_Vision' and s.cname(o)=='Class' and b.live(o,true) then class=o;break end
 end
 assert(class,'Vision function class not found')
 local sizes={GetMaxMasteryPoint=12,GetMaxLevel=12,GetAwakeningMasteryLevel=8,GetSynchroMasteryLevel=12,
  SetAwakeningMasteryPoint=9,SetSynchroMasteryPoint=13}
 local f=readPointer(class+0x48);local visited={}
 for _=1,512 do
  if not b.live(f) or visited[f] then break end
  visited[f]=true;local name=s.oname(f)
  if sizes[name] then
   assert(readPointer(f+32)==class and s.cname(f)=='Function','Wrong vision function owner/type')
   assert(readSmallInteger(f+0xB6)==sizes[name],'Vision function parameter mismatch')
   local flags=assert(readInteger(f+0xB0));assert((flags & 0x2400)==0x2400,'Vision function flags mismatch')
   b.functions[name]={object=f,owner=class,static=true,native=true,paramSize=sizes[name],identity=b.live(f),defaults=readPointer(class+0x110)}
  end
  f=readPointer(f+0x28)
 end
 for name in pairs(sizes)do assert(b.functions[name],'Missing vision function: '..name)end
 local world=readPointer(s.base+0x9AA0540)
 local links=battleDirectLinks(s,b);links.refresh()
 local ui
 for o in pairs(b.interfaces)do if readPointer(o+32)==world then assert(not ui,'Multiple battle interfaces');ui=o end end
 assert(ui and readBytes(ui+0x80,1)==0,'Upgrade only outside battle')
 local thread=createGameThread(s);local calls=battleCalls(s,b,thread)
 local r={running=true,completed=0,status='Waiting for game foreground'}
 _G.FFRS_VISION_UPGRADE=r
 local timer=createTimer(nil,false);timer.Interval=250;r.timer=timer
 local started=getTickCount();local plan,index=nil,1
 local function stop()
  if not r.running then return end
  r.running=false;timer.Enabled=false;timer.destroy();pcall(thread.stop);b.clear()
 end
 r.stop=function()r.status='Stopped; completed upgrades remain';stop()end
 local function context(op)
  assert(getOpenedProcessID()==s.pid and readPointer(s.base+0x9AA0540)==world,'Game/world changed; stop')
  local guards={}
  for _,o in ipairs({world,s.manager,s.save,ui})do assert(b.live(o,false,guards),'Object expired; stop')end
  assert(readPointer(s.manager+0x60)==s.save and readPointer(ui+32)==world and readBytes(ui+0x80,1)==0,'Save or battle changed; stop')
  guards[#guards+1]={s.base+0x9AA0540,world};guards[#guards+1]={s.manager+0x60,s.save}
  guards[#guards+1]={ui+32,world};guards[#guards+1]={ui+0x80,0,1}
  local current=visionSnapshot(s)
  assert(current.pointer==snapshot.pointer and current.count==snapshot.count and current.party==snapshot.party and current.partyCount==snapshot.partyCount,'Vision list/party changed; stop')
  guards[#guards+1]={s.save+0x118,snapshot.pointer};guards[#guards+1]={s.save+0x120,snapshot.count,4}
  guards[#guards+1]={s.save+0x90,snapshot.party};guards[#guards+1]={s.save+0x98,snapshot.partyCount,4}
  for i,id in ipairs(snapshot.units)do assert(current.units[i]==id,'Party changed; stop');guards[#guards+1]={snapshot.party+(i-1)*4,id,4}end
  for i,v in ipairs(snapshot.visions)do assert(current.visions[i].id==v.id,'Owned visions changed; stop')end
  if op then
   local found
   for _,v in ipairs(current.visions)do if v.id==op.id then found=v end end
   assert(found and found.address==op.vision.address,'Vision moved; stop')
   local value=op.kind==0 and found.awakening or found.synchro[op.unit] and found.synchro[op.unit].point
   local address=op.kind==0 and found.address+4 or found.synchro[op.unit] and found.synchro[op.unit].address
   assert(value==op.before and address==op.address,'Growth changed; retry from the menu')
   guards[#guards+1]={found.address,op.id,4};guards[#guards+1]={address,op.before,4}
   if op.kind==1 then
    guards[#guards+1]={address-4,op.unit,4}
    local map=found.address+8;guards[#guards+1]={map,readPointer(map)};guards[#guards+1]={map+8,readInteger(map+8),4}
   end
  end
  return {world=world,guards=guards}
 end
 local function invoke(name,ctx,fill)
  local fn=b.functions[name];assert(fn and b.live(fn.object)==fn.identity,'Vision function expired')
  assert(calls.invoke(name,nil,ctx,fill),'Game focus or state changed; stop and inspect completed upgrades')
 end
 timer.OnTimer=function()
  local ok,err=pcall(function()
   assert(getTickCount()-started<120000,'Vision upgrade timed out')
   assert(getOpenedProcessID()==s.pid,'CE changed process')
   if executeCodeEx(0,3000,assert(getAddressSafe('user32.GetForegroundWindow')))~=thread.hwnd then r.status='Waiting for game foreground';return end
   if not plan then
    local ctx=context()
    plan=visionPlan(snapshot,selected,mode,function(id,kind)
     local values={}
     for _,name in ipairs({'GetMaxMasteryPoint','GetMaxLevel'})do
      invoke(name,ctx,function(a)writeInteger(a,id);writeBytes(a+4,kind)end)
      values[#values+1]=readInteger(calls.buffer+8)
     end
     return values[1],values[2]
    end)
    r.total=#plan;r.status='Plan validated';return
   end
   local op=plan[index]
   if not op then
    r.status='Completed';stop()
    showMessage('幻兵強化完成 / Vision upgrade complete: '..r.completed..'\n請重新開啟幻兵選單核對。已完成的強化不會因取消勾選而還原。')
    return
   end
   local ctx=context(op)
   local setter=op.kind==0 and 'SetAwakeningMasteryPoint' or 'SetSynchroMasteryPoint'
   invoke(setter,ctx,function(a)
    writeInteger(a,op.id)
    if op.kind==0 then writeInteger(a+4,op.target)else writeInteger(a+4,op.unit);writeInteger(a+8,op.target)end
   end)
   assert(readBytes(calls.buffer+(op.kind==0 and 8 or 12),1)==1,'Game rejected vision upgrade')
   r.completed=r.completed+1
   assert(readInteger(op.address)==op.target,'Growth readback mismatch; inspect game')
   -- Fresh guards after the setter, since the expected point value changed.
   local verify=context()
   invoke(op.kind==0 and 'GetAwakeningMasteryLevel' or 'GetSynchroMasteryLevel',verify,function(a)
    writeInteger(a,op.id);if op.kind==1 then writeInteger(a+4,op.unit)end
   end)
   assert(readInteger(calls.buffer+(op.kind==0 and 4 or 8))==op.level,'Growth level verification failed')
   r.status=visionName(op.id)..' verified';index=index+1
  end)
  if not ok then r.error=tostring(err);r.status='Stopped with error';stop();showMessage(r.error..'\nCompleted: '..r.completed..'; completed changes are not rolled back.') end
 end
 timer.Enabled=true
 return r
end
