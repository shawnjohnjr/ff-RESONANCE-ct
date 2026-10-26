-- Run with Lua 5.3+ or CE: pass the repository path as the first argument.
local root=(...) or '.'
local function test(already,inBattle)
 local calls,timer={},nil
 local mem={[0x9AA0540]=200000,[300032]=200000,[400096]=500000,[400104]=1,[500000]=1006,[500004]=12345,[500080]=600000,[500088]=already and 2 or 1,[600000]=42,[600004]=408160,[700096]=400000}
 local env=setmetatable({}, {__index=_G});env._G=env
 env.connect=function()return {base=0,pid=1,save=400000,manager=700000}end
 env.battleObjects=function()return {interfaces={[300000]=true},live=function()return true end,clear=function()end}end
 env.battleDirectLinks=function()return {refresh=function()end}end
 env.readPointer=function(a)return mem[a]end;env.readInteger=env.readPointer
 env.readBytes=function()return inBattle and 1 or 0 end
 env.checkCode=function()end;env.getAddressList=function()return {Count=0}end
 env.createGameThread=function()return {hwnd=9,stop=function()end,call=function(fn,id,value,guards,r8)
  calls[#calls+1]={fn,id,value,r8}
  if fn==0x5108640 then mem[500088]=2;mem[600004]=408160 end
  return true
 end}end
 env.createTimer=function()timer={destroy=function()end};return timer end
 env.getTickCount=function()return 0 end;env.getOpenedProcessID=function()return 1 end
 env.executeCodeEx=function()return 9 end;env.getAddressSafe=function()return 1 end
 env.showMessage=function()end;env.print=function()end
 local fn=assert(loadfile(root..'/src/unlock_fel_meteor.lua','t',env))
 local ok=pcall(fn)
 if inBattle then assert(not ok and #calls==0);return end
 assert(ok)
 if already then assert(not timer and #calls==0);return end
 timer.OnTimer()
 assert(#calls==2 and calls[1][2]==1006 and calls[1][3]==408160)
 assert(calls[2][3]==12345 and calls[2][4]==0,'Refresh must pass false explicitly')
 assert(mem[600000]==42 and mem[500004]==12345)
 assert(not env.FFRS_FEL_METEOR.running and env.FFRS_FEL_METEOR.status:match('Complete'))
end
test(false,false);test(true,false);test(false,true)
return 'PASS: learning, unchanged EXP, explicit false, already-learned skip, battle rejection'
