-- SaveDataUnit baseParameterList stores accumulated story bonuses, not final stats.
local BASE_STATS={
 {id=1,label='HP',max=9999},{id=2,label='MP',max=9999},
 {id=5,label='力量 / Strength',max=9999},{id=6,label='體力 / Vitality',max=9999},
 {id=7,label='魔力 / Magic',max=9999},{id=8,label='精神 / Spirit',max=9999},
 {id=9,label='速度 / Speed',max=9999},{id=11,label='AP',max=9999},
}
local CHARACTER_NAMES={[1001]='雷因 / Rain',[1002]='拉斯韋爾 / Lasswell',[1003]='菲娜 / Fina',
 [1004]='莉德 / Lid',[1005]='尼科爾 / Nichol',[1006]='魔人菲娜 / Archwitch Fina',
 [1007]='傑科 / Jake',[1008]='櫻 / Sakura'}
local function baseStatSnapshot(s)
 local units,n=arrayAt(s.save+0x60,8);local out={pointer=units,count=n,units={},byId={}}
 for i=0,n-1 do
  local a=units+i*0xA0;local id=readInteger(a)
  assert(CHARACTER_NAMES[id] and not out.byId[id],'Unexpected character list')
  local p,count=arrayAt(a+0x10,20)
  assert(count==20,'Base bonus array not initialized; stop')
  local u={id=id,address=a,pointer=p,values={},xp=readInteger(a+4),join=readBytes(a+0x80,1)}
  assert(u.xp and u.xp>=0 and u.join and u.join<=4,'Invalid character state')
  for j=0,19 do local v=readInteger(p+j*4);assert(v and v>=0 and v<=2147483647,'Invalid bonus');u.values[j]=v end
  out.units[#out.units+1]=u;out.byId[id]=u
 end
 return out
end
local function baseStatPlan(snapshot,id,statId,target)
 local u=assert(snapshot.byId[id],'Character missing');assert(u.join==0,'Character not currently joined')
 local stat;for _,v in ipairs(BASE_STATS)do if v.id==statId then stat=v end end
 assert(stat,'Unsupported stat')
 assert(u.values[statId]<=stat.max,'Existing bonus exceeds editor range; stop')
 assert(type(target)=='number' and target==math.floor(target) and target>=0 and target<=stat.max,'Enter a whole number from 0 to '..stat.max)
 return {unit=u,stat=stat,before=u.values[statId],target=target,delta=target-u.values[statId]}
end
local function verifyBaseStatSnapshot(before,after,op,applied)
 assert(after.pointer==before.pointer and after.count==before.count,'Character array changed')
 for _,u in ipairs(before.units)do
  local v=assert(after.byId[u.id],'Character missing')
  assert(v.address==u.address and v.pointer==u.pointer and v.xp==u.xp and v.join==u.join,'Character context changed')
  for j=0,19 do
   local expected=applied and u.id==op.unit.id and j==op.stat.id and op.target or u.values[j]
   assert(v.values[j]==expected,'Bonus changed unexpectedly: '..u.id..' / '..j)
  end
 end
end
