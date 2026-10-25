local function checkLevelFunctions(s)
 checkCode(s.base+0x523BC00,{0x48,0x8B,0xC4,0x56,0x48,0x81,0xEC,0xD0,0,0,0})
 checkCode(s.base+0x524B3A0,{0x48,0x89,0x5C,0x24,0x18,0x48,0x89,0x74,0x24,0x20,0x57,0x48,0x81,0xEC,0xD0,1,0,0})
end
local function setParty99(s,plan,party,n,units)
 checkLevelFunctions(s)
 -- Preflight all targets with the game's own EXP-to-level calculation.
 for _,u in ipairs(plan) do
  assert(executeCodeEx(0,5000,s.base+0x523BC00,u.id,u.target)==99,'Game rejected level-99 threshold')
 end
 local report={}
 for _,u in ipairs(plan) do
  local now=connect();local pp,pn=arrayAt(now.save+0x90,8);local up=arrayAt(now.save+0x60,64)
  assert(now.save==s.save and now.manager==s.manager and pp==party and pn==n and up==units,'Party/save changed; stop')
  for _,member in ipairs(plan) do assert(readInteger(party+member.partyIndex*4)==member.id,'Party changed; stop') end
  assert(readInteger(u.address)==u.id and readInteger(u.address+4)==u.experience,'Character EXP changed; retry')
  if u.experience<u.target then
   -- Native SetPlayableUnitExperience(UnitId, EXP, isMaxStatusSet=false):
   -- updates save EXP and refreshes the live character parameters/skills.
   executeCodeEx(0,10000,s.base+0x524B3A0,u.id,u.target,0)
   assert(readInteger(u.address+4)==u.target,'EXP update did not finish; stop and check game')
  end
  local xp=readInteger(u.address+4)
  local lv=executeCodeEx(0,5000,s.base+0x523BC00,u.id,xp)
  assert(lv==99,'Level verification failed; stop and check game')
  report[#report+1]=string.format('%s（ID %d）：Lv.%d／EXP %d',u.name,u.id,lv,xp)
 end
 return report
end
