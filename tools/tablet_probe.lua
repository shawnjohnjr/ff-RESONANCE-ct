-- Connection helper copied from src/game_connection.lua; keep build checks in sync.
-- FFRS retail Steam build 24250053. Read-only lookup, no injected game calls.
-- SDK reference: PolarWizard/final-fantasy-resonance-fix (MIT).
local function connect(battleOnly)
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
  if block>blocks then blocks=readInteger(pool+8) or -1 end
  if block>blocks or blocks>=8192 then return '?' end
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
  local currentCount=battleOnly and readInteger(g+0x14) or count
  if not i or not currentCount or currentCount>2000000 or i<0 or i>=currentCount then return nil end
  local ch=readPointer(chunks+math.floor(i/65536)*8)
  return ch and ch>65536 and readPointer(ch+(i%65536)*24) or nil
 end
 -- Battle automation does not use inventory tables or save-data writes.
 if battleOnly then return {at=at,oname=oname,cname=cname,name=name,pid=pid,base=base} end
 local function ismanager(o)
  if not o or o<65536 then return false end
  local flags=readInteger(o+8)
  return flags and (flags & 0x10)==0 and cname(o)=='CPP_MuchaSaveDataManager' and readPointer(o+0x20)==gi
 end
 local cached=_G.FFRS_CT_SESSION
 local manager,index
 local tables={}
 if cached and cached.pid==pid and cached.base==base and at(cached.index)==cached.manager and ismanager(cached.manager) and cached.tables then
  manager,index=cached.manager,cached.index
  tables=cached.tables
 else
  for i=0,count-1 do
   local o=at(i)
   if o and o>65536 and cname(o)=='DataTable' then
    local row=readPointer(o+0x28)
    local rn=oname(row)
    if rn=='CONSUMABLES_ITEM_DATA' or rn=='EQUIPMENT_ITEM_DATA' or rn=='UNIT_PARAMETER' or rn=='UNIT_LEVEL_PARAMETER_LIST' then
     tables[#tables+1]={object=o,index=i,row=rn,name=oname(o)}
    end
   end
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
 _G.FFRS_CT_SESSION={pid=pid,base=base,manager=manager,index=index,tables=tables}
 return {at=at,oname=oname,cname=cname,name=name,tables=tables,pid=pid,base=base,manager=manager,save=save,gil=gil,inventory=inv,count=n,capacity=cap}
end

-- Standalone read-only research API. Loading this file does not start a scan.
local probe = {}
local function array(a, stride, limit, fn)
 local p,n,c=readPointer(a),readInteger(a+8),readInteger(a+12)
 assert(n and c and n>=0 and n<=c and c<=limit,'Invalid array')
 assert(n==0 or (p and p>65536),'Invalid array pointer')
 for i=0,n-1 do fn(p+i*stride) end
 assert(readPointer(a)==p and readInteger(a+8)==n,'Array changed during scan; retry')
end
local function map(m,stride,limit,fn)
 local p,n,c=readPointer(m),readInteger(m+8),readInteger(m+12)
 local bc=readInteger(m+0x28)
 assert(n and c and bc and n>=0 and n<=c and c<=limit and bc>=n and bc<=limit,'Invalid sparse map')
 assert(n==0 or (p and p>65536),'Invalid map pointer')
 local bits=readPointer(m+0x20);if not bits or bits==0 then bits=m+0x10 end
 for i=0,n-1 do
  local b=assert(readInteger(bits+math.floor(i/32)*4),'Unreadable allocation flags')
  if (b & (1<<(i%32)))~=0 then fn(p+i*stride) end
 end
 assert(readPointer(m)==p and readInteger(m+8)==n,'Map changed during scan; retry')
end
local function boolean(a)
 local v=readBytes(a,1);assert(v==0 or v==1,'Invalid boolean');return v
end
function probe.snapshot(outputPath)
 assert(type(outputPath)=='string' and #outputPath>0,'Supply an absolute output filename')
 local s=connect(false)
 local rows,seen={},{}
 local shardCount=0
 array(s.save+0xA8,8,100000,function(p)
  if readInteger(p)==25004 then shardCount=shardCount+assert(readInteger(p+4)) end
 end)
 map(s.save+0x218,0x110,10000,function(e)
  local mapId=assert(readInteger(e))
  array(e+8,12,10000,function(p)
   local id,uid=assert(readInteger(p)),assert(readInteger(p+4))
   local key=mapId..':'..uid
   assert(not seen[key],'Duplicate pickup key; revalidate layout');seen[key]=true
   rows[#rows+1]={mapId,id,uid,boolean(p+8),boolean(p+9),boolean(p+10)}
  end)
 end)
 assert(readPointer(s.manager+0x60)==s.save,'Save object changed; retry')
 assert(getOpenedProcessID()==s.pid,'Process changed; retry')
 table.sort(rows,function(a,b)if a[1]~=b[1] then return a[1]<b[1] end;return a[3]<b[3] end)
 -- Only output-file writes occur below. Never writes to game memory.
 local out=assert(io.open(outputPath,'w'))
 local ok,err=pcall(function()
  assert(out:write('FORMAT\tFFRS_TABLET_PICKUPS_V1\nBUILD\t24250053\n'))
  assert(out:write('SHARD_INVENTORY\t',tostring(shardCount),'\n'))
  for _,r in ipairs(rows)do local t={'PICKUP'};for _,v in ipairs(r)do t[#t+1]=tostring(v)end;assert(out:write(table.concat(t,'\t'),'\n'))end
  assert(out:write('END\tOK\n'))
 end)
 local closed,closeErr=out:close()
 assert(ok,err);assert(closed,closeErr)
 print('Read-only pickup snapshot complete:',#rows,'records. No game memory changed.')
 return #rows
end
return probe
