-- Own Lua implementation. No executable patch, allocation, native call or ASM hook.
-- Build 24250053: getter 0x52383FA reads current break at parameter+0x114.
local legacy=_G.FFRS_ONE_HIT_STAGGER
if legacy then legacy.stop() end -- Restore a previously enabled legacy hook first.
local prior=_G.FFRS_LUA_BREAK
if prior and prior.running then return end
local s=connect(true)
checkCode(s.base+0x52383FA,{0x8B,0x8E,0x14,0x01,0,0})
checkCode(s.base+0x523230A,{0x41,0x2B,0xC4,0x41,0x0F,0x28,0xC5})
local b=battleObjects(s)
local rosterFor=breakEnemyRoster(s,b)
local run={running=true,status='Waiting for command selection',writes=0,history={}}
_G.FFRS_LUA_BREAK=run
local timer=createTimer(nil,false);timer.Interval=250
function run.stop()
 if not run.running then return end
 run.running=false;timer.Enabled=false;timer.destroy();b.clear()
 -- Do not restore old gauges after attacks: natural battle progression owns them.
end
local function guardsMatch(guards)
 for _,g in ipairs(guards) do
  local value
  if g[3]==1 then value=readBytes(g[1],1)
  elseif g[3]==4 then value=readInteger(g[1])
  else value=readPointer(g[1]) end
  if value~=g[2] then return false end
 end
 return true
end
local function tick()
 assert(getOpenedProcessID()==s.pid,'Attached process changed')
 if isPaused() then return end
 b.scan(256,{attack=true})
 local ctx=b.context()
 if not ctx or ctx.state~=0 or ctx.commandType==2 then run.status='Waiting for command selection';return end
 local roster=rosterFor(ctx);if not roster then return end
 -- Pause only for a short guarded data transaction; no target code is injected.
 pause()
 local ok,err=pcall(function()
  if not guardsMatch(ctx.guards) or not guardsMatch(roster.guards) then return end
  for _,u in ipairs(roster.members) do
   if tostring(b.live(u.actor))..'/'..tostring(b.live(u.param))~=u.identity then return end
   if readPointer(u.slot)~=u.actor or readPointer(u.actor+0x838)~=u.param or
      readPointer(u.actor+32)~=u.level or readPointer(u.level+0xC0)~=ctx.world or
      readInteger(u.actor+0x880)~=u.uniqueId or readInteger(u.param+0xD0)~=u.id then return end
   local hp=readInteger(u.param+0x10C)
   local gauge=readInteger(u.param+0x114)
   assert(hp and gauge and gauge>=0 and gauge<=10000000,'Invalid enemy resource data')
   if readBytes(u.param+0x3D8,1)==2 and hp>0 and gauge>1 then
    assert(writeInteger(u.param+0x114,1),'Break write failed')
    assert(readInteger(u.param+0x114)==1,'Break readback failed')
    run.writes=run.writes+1
    run.history[#run.history+1]={unit=u.id,before=gauge,after=1}
    if #run.history>32 then table.remove(run.history,1) end
   end
  end
 end)
 unpause()
 assert(ok,err)
 run.status='Enemy break prepared; writes='..run.writes
end
timer.OnTimer=function()
 local ok,err=pcall(tick)
 if not ok then run.error=tostring(err);run.stop();run.status='Stopped: '..run.error;showMessage(run.status) end
end
timer.Enabled=true
