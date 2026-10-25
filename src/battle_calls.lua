-- Shared, guarded Unreal calls for battle automation.
local function battleCalls(s,objects,thread)
 local p=thread.buffer
 local zero={};for i=1,128 do zero[i]=0 end
 local function invoke(n,target,ctx,fill)
  local f=assert(objects.functions[n],'Missing function '..n)
  target=f.static and f.defaults or target
  local g={};for _,v in ipairs(ctx.guards) do g[#g+1]=v end
  if not objects.live(f.object,false,g) or not objects.live(target,f.static,g) or not objects.isa(target,f.owner) then return false end
  local flags=readInteger(f.object+0xB0)
  if not flags or ((flags & 0x400)~=0)~=f.native or (not f.native and (flags & 0x800)==0) or ((flags & 0x2000)~=0)~=f.static then return false end
  g[#g+1]={f.object+0xB0,flags,4};g[#g+1]={f.object+32,f.owner}
  if f.paramSize and readSmallInteger(f.object+0xB6)~=f.paramSize then return false end
  if f.paramSize then g[#g+1]={f.object+0xB6,readInteger(f.object+0xB6),4} end
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
 return {invoke=invoke,safeScene=safeScene,buffer=p}
end
