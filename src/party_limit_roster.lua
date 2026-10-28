-- Read the world's battle subsystem and its owned actor array (no TArray allocation).
local function partyLimitRoster(s,b)
 local cached
 local function manager(world)
  if cached and cached.world==world and b.live(cached.object)==cached.identity and readPointer(cached.object+32)==world then return cached.object end
  cached=nil
  local map=world+0x930;local p=readPointer(map)
  local n,cap=readInteger(map+8),readInteger(map+12)
  local bits,count=readPointer(map+0x20),readInteger(map+0x28)
  if not p or p<65536 or not n or not cap or n<0 or n>cap or cap>256 or not count or count<n or count>256 then return end
  if not bits or bits==0 then bits=map+0x10 end
  for i=0,n-1 do
   local flags=readInteger(bits+math.floor(i/32)*4);if not flags then return end
   if (flags & (1<<(i%32)))~=0 then
    local o=readPointer(p+i*24+8)
    if b.live(o) and b.isa(o,'CPP_BtlManager') and readPointer(o+32)==world then
     cached={world=world,object=o,identity=b.live(o)};return o
    end
   end
  end
 end
 return function(ctx)
  local m=manager(ctx.world);if not m then return end
  local um=readPointer(m+0x48)
  if not b.live(um) or not b.isa(um,'CPP_BtlUnitManager') then return end
  local p,n,cap=readPointer(um+0x28),readInteger(um+0x30),readInteger(um+0x34)
  if not p or p<65536 or not n or not cap or n<1 or n>cap or cap>128 then return end
  local roster={manager=m,members={},guards={},key=b.live(ctx.world)..'/'..b.live(m)..'/'..b.live(um)}
  if not b.live(m,false,roster.guards) or not b.live(um,false,roster.guards) then return end
  for _,g in ipairs({{m+32,ctx.world},{m+0x48,um},{um+0x28,p},{um+0x30,n,4}})do roster.guards[#roster.guards+1]=g end
  local seen={}
  for i=0,n-1 do
   local actor=readPointer(p+i*8)
   if b.live(actor) and b.isa(actor,'CPP_BtlUnit') then
    local param=readPointer(actor+0x838)
    if b.live(param) and b.isa(param,'CPP_BtlUnitParameter') then
     local id=readInteger(param+0xD0)
     -- Exclude enemies and companion visions; relation is checked again before writing.
     if id and id>=1001 and id<=1008 then
      assert(not seen[id],'Duplicate party character');seen[id]=true
      local level=readPointer(actor+32)
      if not b.live(level) or readPointer(level+0xC0)~=ctx.world then return end
      roster.members[#roster.members+1]={actor=actor,param=param,id=id,uniqueId=readInteger(actor+0x880),slot=p+i*8,level=level,
       identity=b.live(actor)..'/'..b.live(param)}
     end
    end
   end
  end
  if #roster.members==0 or #roster.members>8 then return end
  -- Streaming level identities also change when battles reuse the manager.
  roster.key=roster.key..'/'..b.live(roster.members[1].level)
  return roster
 end
end
