-- Current controlled map pawn only; no global time dilation or periodic writes.
local function mapMovementSpeed(s,b)
 local offsets={0x86C,0x870,0x874} -- walking, running, jogging
 checkCode(s.base+0x4E63971,{0xF3,0x0F,0x11,0x87,0x70,0x08,0,0})
 checkCode(s.base+0x4E639F1,{0xF3,0x0F,0x11,0x87,0x6C,0x08,0,0})
 local function context()
  assert(getOpenedProcessID()==s.pid,'Game process changed')
  local world=readPointer(s.base+0x9AA0540);assert(b.live(world),'World unavailable')
  local gi=readPointer(world+0x228);assert(b.live(gi),'Game instance unavailable')
  local players=readPointer(gi+0x38);assert(players and readInteger(gi+0x40)==1,'Expected one local player')
  local lp=readPointer(players);assert(b.live(lp),'Local player unavailable')
  local pc=readPointer(lp+0x30);assert(b.live(pc),'Controller unavailable')
  local pawn=readPointer(pc+0x2E8);local identity=b.live(pawn)
  assert(identity and b.isa(pawn,'CPP_MapUnit_Playable'),'No controlled map character')
  assert(not b.isa(pawn,'CPP_MapUnit_Chocobo') and not b.isa(pawn,'CPP_MapUnit_AirShip'),'Dismount before changing speed')
  local level=readPointer(pawn+32);assert(b.live(level) and readPointer(level+0xC0)==world,'Map changed')
  assert(readBytes(pawn+0xA08,1)==1,'Wait for free map movement')
  battleDirectLinks(s,b).refresh()
  local found=false
  for o in pairs(b.interfaces)do
   if b.live(o) and readPointer(o+32)==world then
    assert(readBytes(o+0x80,1)==0,'Leave battle first');found=true
   end
  end
  assert(found,'Battle state unavailable')
  return {pawn=pawn,identity=identity,world=world}
 end
 local c=context()
 local cache=_G.FFRS_MAP_SPEED
 if not cache or cache.pid~=s.pid then cache={pid=s.pid,actors={}};_G.FFRS_MAP_SPEED=cache end
 for key,v in pairs(cache.actors)do if b.live(v.pawn)~=v.identity then cache.actors[key]=nil end end
 local key=tostring(c.pawn)..'/'..c.identity
 local record=cache.actors[key]
 local values={};for i,o in ipairs(offsets)do
  local v=readFloat(c.pawn+o);assert(v and v==v and v>0 and v<=10000,'Invalid movement speed');values[i]=v
 end
 if not record then
  record={pawn=c.pawn,identity=c.identity,base={table.unpack(values)},multiplier=1}
  -- Preserve the baseline of the live test when adopting it into the formal CT.
  local probe=_G.FFRS_MAP_SPEED_PROBE
  if probe and probe.pid==s.pid and probe.pawn==c.pawn and probe.identity==c.identity and probe.jog then
   record.base={probe.old[1],probe.old[2],probe.jog};record.multiplier=probe.multiplier or 1.5
  end
  cache.actors[key]=record
 end
 local function apply(multiplier)
  assert(multiplier==1 or multiplier==1.5 or multiplier==2 or multiplier==3,'Unsupported multiplier')
  local now=context();assert(now.pawn==c.pawn and now.identity==c.identity and now.world==c.world,'Character changed; reopen entry')
  local before={}
  for i,o in ipairs(offsets)do
   before[i]=readFloat(c.pawn+o)
   assert(before[i]==record.base[i]*record.multiplier,'Speed changed externally; refusing to overwrite')
  end
  local written=0
  local ok,err=pcall(function()
   for i,o in ipairs(offsets)do
    local live=context();assert(live.pawn==c.pawn and live.identity==c.identity and live.world==c.world,'Map changed during update')
    written=i
    assert(writeFloat(c.pawn+o,record.base[i]*multiplier),'Speed write failed')
    assert(readFloat(c.pawn+o)==record.base[i]*multiplier,'Speed readback failed')
   end
  end)
  if not ok then
   if b.live(c.pawn)==c.identity then
    for i=1,written do if readFloat(c.pawn+offsets[i])==record.base[i]*multiplier then writeFloat(c.pawn+offsets[i],before[i]) end end
   end
   error(err)
  end
  record.multiplier=multiplier
  if _G.FFRS_MAP_SPEED_PROBE and _G.FFRS_MAP_SPEED_PROBE.pawn==c.pawn then _G.FFRS_MAP_SPEED_PROBE=nil end
  return record.base[1]*multiplier,record.base[2]*multiplier,record.base[3]*multiplier
 end
 return {apply=apply,multiplier=record.multiplier}
end
