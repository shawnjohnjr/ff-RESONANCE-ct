-- Run with Lua 5.3+ from the repository root; no game or Cheat Engine required.
local file=assert(io.open('src/result_actions.lua','r'))
local source=file:read('*a');file:close()
local function fixture()
 local now,event=1000,nil
 local log={};local paused=false;local liveLayout=true;local reject=false;local retireOnPress=false
 local env=setmetatable({
  getTickCount=function() return now end,
  writeBytes=function(_,value) event=value end,
 },{__index=_G})
 local factory=assert(load(source..'\nreturn resultActions','result_actions','t',env))()
 local calls={buffer=100,safeScene=function() return not paused end}
 calls.invoke=function(name,target,_,fill)
  assert(name=='InputDecide' and target==2,'Input must address the result widget only')
  if reject then return false end
  fill(100);log[#log+1]=event
  if event==1 and retireOnPress then liveLayout=false end
  return true
 end
 local objects={live=function(o) if o==1 then return 'world' end;if o==2 and liveLayout then return 'layout' end end}
 local a=factory({base=0},objects,calls)
 local ctx={world=1,layout=2,identity='layout',guards={}}
 a.context=function() return ctx end
 return {a=a,log=log,setContext=function(v) ctx=v end,
  pause=function(v) paused=v end,advance=function() now=now+300 end,
  retire=function() retireOnPress=true end,reject=function() reject=true end}
end
local f=fixture();f.setContext(nil);f.a.step();assert(#f.log==0,'No result screen must mean no input')
f=fixture();f.pause(true);f.a.step();assert(#f.log==0,'Paused scene must not confirm')
f=fixture();f.reject();f.a.step();assert(#f.log==0 and f.a.confirms==0,'Rejected call must not count or release')
f=fixture();f.a.step();assert(#f.log==2 and f.log[1]==1 and f.log[2]==2,'Confirm must be paired with release')
assert(f.a.confirms==1 and f.a.releases==1)
f.a.step();assert(#f.log==2,'Confirmation rate must be limited')
f.advance();f.setContext(nil);f.a.step();assert(#f.log==2,'Returning to gameplay must stop confirmations')
f=fixture();f.retire();f.a.step();assert(#f.log==1,'Retired widget must not receive a release')
print('Result action safety tests passed')
