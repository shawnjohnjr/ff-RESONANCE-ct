-- One dispatcher shared by independently selectable attack/results features.
local function startBattleAutomation(mode)
 assert(mode=='attack' or mode=='results','Unknown automation mode')
 local legacy=_G.FFRS_AUTO_ATTACK
 if legacy and legacy.running then legacy.stop() end
 local old=_G.FFRS_BATTLE_AUTOMATION
 if old and old.running then
  old.modes[mode]=true
  return old
 end
 local s=connect(true)
 local objects=battleObjects(s)
 local thread=createGameThread(s)
 local calls=battleCalls(s,objects,thread)
 local runtime={running=true,pid=s.pid,modes={[mode]=true},objects=objects,thread=thread}
 runtime.actions=battleActions(s,objects,thread,calls)
 runtime.results=resultActions(s,objects,calls)
 _G.FFRS_BATTLE_AUTOMATION=runtime
 local timer=createTimer(nil,false);runtime.timer=timer;timer.Interval=150
 function runtime.stop()
  if not runtime.running then return end
  runtime.running=false;runtime.modes={}
  timer.Enabled=false;timer.destroy()
  pcall(thread.stop)
  objects.clear()
  runtime.actions.pending=nil;runtime.actions.status='Stopped'
  runtime.results.status='Stopped'
 end
 function runtime.disable(which)
  runtime.modes[which]=nil
  if which=='attack' then runtime.actions.pending=nil;runtime.actions.status='Stopped' end
  if which=='results' then runtime.results.status='Stopped' end
  if not next(runtime.modes) then runtime.stop() end
 end
 timer.OnTimer=function()
  if not runtime.running then return end
  local ok,err=pcall(function()
   if getOpenedProcessID()~=s.pid or readSmallInteger(s.base)~=0x5A4D then runtime.stop();return end
   objects.scan(256,runtime.modes)
   for _,which in ipairs({'attack','results'}) do
    if runtime.modes[which] then
     local ready,missing=objects.ready(which)
     local action=which=='attack' and runtime.actions or runtime.results
     if ready then action.step() else action.status='Preparing: '..missing end
    end
   end
  end)
  if not ok then
   runtime.stop();runtime.error=tostring(err)
   print('FFRS Battle Automation stopped: '..runtime.error)
  end
 end
 timer.Enabled=true
 return runtime
end
