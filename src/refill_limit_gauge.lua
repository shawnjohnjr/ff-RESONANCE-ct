-- One-shot refill for the friendly unit currently awaiting a command.
local previous=_G.FFRS_LIMIT_REFILL
if previous and previous.running then error('Limit refill is already waiting') end
local function checkOtherActions()
 local list=getAddressList()
 for i=0,list.Count-1 do
  local row=list[i]
  if row.ID==7 or row.ID==8 then assert(not row.Active,'Turn off entries 07 and 08 first') end
 end
 for _,name in ipairs({'FFRS_BATTLE_AUTOMATION','FFRS_AUTO_ATTACK'}) do
  local action=_G[name];assert(not (action and action.running),'Stop battle automation first')
 end
end
checkOtherActions()
local s=connect(true)
checkCode(s.base+0x4F617D0,{0x48,0x89,0x5C,0x24,0x08,0x57,0x48,0x83,0xEC,0x20,0x8B,0xFA,0x8B,0xD9})
-- Version-checked GetLimitBurstPointMaxGauge returns 200 (two 100-point bars).
checkCode(s.base+0x4D6A1E3,{0x41,0xC7,0x00,0xC8,0,0,0,0xC3})
local objects=battleObjects(s)
local thread=createGameThread(s)
local calls=battleCalls(s,objects,thread)
local run={running=true,status='Preparing battle data',pid=s.pid}
_G.FFRS_LIMIT_REFILL=run
local timer=createTimer(nil,false);timer.Interval=150
local started=getTickCount()
function run.stop()
 if not run.running then return end
 run.running=false;timer.Enabled=false;timer.destroy();pcall(thread.stop);objects.clear()
end
local function refill()
 checkOtherActions()
 assert(getOpenedProcessID()==s.pid,'Game process changed')
 assert(getTickCount()-started<120000,'No eligible command screen within two minutes')
 objects.scan(256,{attack=true})
 if not objects.ready('attack') then return end
 local ctx=objects.context()
 if not ctx or ctx.state~=0 or ctx.commandType==2 then run.status='Waiting for a normal friendly command screen';return end
 if not calls.safeScene(ctx) then run.status='Waiting for foreground / unpaused game';return end
 if not calls.invoke('GetBattleUnitByUniqueId',nil,ctx,function(p)writeInteger(p,ctx.unit);writeBytes(p+4,1)end) then return end
 local actor=readPointer(calls.buffer+8)
 if not objects.live(actor) then return end
 local outer=readPointer(actor+32)
 if not outer or readPointer(outer+0xC0)~=ctx.world then return end
 if not calls.invoke('GetUnitParameter',actor,ctx) then return end
 local parameter=readPointer(calls.buffer)
 if not objects.live(parameter) or not objects.isa(parameter,'CPP_UnitParameter') then return end
 if not calls.invoke('GetRelation',parameter,ctx) or readBytes(calls.buffer,1)~=1 then return end
 assert(readPointer(actor+0x838)==parameter,'Battle parameter changed')
 local battleId=readInteger(parameter+0xD0)
 local maximum=readInteger(parameter+0x2A0)
 assert(battleId and battleId>=0 and maximum and maximum>0 and maximum<=200,'Invalid battle ID or Limit cap')
 local old=readInteger(parameter+0x118)
 assert(old and old>=0 and old<=maximum,'Unexpected Limit gauge value')
 local g={};for _,guard in ipairs(ctx.guards)do g[#g+1]=guard end
 assert(objects.live(actor,false,g) and objects.live(parameter,false,g),'Retired battle unit')
 g[#g+1]={parameter+0xD0,battleId,4};g[#g+1]={parameter+0x2A0,maximum,4}
 g[#g+1]={actor+0x838,parameter};g[#g+1]={parameter+0x118,old,4}
 if old<maximum then assert(thread.call(s.base+0x4F617D0,battleId,maximum,g),'Refill rejected; retry at a stable command screen') end
 assert(objects.live(parameter) and readInteger(parameter+0x118)==maximum,'Limit gauge readback failed')
 run.unit=ctx.unit;run.before=old;run.after=maximum
 run.status=string.format('Complete: unit %d, %d -> %d',ctx.unit,old,maximum)
 run.stop()
 print('FFRS Limit refill: '..run.status)
 showMessage('目前角色極限技槽已補滿（'..old..' → '..maximum..'）。不會自動施放；再次補滿請取消再勾選。')
end
timer.OnTimer=function()
 if not run.running then return end
 local ok,err=pcall(refill)
 if not ok then run.error=tostring(err);run.status='Stopped: '..run.error;run.stop();print('FFRS Limit refill: '..run.status) end
end
timer.Enabled=true
