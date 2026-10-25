-- Lua 5.3+, run from the repo root. No game memory or input is used.
local f=assert(io.open('src/battle_actions.lua','r'));local source=f:read('*a');f:close()
local factory=assert(load(source..'\nreturn battleActions'))()
local ctx={key='finish',commandType=2,phase=2,state=0,view=123}
local safe,accept=true,true
local invoked={}
local calls={buffer=0,safeScene=function()return safe end,
 invoke=function(name,target)
  if name=='CancelCommand' then assert(target==123);invoked[#invoked+1]=name;return accept end
  assert(name=='GetBattleUnitByUniqueId','Unexpected command: '..name);return false
 end}
local a=factory({}, {context=function()return ctx end}, {}, calls)
ctx=nil;a.step();assert(#invoked==0)
ctx={key='finish',commandType=2,phase=2,state=0,view=123}
safe=false;a.step();assert(#invoked==0,'Background/paused scenes must not cancel')
safe=true;ctx.phase=1;a.step();assert(#invoked==0,'Other battle phases must not cancel')
ctx.phase=2;ctx.state=1;a.step();assert(#invoked==0,'Target selection must not cancel')
ctx.state=0;accept=false;a.step();assert(a.cancels==0,'Rejected call must remain retryable')
accept=true;a.step();assert(a.cancels==1)
a.step();assert(a.cancels==1,'Do not repeatedly cancel the same selection')
ctx.commandType=0;a.step();assert(a.cancels==1,'Normal commands must not cancel')
ctx.commandType=2;a.step();assert(a.cancels==2,'A new selection episode may cancel again')
print('Resonance cancellation safety tests passed')
