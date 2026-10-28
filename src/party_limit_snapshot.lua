-- Battle command resource snapshots are authoritative during command refresh.
-- Writing only UnitParameter.currentLimit appears to work, then rolls back.
-- Native restore RVA 0x4F61240(owner, 0) reads snapshot[0], row.limit at +0x0C,
-- and calls the parameter setter at 0x524AE80. See the investigation document.
local function partyLimitSnapshot(b,roster,member)
 local manager=roster.manager
 local events,count,capacity=readPointer(manager+0x78),readInteger(manager+0x80),readInteger(manager+0x84)
 if not events or events<65536 or not count or not capacity or count<1 or count>capacity or capacity>256 then return end
 local owner,ownerSlot
 for i=0,count-1 do
  local event=readPointer(events+i*8)
  if b.live(event) and b.isa(event,'CPP_BtlDelEventCmd') then
   if owner then return end -- Never guess between command owners.
   owner,ownerSlot=event,events+i*8
  end
 end
 if not owner then return end
 local snapshots=readPointer(owner+0x48)
 local snapshotCount,snapshotCapacity=readInteger(owner+0x50),readInteger(owner+0x54)
 -- Only the unqueued command-selection snapshot is supported. Additional
 -- snapshots may represent pending commands with already-reserved resources.
 if not snapshots or snapshots<65536 or snapshotCount~=1 or not snapshotCapacity or snapshotCapacity<1 or snapshotCapacity>64 then return end
 local rows,rowCount,rowCapacity=readPointer(snapshots+8),readInteger(snapshots+0x10),readInteger(snapshots+0x14)
 if not rows or rows<65536 or not rowCount or not rowCapacity or rowCount<1 or rowCount>rowCapacity or rowCapacity>128 then return end
 local row
 for i=0,rowCount-1 do
  local candidate=rows+i*0x14
  -- This is the battle actor's unique ID, NOT the character ID (1001...1008).
  if readInteger(candidate)==member.uniqueId then if row then return end;row=candidate end
 end
 if not row then return end
 local saved=readInteger(row+0x0C)
 if not saved or saved<0 then return end
 local guards={}
 if not b.live(owner,false,guards)then return end
 for _,g in ipairs({{manager+0x78,events},{manager+0x80,count,4},{manager+0x84,capacity,4},
  {ownerSlot,owner},{owner+0x48,snapshots},{owner+0x50,1,4},{owner+0x54,snapshotCapacity,4},
  {snapshots+8,rows},{snapshots+0x10,rowCount,4},{snapshots+0x14,rowCapacity,4},
  {row,member.uniqueId,4},{row+0x0C,saved,4}})do guards[#guards+1]=g end
 return {address=row+0x0C,value=saved,guards=guards}
end

local function createPartyLimitWriter(s)
 -- The validated getter takes the actor's interface at +0x738 and reads +0x148.
 -- Hence actor+0x880 is the unique ID used by snapshot rows and native lookup.
 checkCode(s.base+0x4D9F080,{0x8B,0x81,0x48,1,0,0,0xC3})
 checkCode(s.base+0x4F61375,{0x8B,0x56,0x0C,0xE8,0x03,0x9B,0x2E,0})
 checkCode(s.base+0x4F617D0,{0x48,0x89,0x5C,0x24,8,0x57,0x48,0x83,0xEC,0x20,0x8B,0xFA,0x8B,0xD9})
 local code=assert(allocateMemory(4096),'Cannot allocate party Limit writer')
 -- Executed only through the existing foreground/identity-guarded dispatcher.
 -- RCX = snapshot Limit field; EDX = cap; R8D = character ID for the public setter.
 -- Both changes happen on the game thread, so command refresh cannot run between
 -- the snapshot write and the normal setter/UI update. No executable is patched.
 local assembly=string.format([[
%X:
 mov [rcx],edx
 mov ecx,r8d
 sub rsp,28
 mov rax,%X
 call rax
 add rsp,28
 ret
]],code,s.base+0x4F617D0)
 assert(autoAssemble(assembly),'Cannot assemble party Limit writer')
 -- Like the dispatcher mailbox, retain the tiny allocation until process exit:
 -- disabling must not free code while a game-thread call could still return.
 return function(thread,snapshot,member,maximum,guards)
  return thread.call(code,snapshot.address,maximum,guards,member.id)
 end
end
