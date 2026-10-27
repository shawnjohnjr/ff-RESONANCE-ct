-- One native increment plus an unchanged-EXP refresh; never freezes the values.
local function startBaseStatEdit(s,snapshot,op,onComplete)
 assert(not (_G.FFRS_BASE_STAT_ACTION and _G.FFRS_BASE_STAT_ACTION.running),'Another stat edit is pending')
 local al=getAddressList();for i=0,al.Count-1 do if al[i].ID==7 or al[i].ID==8 then assert(not al[i].Active,'Turn off 07 and 08')end end
 checkCode(s.base+0x5106CD0,{0x40,0x56,0x57,0x41,0x57,0x48,0x83,0xEC,0x20,0x45,0x8B,0xF8,0x0F,0xB6,0xF2,0x8B,0xF9})
 checkCode(s.base+0x524B3A0,{0x48,0x89,0x5C,0x24,0x18,0x48,0x89,0x74,0x24,0x20,0x57,0x48,0x81,0xEC,0xD0,1,0,0})
 checkCode(s.base+0x5249B90,{0x48,0x83,0xEC,0x38,0x48,0x89,0x5C,0x24,0x48,0x48,0x89,0x6C,0x24,0x50})
 checkCode(s.base+0x523D360,{0x40,0x53,0x48,0x83,0xEC,0x20,0x8B,0xD9,0xE8,0x13,0x10,0xE2,0xFF})
 checkCode(s.base+0x5234A90,{0x48,0x89,0x5C,0x24,8,0x48,0x89,0x6C,0x24,0x10,0x48,0x89,0x74,0x24,0x18})
 checkCode(s.base+0x5236670,{0x48,0x89,0x74,0x24,0x10,0x57,0x48,0x81,0xEC,0xC0,0,0,0})
 local b=battleObjects(s);battleDirectLinks(s,b).refresh()
 local world=readPointer(s.base+0x9AA0540);local ui
 for o in pairs(b.interfaces)do if readPointer(o+32)==world then assert(not ui,'Multiple battle interfaces');ui=o end end
 assert(ui and readBytes(ui+0x80,1)==0,'Edit only outside battle')
 local thread=createGameThread(s);local timer=createTimer(nil,false);timer.Interval=250
 local r={running=true,status='Waiting for game foreground',applied=false};_G.FFRS_BASE_STAT_ACTION=r
 local started=getTickCount()
 local function stop()if not r.running then return end;r.running=false;timer.Enabled=false;timer.destroy();pcall(thread.stop);b.clear()end
 r.stop=stop
 local function guards(applied)
  assert(getOpenedProcessID()==s.pid and readPointer(s.base+0x9AA0540)==world and readPointer(s.manager+0x60)==s.save,'Game/save changed')
  assert(readBytes(ui+0x80,1)==0,'Battle started')
  verifyBaseStatSnapshot(snapshot,baseStatSnapshot(s),op,applied)
  local g={};for _,o in ipairs({world,s.manager,s.save,ui})do assert(b.live(o,false,g),'Object expired')end
  for _,v in ipairs({{s.base+0x9AA0540,world},{s.manager+0x60,s.save},{ui+0x80,0,1},
   {s.save+0x60,snapshot.pointer},{s.save+0x68,snapshot.count,4},{op.unit.address,op.unit.id,4},
   {op.unit.address+4,op.unit.xp,4},{op.unit.address+0x80,0,1},{op.unit.address+0x10,op.unit.pointer},
   {op.unit.address+0x18,20,4},{op.unit.pointer+op.stat.id*4,applied and op.target or op.before,4}})do g[#g+1]=v end
  return g
 end
 timer.OnTimer=function()
  local ok,err=pcall(function()
   assert(getTickCount()-started<120000,'Stat edit timed out')
   assert(getOpenedProcessID()==s.pid,'Process changed')
   if executeCodeEx(0,3000,getAddressSafe('user32.GetForegroundWindow'))~=thread.hwnd then return end
   if op.delta~=0 then
    assert(thread.call(s.base+0x5106CD0,op.unit.id,op.stat.id,guards(false),op.delta),'Stat call rejected')
    r.applied=true
    -- Keep recovery information even if the subsequent refresh fails.
    _G.FFRS_BASE_STAT_UNDO={pid=s.pid,save=s.save,unit=op.unit.id,stat=op.stat.id,before=op.before,after=op.target}
   end
   assert(thread.call(s.base+0x524B3A0,op.unit.id,op.unit.xp,guards(true),0),'Refresh failed; bonus may already be changed')
   -- The EXP refresh re-adds persistent effects. Normalize them through the
   -- same remove/rebuild routine used by the game's equipment-change path.
   local param=executeCodeEx(0,3000,s.base+0x523D360,op.unit.id)
   local g=guards(true);assert(param and b.live(param,false,g),'Live character unavailable')
   assert(readInteger(param+0xD0)==op.unit.id,'Live character ID mismatch')
   g[#g+1]={param+0xD0,op.unit.id,4}
   assert(thread.call(s.base+0x5249B90,param,0,g,0),'Effect normalization failed')
   assert(thread.call(s.base+0x5234A90,param,0,g,0),'HP/MP clamp failed')
   assert(thread.call(s.base+0x5236670,op.unit.id,0,g,0),'Menu refresh failed')
   verifyBaseStatSnapshot(snapshot,baseStatSnapshot(s),op,true)
   r.status='Complete';stop();if onComplete then onComplete(r)end
  end)
  if not ok then r.error=tostring(err);r.status='Error';stop();showMessage(r.error..'\nBonus applied: '..tostring(r.applied))end
 end
 timer.Enabled=true;return r
end
