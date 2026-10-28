-- IMPORTANT: immediate +0x118 readback is not a persistence check.
-- The game restores resource snapshots while advancing battle commands.
-- See docs/party-limit-investigation.md for the confirmed restore call chain,
-- failed approaches, and required turn-transition/consumption regression tests.
-- CrossOver verified: turn changes retain fill, spending consumes it, next battle re-arms.
local function startPartyLimitRefill(s)
 local old=_G.FFRS_PARTY_LIMIT
 if old and old.running then return old end
 local fillWithSnapshot=createPartyLimitWriter(s)
 local b=battleObjects(s);local thread=createGameThread(s);local calls=battleCalls(s,b,thread)
 local rosterFor=partyLimitRoster(s,b);local cycle=partyLimitState()
 local run={running=true,status='Waiting for battle',cycle=cycle,history={},pid=s.pid}
 _G.FFRS_PARTY_LIMIT=run
 local timer=createTimer(nil,false);timer.Interval=250
 function run.stop()
  if not run.running then return end
  run.running=false;timer.Enabled=false;timer.destroy();pcall(thread.stop);b.clear();cycle.reset()
 end
 local function tick()
  assert(getOpenedProcessID()==s.pid and readSmallInteger(s.base)==0x5A4D,'Game process ended or changed')
  b.scan(256,{attack=true})
  local world=readPointer(s.base+0x9AA0540)
  for ui,identity in pairs(b.interfaces)do
   if b.live(ui)==identity and readPointer(ui+32)==world and readBytes(ui+0x80,1)==0 then
    cycle.reset();run.status='Waiting for next battle';return
   end
  end
  if not b.ready('attack') then run.status='Discovering battle functions';return end
  local ctx=b.context()
  if not ctx or ctx.state~=0 or ctx.commandType==2 then run.status='Waiting for friendly commands';return end
  if executeCodeEx(0,3000,getAddressSafe('user32.GetForegroundWindow'))~=thread.hwnd then run.status='Waiting for game foreground';return end
  -- Give other one-shot refills priority; no popup or forced checkbox changes.
  if _G.FFRS_LIMIT_REFILL and _G.FFRS_LIMIT_REFILL.running then return end
  if not calls.safeScene(ctx) then return end
  local roster=rosterFor(ctx);if not roster then return end
  cycle.enter(roster.key)
  for _,u in ipairs(roster.members)do
   if cycle.pending(u.identity) and (readInteger(u.param+0x10C) or 0)>0 then
    if not calls.invoke('GetRelation',u.param,ctx) then return end
    assert(readBytes(calls.buffer,1)==1,'Party relation mismatch')
    local maximum,current=readInteger(u.param+0x2A0),readInteger(u.param+0x118)
    assert(maximum and maximum>0 and maximum<=10000 and current and current>=0 and current<=maximum,'Invalid Limit gauge/cap')
    local snapshot=partyLimitSnapshot(b,roster,u)
    if not snapshot then run.status='Waiting for stable command snapshot';return end
    assert(snapshot.value<=maximum,'Snapshot Limit exceeds cap')
    local g={};for _,v in ipairs(ctx.guards)do g[#g+1]=v end
    for _,v in ipairs(roster.guards)do g[#g+1]=v end
    for _,v in ipairs(snapshot.guards)do g[#g+1]=v end
    assert(b.live(u.actor,false,g) and b.live(u.param,false,g),'Battle member expired')
    for _,v in ipairs({{u.slot,u.actor},{u.actor+32,u.level},{u.level+0xC0,ctx.world},
     {u.actor+0x880,u.uniqueId,4},{u.actor+0x838,u.param},{u.param+0xD0,u.id,4},{u.param+0x2A0,maximum,4},{u.param+0x118,current,4}})do g[#g+1]=v end
    if (current<maximum or snapshot.value<maximum) and not fillWithSnapshot(thread,snapshot,u,maximum,g) then run.status='Scene changed; retrying';return end
    assert(b.live(u.param) and readInteger(u.param+0x118)==maximum and readInteger(snapshot.address)==maximum,'Limit/snapshot readback failed')
    cycle.mark(u.identity)
    run.history[#run.history+1]={unit=u.id,before=current,snapshotBefore=snapshot.value,after=maximum,battle=cycle.battles}
    if #run.history>32 then table.remove(run.history,1)end
    run.status='Filled '..u.id..': '..current..' -> '..maximum
    return -- Bound work to one character per tick.
   end
  end
  run.status='Party filled; waiting for next battle'
 end
 timer.OnTimer=function()
  if not run.running then return end
  local ok,err=pcall(tick)
  if not ok then run.error=tostring(err);run.status='Stopped: '..run.error;run.stop()end
 end
 timer.Enabled=true;return run
end
