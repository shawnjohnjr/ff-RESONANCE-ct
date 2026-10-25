-- Reflection and state validation adapted from Darjjj/resonance-game-boosters (MIT).
local function battleObjects(s)
 local b={functions={},interfaces={},views={},results={},roots={},cursor=0,seen=0}
 local spec={
  GetBattleUnitByUniqueId={'CPP_BFL_Battle',true},
  GetUnitParameter={'CPP_BtlUnit',false},GetRelation={'CPP_UnitParameter',false},
  GetUnitAI={'CPP_BtlUnit',false},GetFightSkillId={'CPP_BtlUnitAI',false},
  CancelCommand={'CPP_VM_BtlCmd',false,true,0},
  CanActivateAction={'CPP_VM_BtlCmd',false},DecideActionKey={'CPP_VM_BtlCmd',false},
  GetDefaultSkillTargetUnitUniqueId={'CPP_BFL_Battle',true},
  DecideTarget={'CPP_VM_BtlCmd',false},IsEnableCommand={'CPP_BFL_Battle',true},
  IsGamePaused={'GameplayStatics',true},IsPlayingEvent={'CPP_BFL_TalkEvent',true},
  IsPlaying={'CPP_BFL_Movie',true},
  InputDecide={'WBP_Btl_ResultLayout_C',false,false,1},
  IsInViewport={'Widget',false},
 }
 local registry=s.base+0x9D84DD0
 local inheritance={}
 local reflected={}
 local scanChunks={}
 local kinds={}
 local lastPrune=0
 local kindPruneCursor,inheritancePruneCursor
 local priorityCursor=nil
 b.discovery={mode='background',inspected=0,elapsedMs=0,boosts=0,pruned=0}
 -- Store identities as well as addresses: Unreal can reuse object/class slots.
 function b.prune(limit)
  limit=limit or math.huge
  local removed=0
  for _,cache in ipairs({b.interfaces,b.views,b.results,b.roots}) do
   for o,identity in pairs(cache) do
    if b.live(o)~=identity then cache[o]=nil;removed=removed+1 end
   end
  end
  local function pruneClasses(cache,cursor)
   local key=cursor or next(cache)
   local visited=0
   while key and visited<limit do
    local entry=cache[key];local following=next(cache,key)
    if b.live(key,true)~=entry.identity then cache[key]=nil;removed=removed+1 end
    key=following;visited=visited+1
   end
   return key
  end
  kindPruneCursor=pruneClasses(kinds,kindPruneCursor)
  inheritancePruneCursor=pruneClasses(inheritance,inheritancePruneCursor)
  if b.activeView and b.live(b.activeView)~=b.activeViewIdentity then
   b.activeView=nil;b.activeViewIdentity=nil
  end
  for name,fn in pairs(b.functions) do
   if b.live(fn.object)~=fn.identity then b.functions[name]=nil;if fn.owner then reflected[fn.owner]=nil end;removed=removed+1 end
  end
  b.discovery.pruned=b.discovery.pruned+removed
 end
 local clearDirect
 function b.clear()
  if clearDirect then clearDirect() end
  b.functions={};b.interfaces={};b.views={};b.results={};b.roots={}
  b.activeView=nil;b.activeViewIdentity=nil
  inheritance={};scanChunks={};kinds={}
  kindPruneCursor=nil;inheritancePruneCursor=nil;priorityCursor=nil
 end
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
  local identity=b.live(c,true);if not identity then return false end
  local cached=inheritance[c]
  if not cached or cached.identity~=identity then
   cached={identity=identity,answers={}};inheritance[c]=cached
  end
  if cached.answers[class]~=nil then return cached.answers[class] end
  for _=1,32 do
   if not c or c<65536 then return false end
   if type(class)=='number' and c==class or type(class)=='string' and s.oname(c)==class then cached.answers[class]=true;return true end
   c=readPointer(c+0x40)
  end
  cached.answers[class]=false;return false
 end
 function b.registerFunction(o)
   local n=s.oname(o);local wanted=spec[n]
   if wanted and b.live(o,false) then
    local owner=readPointer(o+32);local flags=readInteger(o+0xB0)
    local native=wanted[3]~=false
    if s.oname(owner)==wanted[1] and flags and ((flags & 0x400)~=0)==native and (native or (flags & 0x800)~=0) and ((flags & 0x2000)~=0)==wanted[2] then
     b.functions[n]={object=o,owner=owner,static=wanted[2],native=native,paramSize=wanted[4],identity=b.live(o),defaults=readPointer(owner+0x110)}
    end
   end

 end
 function b.reflectClass(c)
  for _=1,32 do
   local identity=b.live(c,true)
   if not identity or reflected[c]==identity then return end
   local owner=s.oname(c);local wanted=false
   for _,entry in pairs(spec) do if entry[1]==owner then wanted=true;break end end
   if wanted then
    reflected[c]=identity
    local f=readPointer(c+0x48);local visited={}
    for _=1,1024 do
     if not b.live(f) or visited[f] then break end
     visited[f]=true
     if readPointer(f+0x20)==c and s.oname(readPointer(f+16))=='Function' then b.registerFunction(f) end
     f=readPointer(f+0x28)
    end
   end
   c=readPointer(c+0x40)
  end
 end
 local direct=battleDirectLinks and battleDirectLinks(s,b)
 clearDirect=function() reflected={};if direct then direct.clear() end end
 local wantedClasses={}
 for _,entry in pairs(spec) do wantedClasses[entry[1]]=true end
 local function inspect(i,classesOnly)
  local chunkIndex=math.floor(i/65536)
  local chunk=scanChunks[chunkIndex]
  if not chunk then
   local chunks=readPointer(registry)
   chunk=chunks and readPointer(chunks+chunkIndex*8);scanChunks[chunkIndex]=chunk
  end
  local a=chunk and chunk+(i%65536)*24;local o=a and readPointer(a)
  if not o or o<65536 then return end
  local klass=readPointer(o+16);if not klass or klass<65536 then return end
  if classesOnly then
   if s.oname(klass)=='Class' and wantedClasses[s.oname(o)] then b.reflectClass(o) end
   return
  end
  local cached=kinds[klass]
  local cn=cached and cached.value
  if not cn then
   local identity=b.live(klass,true);if not identity then return end
   cn=s.oname(klass)
   if cn~='Function' and cn~='Class' then
    cn=b.isa(o,'CPP_UI_BattleSubsystem') and 'UI' or b.isa(o,'CPP_VM_BtlCmd') and 'View' or b.isa(o,'WBP_Btl_ResultLayout_C') and 'Result' or b.isa(o,'WBP_OverAllLayout_C') and 'Root' or 'Other'
   end
   kinds[klass]={identity=identity,value=cn}
  end
  if cn=='Function' then b.registerFunction(o)
  elseif cn=='Class' then b.reflectClass(o)
  elseif cn=='UI' and b.live(o,false) then b.interfaces[o]=b.live(o)
  elseif cn=='View' and b.live(o,false) then b.views[o]=b.live(o)
  elseif cn=='Result' and b.live(o,false) then b.results[o]=b.live(o)
  elseif cn=='Root' and b.live(o,false) then b.roots[o]=b.live(o) end
 end
 function b.scan(budget,modes)
  local n=assert(readInteger(registry+0x14));assert(n>=0 and n<2000000,'Invalid object count')
  local start=getTickCount()
  local linked=direct and direct.refresh()
  if start-lastPrune>=2000 then b.prune(8);lastPrune=start end
  scanChunks={} -- Chunk pointers are reused only within this slice.
  b.seen=math.min(b.seen,n)
  local mode='background'
  if linked and b.ready('attack') and (b.ready('results') or not next(b.results)) then
   b.discovery.mode='direct';b.discovery.inspected=0;b.discovery.elapsedMs=getTickCount()-start;return
  end
  if modes and modes.attack then
   local _,reason=b.context()
   if reason=='missing-command-view' then budget=math.max(budget,4096);mode='command-view' end
  end
  if mode=='background' and b.seen<n then budget=math.max(budget,2048);mode='initial' end
  if mode~='background' then
   if b.discovery.mode~=mode or not priorityCursor or priorityCursor>=n then priorityCursor=n-1 end
  else priorityCursor=nil end
  if mode~='background' then b.discovery.boosts=b.discovery.boosts+1 end
  local processed=0
  -- Visit reused slots too: registry size need not grow between battles.
  while processed<budget and n>0 do
   if not linked and mode~='background' and processed%2==0 then
    -- UI objects often reuse high registry slots; search backwards as well.
    -- Alternate with the full sweep so low reused slots cannot starve.
    if priorityCursor<0 then priorityCursor=n-1 end
    inspect(priorityCursor);priorityCursor=priorityCursor-1
   elseif b.seen<n then inspect(b.seen,linked);b.seen=b.seen+1
   else
    if b.cursor>=n then b.cursor=0 end
    inspect(b.cursor);b.cursor=b.cursor+1
   end
   processed=processed+1
   -- Bound each burst so CE keeps servicing its UI and the stop switch.
   if processed%32==0 and getTickCount()-start>=20 then break end
  end
  b.discovery.mode=mode;b.discovery.inspected=processed
  b.discovery.elapsedMs=getTickCount()-start
 end
 function b.ready(mode)
  local resultNames={InputDecide=true,IsInViewport=true,IsGamePaused=true,IsPlayingEvent=true,IsPlaying=true}
  for n in pairs(spec) do
   local needed=mode=='results' and resultNames[n] or mode~='results' and n~='InputDecide' and n~='IsInViewport'
   if needed and not b.functions[n] then return false,n end
  end
  return true
 end
 local function add(g,a,v,size) g[#g+1]={a,v,size} end
 function b.context()
  local world=readPointer(s.base+0x9AA0540);local g={}
  if not b.live(world,false,g) then return end
  add(g,s.base+0x9AA0540,world)
  local ui
  for o,identity in pairs(b.interfaces) do
   if b.live(o)~=identity or not b.isa(o,'CPP_UI_BattleSubsystem') then b.interfaces[o]=nil
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
  for o,identity in pairs(b.views) do
   if b.live(o)~=identity or not b.isa(o,'CPP_VM_BtlCmd') then b.views[o]=nil
   elseif readPointer(o+0x68)==asset then
    local v=readBytes(o+0x199,1)
    if v and v<=1 and (state==0 and v==1 or state==1 and o==b.activeView and b.live(o)==b.activeViewIdentity) then
     if view then return end;view=o;visible=v
    end
   end
  end
  if not view then return nil,'missing-command-view' end
  vid=b.live(view,false,g)
  add(g,view+0x68,asset);add(g,view+0x199,visible,1)
  if state==0 then b.activeView=view;b.activeViewIdentity=vid end
  return {world=world,unit=unit,state=state,commandType=typ,phase=phase,view=view,guards=g,
   key=world..'/'..mid..'/'..vid..'/'..unit..'/'..(index+typ*0x1000000)}
 end
 return b
end
