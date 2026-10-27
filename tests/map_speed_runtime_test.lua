local root=(...) or '.'
local f=assert(io.open(root..'/src/map_speed_runtime.lua'));local source=f:read('*a');f:close()
local env=setmetatable({}, {__index=_G});env._G=env
local timer,pid,selected,paused= nil,1,'foot',false
local offsets={0x86C,0x870,0x874};local mem={}
local actors={foot={pawn=10000,identity='foot',base={180,450,230},multiplier=1},mount={pawn=20000,identity='mount',base={350,500,400},multiplier=1}}
for _,a in pairs(actors)do for i,o in ipairs(offsets)do mem[a.pawn+o]=a.base[i]end end
local b={live=function(p)for _,a in pairs(actors)do if a.pawn==p then return a.identity end end end,clear=function()end}
env.createTimer=function()timer={destroy=function()end};return timer end
env.getOpenedProcessID=function()return pid end
env.readFloat=function(p)return mem[p]end;env.writeFloat=function(p,v)mem[p]=v;return true end
env.mapMovementSpeed=function()
 assert(not paused,'Not controllable')
 local a=actors[selected]
 local reset=true;for i,o in ipairs(offsets)do if mem[a.pawn+o]~=a.base[i]then reset=false end end
 if reset then a.multiplier=1 end
 return {pawn=a.pawn,identity=a.identity,mounted=selected=='mount',record=a,multiplier=a.multiplier,apply=function(m)
  for i,o in ipairs(offsets)do mem[a.pawn+o]=a.base[i]*m end;a.multiplier=m
  return a.base[1]*m,a.base[2]*m,a.base[3]*m
 end}
end
local start=assert(load(source..'\nreturn startMapSpeedRuntime','runtime','t',env))()
local run=start({pid=1},b)
timer.OnTimer();assert(mem[10000+0x874]==690)
selected='mount';timer.OnTimer();assert(mem[10000+0x874]==230 and mem[20000+0x870]==1750)
selected='foot';timer.OnTimer();assert(mem[10000+0x874]==690 and mem[20000+0x870]==500)
timer.OnTimer();assert(mem[10000+0x874]==690,'No compounding')
paused=true;timer.OnTimer();assert(mem[10000+0x874]==230)
paused=false;timer.OnTimer();assert(mem[10000+0x874]==690)
run.stop();assert(not run.running and mem[10000+0x874]==230)
return 'PASS: mount/dismount, original restoration, no compounding, pause/resume, disable'
