-- Adapted from Resonance Game Boosters auto_complete.hpp (MIT).
-- Confirm only the active result widget; never send global keyboard input.
local function resultActions(s,objects,calls)
 local a={confirms=0,releases=0,status='Waiting for results',last=0}
 local p=calls.buffer
 local function add(g,address,value,size) g[#g+1]={address,value,size} end
 function a.context()
  local world=readPointer(s.base+0x9AA0540);local base={}
  if not objects.live(world,false,base) then return end
  add(base,s.base+0x9AA0540,world)
  local ctx
  for layout in pairs(objects.results) do
   if not objects.live(layout) then objects.results[layout]=nil
   elseif readBytes(layout+0x3E0,1)==1 and readBytes(layout+0x5C8,1)==0 and objects.isa(layout,'WBP_Btl_ResultLayout_C') then
    local g={};for _,v in ipairs(base) do g[#g+1]=v end
    local identity=objects.live(layout,false,g)
    local page=readPointer(layout+0x598);local model=readPointer(layout+0x5D8)
    if identity and objects.live(page,false,g) and objects.isa(page,'WBP_BtlResultPage_Layout_C') and
       objects.live(model,false,g) and objects.isa(model,'CPP_VM_BattleResult') and readPointer(page+0x5C8)==model then
     local index=readInteger(page+0x5D0)
     if index and index>=0 and index<=128 then
      if ctx then return end
      add(g,layout+0x3E0,1,1);add(g,layout+0x5C8,0,1)
      add(g,layout+0x598,page);add(g,layout+0x5D8,model)
      add(g,page+0x5C8,model);add(g,page+0x5D0,index,4)
      ctx={world=world,layout=layout,identity=identity,page=page,index=index,guards=g}
     end
    end
   end
  end
  if not ctx then return end
  -- A live viewport root is required. Check every system/modal stack again on
  -- the game thread through guards, not just the cached discovery snapshot.
  local activeRoot
  for root in pairs(objects.roots) do
   if not objects.live(root) then objects.roots[root]=nil
   elseif objects.isa(root,'WBP_OverAllLayout_C') and calls.invoke('IsInViewport',root,ctx) and readBytes(p,1)==1 then
    if activeRoot then return end
    activeRoot=root
   end
  end
  if not activeRoot or not objects.live(activeRoot,false,ctx.guards) then return end
  for _,offset in ipairs({0x5C8,0x5D0,0x5D8,0x5E0,0x5E8}) do
   local stack=readPointer(activeRoot+offset)
   if not stack then return end
   add(ctx.guards,activeRoot+offset,stack)
   if stack~=0 then
    if not objects.live(stack,false,ctx.guards) then return end
    local child=readPointer(stack+0x1A0);if not child then return end
    add(ctx.guards,stack+0x1A0,child)
    if child~=0 then
     if not objects.live(child,false,ctx.guards) then return end
     local active=readBytes(child+0x3E0,1);if active~=0 and active~=1 then return end
     if active==1 and not objects.isa(child,'WBP_Btl_ResultLayout_C') and not objects.isa(child,'WBP_BattleSequencerLay_C') then return end
     add(ctx.guards,child+0x3E0,active,1)
    end
   end
  end
  return ctx
 end
 function a.step()
  if getTickCount()-a.last<250 then return end
  local ctx=a.context()
  if not ctx then a.status='Waiting for results';return end
  if not calls.safeScene(ctx) then a.status='Paused';return end
  if not calls.invoke('InputDecide',ctx.layout,ctx,function(b) writeBytes(b,1) end) then return end
  a.last=getTickCount();a.confirms=a.confirms+1;a.status='Result confirmed'
  -- The press can transition pages or close results. Release is addressed only
  -- to that same still-live widget, so it cannot become an input to gameplay.
  local guards={}
  if objects.live(ctx.world,false,guards) and objects.live(ctx.layout,false,guards)==ctx.identity then
   add(guards,s.base+0x9AA0540,ctx.world)
   if calls.invoke('InputDecide',ctx.layout,{world=ctx.world,guards=guards},function(b) writeBytes(b,2) end) then a.releases=a.releases+1 end
  end
 end
 return a
end
