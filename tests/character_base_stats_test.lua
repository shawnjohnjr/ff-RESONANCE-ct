local root=...
local code=assert(io.open(root..'/src/character_base_stats.lua')):read('*a')
local api=assert(load(code..'\nreturn {plan=baseStatPlan,verify=verifyBaseStatSnapshot,stats=BASE_STATS}'))()
local function snap()
 local u={id=1003,address=100,pointer=200,xp=10,join=0,values={}}
 for i=0,19 do u.values[i]=0 end;u.values[2]=10
 return {pointer=50,count=1,units={u},byId={[1003]=u}}
end
for _,stat in ipairs(api.stats)do
 local before=snap();local old=before.units[1].values[stat.id]
 local op=api.plan(before,1003,stat.id,old+1);assert(op.delta==1)
 local after=snap();after.units[1].values[stat.id]=old+1;api.verify(before,after,op,true)
 local restore=api.plan(after,1003,stat.id,old);assert(restore.delta==-1)
 api.verify(after,before,restore,true)
 after.units[1].values[3]=1;assert(not pcall(api.verify,before,after,op,true))
end
assert(api.stats[8].id==11,'AP must use EquipCost, not unused enum AP=19')
for _,bad in ipairs({-1,0.5,10000,math.huge,'3'})do assert(not pcall(api.plan,snap(),1003,1,bad))end
assert(not pcall(api.plan,snap(),1003,19,1))
local s=snap();s.units[1].join=2;assert(not pcall(api.plan,s,1003,1,1))
assert(api.plan(snap(),1003,2,10).delta==0)
print('character base stat tests passed')
