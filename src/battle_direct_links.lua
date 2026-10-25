-- Validated links for Steam build 24250053; no process-wide pointer scan.
local function battleDirectLinks(s,b)
 local cached={}
 local function subsystem(owner,offset,wanted)
  if not b.live(owner) then return end
  local old=cached[wanted]
  if old and old.owner==owner and b.live(old.object)==old.identity and readPointer(old.object+0x20)==owner then return old.object end
  cached[wanted]=nil
  local m=owner+offset;local p=readPointer(m)
  local n,cap=readInteger(m+8),readInteger(m+12)
  local bits,count=readPointer(m+0x20),readInteger(m+0x28)
  if not p or p<65536 or not n or not cap or n<0 or n>cap or cap>256 or not count or count<n or count>256 then return end
  if not bits or bits==0 then bits=m+0x10 end
  for i=0,n-1 do
   local flags=readInteger(bits+math.floor(i/32)*4)
   if not flags then return end
   if (flags & (1<<(i%32)))~=0 then
    local key=readPointer(p+i*24);local value=readPointer(p+i*24+8)
    if b.live(key,true) and s.oname(key)==wanted and b.live(value) and b.isa(value,key) and readPointer(value+0x20)==owner then
     cached[wanted]={owner=owner,object=value,identity=b.live(value)};return value
    end
   end
  end
 end
 local function accept(o,class,cache)
  local identity=b.live(o)
  if not identity or not b.isa(o,class) then return end
  cache[o]=identity;b.reflectClass(readPointer(o+16));return o
 end
 local function weak(address)
  local index,serial=readInteger(address),readInteger(address+4)
  if not index or index<=0 or not serial or serial<=0 then return end
  local o=s.at(index)
  if b.live(o)==tostring(index)..':'..tostring(serial) then return o end
 end
 local d={}
 local lastRefresh,lastLinked=0,false
 function d.clear() cached={};lastRefresh=0;lastLinked=false end
 function d.refresh()
  local now=getTickCount()
  if now-lastRefresh<250 then return lastLinked end
  lastRefresh=now;lastLinked=false
  local world=readPointer(s.base+0x9AA0540)
  if not b.live(world) then return false end
  local gi=readPointer(world+0x228)
  local widgets=subsystem(gi,0x108,'CPP_GameWidgetManagerSubsystem')
  local root=widgets and accept(readPointer(widgets+0x80),'WBP_OverAllLayout_C',b.roots)
  local ui=subsystem(world,0x930,'CPP_UI_BattleSubsystem')
  if not ui then return false end
  b.interfaces[ui]=b.live(ui)
  accept(readPointer(ui+0x48),'WBP_Btl_ResultLayout_C',b.results)
  local widget=weak(ui+0x40)
  local view
  if widget and b.isa(widget,'WBP_BattleLayout_C') then
   local commands=readPointer(widget+0x5A0)
   if b.live(commands) and b.isa(commands,'WBP_BtlCmdLayout_C') then
    view=accept(readPointer(commands+0x5A8),'CPP_VM_BtlCmd',b.views)
   end
  end
  -- A missing/changed link leaves the original discovery sweep available.
  lastLinked=root~=nil and (readBytes(ui+0x80,1)==0 or view~=nil)
  return lastLinked
 end
 return d
end
