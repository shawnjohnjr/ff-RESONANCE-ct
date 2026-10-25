-- Ordinary Attack only. Command and target selection use the game's own checks.
local function battleActions(s,objects,thread)
 local p=thread.buffer
 local actions={attacks=0,targets=0,pending=nil,status='Waiting for battle'}
 local zero={};for i=1,128 do zero[i]=0 end
 local function invoke(n,target,ctx,fill)
  local f=assert(objects.functions[n],'Missing function '..n)
  target=f.static and f.defaults or target
  local g={};for _,v in ipairs(ctx.guards) do g[#g+1]=v end
  if not objects.live(f.object,false,g) or not objects.live(target,f.static,g) or not objects.isa(target,f.owner) then return false end
  local flags=readInteger(f.object+0xB0)
  if not flags or (flags & 0x400)==0 or ((flags & 0x2000)~=0)~=f.static then return false end
  g[#g+1]={f.object+0xB0,flags,4};g[#g+1]={f.object+32,f.owner}
  local vtable=readPointer(target);local process=vtable and readPointer(vtable+0x4C*8)
  if not process or process<s.base or process>=s.base+503013376 then return false end
  g[#g+1]={target,vtable};g[#g+1]={vtable+0x4C*8,process}
  writeBytes(p,zero)
  if fill then fill(p) end
  return thread.call(process,target,f.object,g)
 end
 local function safeScene(ctx)
  if not invoke('IsGamePaused',nil,ctx,function(a) writeQword(a,ctx.world);writeBytes(a+8,1) end) or readBytes(p+8,1)~=0 then return false end
  for _,n in ipairs({'IsPlayingEvent','IsPlaying'}) do
   if not invoke(n,nil,ctx,function(a) writeBytes(a,1) end) or readBytes(p,1)~=0 then return false end
  end
  return true
 end
 local function unit(ctx,id,relation)
  if not invoke('GetBattleUnitByUniqueId',nil,ctx,function(a) writeInteger(a,id);writeBytes(a+4,1) end) then return end
  local actor=readPointer(p+8)
  if not objects.live(actor) then return end
  local outer=readPointer(actor+32)
  if not outer or readPointer(outer+0xC0)~=ctx.world then return end
  if not invoke('GetUnitParameter',actor,ctx) then return end
  local parameter=readPointer(p)
  if not invoke('GetRelation',parameter,ctx) or readBytes(p,1)~=relation then return end
  return actor
 end
 function actions.probe()
  local ctx=objects.context();if not ctx then return false,'No command screen' end
  if not safeScene(ctx) then return false,'Paused, unfocused, cinematic or changed context' end
  local actor=unit(ctx,ctx.unit,1);if not actor then return false,'No live friendly unit' end
  if not invoke('GetUnitAI',actor,ctx) then return false,'No AI' end
  local ai=readPointer(p)
  if not ai or readPointer(ai+0x28)~=actor or not invoke('GetFightSkillId',ai,ctx) then return false,'No basic attack' end
  local skill=readInteger(p)
  return true,ctx,skill
 end
 function actions.step()
  local ctx=objects.context()
  if not ctx then actions.pending=nil;actions.status='Waiting for battle';return end
  if not safeScene(ctx) then actions.status='Paused';return end
  local pending=actions.pending
  if pending and (pending.key~=ctx.key or pending.stage==2 and ctx.state==0) then pending=nil;actions.pending=nil end
  local actor=unit(ctx,ctx.unit,1);if not actor then actions.pending=nil;return end
  if not pending then
   if ctx.state~=0 then return end
   if not invoke('GetUnitAI',actor,ctx) then return end
   local ai=readPointer(p)
   if not ai or readPointer(ai+0x28)~=actor or not invoke('GetFightSkillId',ai,ctx) then return end
   local skill=readInteger(p);if not skill or skill<=0 then return end
   local function key(a) writeBytes(a,1);writeInteger(a+4,skill) end
   if not invoke('CanActivateAction',ctx.view,ctx,key) or readBytes(p+8,1)~=1 then return end
   if not invoke('IsEnableCommand',nil,ctx,function(a) writeInteger(a,ctx.unit);writeInteger(a+4,skill) end) or readBytes(p+8,1)~=1 then return end
   if invoke('DecideActionKey',ctx.view,ctx,key) then
    actions.pending={key=ctx.key,skill=skill,stage=1};actions.attacks=actions.attacks+1
    actions.status='Attack selected'
   end
  elseif pending.stage==1 and ctx.state==1 then
   if not invoke('GetDefaultSkillTargetUnitUniqueId',nil,ctx,function(a)
    writeInteger(a,ctx.unit);writeInteger(a+4,pending.skill);writeInteger(a+8,-1)
   end) then return end
   local enemy=readInteger(p+8)
   if not enemy or enemy<0 or not unit(ctx,enemy,2) then return end
   if invoke('DecideTarget',ctx.view,ctx,function(a)
    writeInteger(a+0x80,enemy);writeQword(a,a+0x80);writeInteger(a+8,1);writeInteger(a+12,1)
   end) then
    pending.stage=2;actions.targets=actions.targets+1;actions.status='Attack confirmed'
   end
  end
 end
 return actions
end
