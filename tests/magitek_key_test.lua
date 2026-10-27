local root=(...) or '.'
local source=assert(io.open(root..'/src/grant_magitek_key.lua')):read('*a')
local function test(owned)
 local timer,grants
 grants=0
 local mem={[0x9AA0540]=200000,[300032]=200000,[400168]=500000,[400176]=owned and 1 or 0,[400040]=100,[500000]=29500,[500004]=1,[600096]=400000}
 local env=setmetatable({}, {__index=_G});env._G=env
 env.connect=function()return {base=0,pid=1,save=400000,manager=600000}end
 env.battleObjects=function()return {interfaces={[300000]=true},live=function()return true end,clear=function()end}end
 env.battleDirectLinks=function()return {refresh=function()end}end
 env.readPointer=function(a)return mem[a]end;env.readInteger=env.readPointer
 env.readBytes=function()return 0 end;env.checkCode=function()end
 env.getAddressList=function()return {Count=0}end
 env.createGameThread=function()return {hwnd=9,stop=function()end,call=function(fn,id,qty)
  assert(fn==0x5107500 and id==29500 and qty==1);grants=grants+1;mem[400176]=1;return true
 end}end
 env.createTimer=function()timer={destroy=function()end};return timer end
 env.getTickCount=function()return 0 end;env.getOpenedProcessID=function()return 1 end
 env.executeCodeEx=function()return 9 end;env.getAddressSafe=function()return 1 end
 env.print=function()end;env.showMessage=function()end
 assert(load(source..'\ngrantMagitekKey()','grant','t',env))()
 if owned then assert(not timer and grants==0) else timer.OnTimer();assert(grants==1 and not env.FFRS_MAGITEK_KEY.running);assert(env.FFRS_MAGITEK_KEY.status:match('SUCCESS')) end
end
test(false);test(true)
return 'PASS: missing key grants exactly one; owned key skips'
