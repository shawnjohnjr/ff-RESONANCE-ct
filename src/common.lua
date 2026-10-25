-- FFRS retail Steam build 24250053. Read-only lookup, no injected game calls.
-- SDK reference: PolarWizard/final-fantasy-resonance-fix (MIT).
local function connect()
 local pid=assert(getProcessIDFromProcessName('FFRS-Win64-Shipping.exe'),'Resonance is not running')
 if getOpenedProcessID()~=pid then openProcess(pid) end
 local base=assert(getAddressSafe('FFRS-Win64-Shipping.exe'),'Game module unavailable')
 local pe=base+readInteger(base+0x3c)
 assert(readInteger(pe+8)==0x6A586B2F and readInteger(pe+0x50)==503013376,'Unsupported game build; stop and revalidate')
 local pool=base+0x9CA1280
 local names={}
 local blocks=readInteger(pool+8)
 assert(blocks and blocks>=0 and blocks<8192,'Invalid name pool')
 local function name(id)
  if not id or id<0 then return '?' end
  if names[id] then return names[id] end
  local block=math.floor(id/65536);local off=(id%65536)*2
  if block>blocks then return '?' end
  local p=readPointer(pool+0x10+block*8);if not p or p<65536 then return '?' end
  local h=readSmallInteger(p+off);if not h then return '?' end
  if h<0 then h=h+65536 end
  local len=math.floor(h/64)
  if len>1023 then return '?' end
  local s
  if h%2==1 then s=readString(p+off+2,len*2,true)
  else local b=readBytes(p+off+2,len,true);s=b and string.char(table.unpack(b)) end
  names[id]=s or '?';return names[id]
 end
 assert(name(0)=='None','Name pool does not match this game')
 local function oname(o) return o and o>65536 and name(readInteger(o+0x18)) or '?' end
 local classes={}
 local function cname(o)
  local c=o and readPointer(o+0x10)
  if not c or c<65536 then return '?' end
  if not classes[c] then classes[c]=oname(c) end
  return classes[c]
 end
 local world=readPointer(base+0x9AA0540)
 assert(world and world>65536 and cname(world)=='World','Wait for a loaded world')
 local gi=readPointer(world+0x228)
 assert(gi and gi>65536,'Wait for the game instance')
 local g=base+0x9D84DD0;local count=readInteger(g+0x14);local chunks=readPointer(g)
 assert(count and count>0 and count<2000000 and chunks and chunks>65536,'Invalid object array')
 local chunkCount=readInteger(g+0x1c)
 assert(chunkCount and chunkCount>0 and chunkCount<=math.ceil(2000000/65536),'Invalid object chunks')
 local function at(i)
  if i<0 or i>=count then return nil end
  local ch=readPointer(chunks+math.floor(i/65536)*8)
  return ch and ch>65536 and readPointer(ch+(i%65536)*24) or nil
 end
 local function ismanager(o)
  if not o or o<65536 then return false end
  local flags=readInteger(o+8)
  return flags and (flags & 0x10)==0 and cname(o)=='CPP_MuchaSaveDataManager' and readPointer(o+0x20)==gi
 end
 local cached=_G.FFRS_CT_SESSION
 local manager,index
 if cached and cached.pid==pid and cached.base==base and at(cached.index)==cached.manager and ismanager(cached.manager) then
  manager,index=cached.manager,cached.index
 else
  for i=0,count-1 do
   local o=at(i)
   if ismanager(o) then assert(not manager,'Multiple active save managers; stop');manager,index=o,i end
  end
 end
 assert(manager,'Active save manager not found; load a save first')
 local save=readPointer(manager+0x60)
 assert(save and save>65536 and cname(save)=='CPP_MuchaGameSaveData','Active save data unavailable')
 local flags=readInteger(save+8);assert(flags and (flags & 0x10)==0,'Default object is not a save')
 local gil=readInteger(save+0x28)
 assert(gil and gil>=0 and gil<=2147483647,'Invalid money value')
 local inv=readPointer(save+0xA8);local n=readInteger(save+0xB0);local cap=readInteger(save+0xB4)
 assert(n and cap and n>=0 and n<=cap and cap<=100000,'Invalid inventory array')
 assert(n==0 or (inv and inv>65536),'Invalid inventory pointer')
 _G.FFRS_CT_SESSION={pid=pid,base=base,manager=manager,index=index}
 return {pid=pid,base=base,manager=manager,save=save,gil=gil,inventory=inv,count=n,capacity=cap}
end
