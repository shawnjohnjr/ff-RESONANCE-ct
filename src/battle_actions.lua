-- Ordinary Attack only. Command and target selection use the game's own checks.
local function battleActions(s,objects,thread,calls)
 local p=calls.buffer
 local invoke,safeScene=calls.invoke,calls.safeScene
 local actions={attacks=0,targets=0,cancels=0,pending=nil,status='Waiting for battle'}
 local cancelledResonance=nil
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
  if not ctx then actions.pending=nil;cancelledResonance=nil;actions.status='Waiting for battle';return end
  if not safeScene(ctx) then actions.status='Paused';return end
  -- Finish (2) is SELECT RESONANCE. Cancel through this command view only;
  -- do not select a finisher, spend a gauge, or send a global Cancel key.
  if ctx.commandType==2 then
   actions.pending=nil
   if ctx.phase==2 and ctx.state==0 and cancelledResonance~=ctx.key then
    if invoke('CancelCommand',ctx.view,ctx) then
     cancelledResonance=ctx.key;actions.cancels=actions.cancels+1
     actions.status='Resonance selection cancelled'
    end
   end
   return
  end
  cancelledResonance=nil
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
