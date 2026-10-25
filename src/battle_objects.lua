-- Reflection and state validation adapted from Darjjj/resonance-game-boosters (MIT).
local function battleObjects(s)
 local b={functions={},interfaces={},views={},cursor=0,seen=0}
 local spec={
  GetBattleUnitByUniqueId={'CPP_BFL_Battle',true},
  GetUnitParameter={'CPP_BtlUnit',false},GetRelation={'CPP_UnitParameter',false},
  GetUnitAI={'CPP_BtlUnit',false},GetFightSkillId={'CPP_BtlUnitAI',false},
  CanActivateAction={'CPP_VM_BtlCmd',false},DecideActionKey={'CPP_VM_BtlCmd',false},
  GetDefaultSkillTargetUnitUniqueId={'CPP_BFL_Battle',true},
  DecideTarget={'CPP_VM_BtlCmd',false},IsEnableCommand={'CPP_BFL_Battle',true},
  IsGamePaused={'GameplayStatics',true},IsPlayingEvent={'CPP_BFL_TalkEvent',true},
  IsPlaying={'CPP_BFL_Movie',true},
 }
 local registry=s.base+0x9D84DD0
 local inheritance={}
 local scanChunks={}
 local kinds={}
 local function slot(index)
  local count=readInteger(registry+0x14)
  if not index or index<0 or not count or index>=count or count>2000000 then return end
  local chunks=readPointer(registry);if not chunks then return end
  local chunk=readPointer(chunks+math.floor(index/65536)*8)
  if chunk and chunk>65536 then return chunk+(index%65536)*24 end
 end
 function b.live(o,defaults,guards)
  if not o or o<65536 then return end
  local flags=readInteger(o+8);local index=readInteger(o+12)
  if not flags or (flags & (defaults and 0x18000 or 0x18010))~=0 then return end
  local a=slot(index)
  if not a or readPointer(a)~=o then return end
  local serial=readInteger(a+16);if not serial then return end
  if guards then
   guards[#guards+1]={a,o};guards[#guards+1]={a+16,serial,4}
   guards[#guards+1]={o+8,flags,4}
  end
  return tostring(index)..':'..tostring(serial)
 end
 function b.isa(o,class)
  local c=readPointer(o+16)
  if not c then return false end
  local key=tostring(c)..':'..tostring(class)
  if inheritance[key]~=nil then return inheritance[key] end
  for _=1,32 do
   if not c or c<65536 then return false end
   if type(class)=='number' and c==class or type(class)=='string' and s.oname(c)==class then inheritance[key]=true;return true end
   c=readPointer(c+0x40)
  end
  inheritance[key]=false;return false
 end
 local function inspect(i)
  local chunkIndex=math.floor(i/65536)
  local chunk=scanChunks[chunkIndex]
  if not chunk then
   local chunks=readPointer(registry)
   chunk=chunks and readPointer(chunks+chunkIndex*8);scanChunks[chunkIndex]=chunk
  end
  local a=chunk and chunk+(i%65536)*24;local o=a and readPointer(a)
  if not o or o<65536 then return end
  local klass=readPointer(o+16);if not klass or klass<65536 then return end
  local cn=kinds[klass]
  if not cn then
   cn=s.oname(klass)
   if cn~='Function' then
    cn=b.isa(o,'CPP_UI_BattleSubsystem') and 'UI' or b.isa(o,'CPP_VM_BtlCmd') and 'View' or 'Other'
   end
   kinds[klass]=cn
  end
  if cn=='Function' then
   local n=s.oname(o);local wanted=spec[n]
   if wanted and b.live(o,false) then
    local owner=readPointer(o+32);local flags=readInteger(o+0xB0)
    if s.oname(owner)==wanted[1] and flags and (flags & 0x400)~=0 and ((flags & 0x2000)~=0)==wanted[2] then
     b.functions[n]={object=o,owner=owner,static=wanted[2],defaults=readPointer(owner+0x110)}
    end
   end
  elseif cn=='UI' and b.live(o,false) then b.interfaces[o]=true
  elseif cn=='View' and b.live(o,false) then b.views[o]=true end
 end
 function b.scan(budget)
  local n=assert(readInteger(registry+0x14));assert(n<2000000,'Invalid object count')
  -- Prioritize newly appended objects so the first battle does not wait a full scan.
  local left=budget
  while b.seen<n and left>0 do inspect(b.seen);b.seen=b.seen+1;left=left-1 end
  while left>0 do if b.cursor>=n then b.cursor=0 end;inspect(b.cursor);b.cursor=b.cursor+1;left=left-1 end
 end
 function b.ready()
  for n in pairs(spec) do if not b.functions[n] then return false,n end end
  return true
 end
 local function add(g,a,v,size) g[#g+1]={a,v,size} end
 function b.context()
  local world=readPointer(s.base+0x9AA0540);local g={}
  if not b.live(world,false,g) then return end
  add(g,s.base+0x9AA0540,world)
  local ui
  for o in pairs(b.interfaces) do
   if not b.live(o) then b.interfaces[o]=nil
   elseif readPointer(o+32)==world and readBytes(o+0x80,1)==1 then
    if ui then return end;ui=o
   end
  end
  if not ui or not b.live(ui,false,g) then return end
  local phase=readBytes(ui+0x50,1)
  if not phase or phase>2 then return end
  add(g,ui+32,world);add(g,ui+0x80,1,1);add(g,ui+0x50,phase,1)
  local manager=readPointer(ui+0x70)
  local mid=b.live(manager,false,g)
  if not mid or readPointer(manager+32)~=ui then return end
  local typ=readBytes(manager+0x30,1);local state=readBytes(manager+0x31,1)
  if not typ or typ>2 or not state or state>1 then return end
  local asset=readPointer(manager+0x28)
  local index=readInteger(manager+0x58);local count=readInteger(manager+0x68)
  if not index or not count or count<0 or count>16 then return end
  add(g,ui+0x70,manager);add(g,manager+32,ui)
  add(g,manager+0x30,typ,1);add(g,manager+0x31,state,1);add(g,manager+0x28,asset)
  local unit
  if typ<2 then
   if index<0 or index>=count then return end
   local list=readPointer(manager+0x60);if not list or list<65536 then return end
   unit=readInteger(list+index*4)
   add(g,manager+0x58,index,4);add(g,manager+0x68,count,4);add(g,manager+0x60,list)
   add(g,list+index*4,unit,4)
  else index=0;unit=readInteger(manager+0x70);add(g,manager+0x70,unit,4) end
  if not unit or unit<0 then return end
  local view,vid,visible
  for o in pairs(b.views) do
   if not b.live(o) then b.views[o]=nil
   elseif readPointer(o+0x68)==asset then
    local v=readBytes(o+0x199,1)
    if v and v<=1 and (state==0 and v==1 or state==1 and o==b.activeView) then
     if view then return end;view=o;visible=v
    end
   end
  end
  if not view then return end
  vid=b.live(view,false,g)
  add(g,view+0x68,asset);add(g,view+0x199,visible,1)
  if state==0 then b.activeView=view end
  return {world=world,unit=unit,state=state,view=view,guards=g,
   key=world..'/'..mid..'/'..vid..'/'..unit..'/'..(index+typ*0x1000000)}
 end
 return b
end
