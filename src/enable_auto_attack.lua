-- A checkbox controls this session only; no save data or game files are changed.
if _G.FFRS_AUTO_ATTACK and _G.FFRS_AUTO_ATTACK.running then return end
local s=connect()
local objects=battleObjects(s)
local thread=createGameThread(s)
local actions=battleActions(s,objects,thread)
local runtime={running=true,pid=s.pid,actions=actions,objects=objects,thread=thread}
_G.FFRS_AUTO_ATTACK=runtime
local timer=createTimer(nil,false);runtime.timer=timer;timer.Interval=150
function runtime.stop()
 if not runtime.running then return end
 runtime.running=false
 timer.Enabled=false;timer.destroy()
 pcall(thread.stop)
 actions.pending=nil;actions.status='Stopped'
end
timer.OnTimer=function()
 if not runtime.running then return end
 local ok,err=pcall(function()
  if getOpenedProcessID()~=s.pid or readSmallInteger(s.base)~=0x5A4D then
   runtime.stop();return
  end
  objects.scan(256)
  local ready,missing=objects.ready()
  if not ready then actions.status='Preparing: '..missing;return end
  actions.step()
 end)
 if not ok then
  runtime.stop();runtime.error=tostring(err)
  print('FFRS Auto Attack stopped: '..runtime.error)
 end
end
timer.Enabled=true
