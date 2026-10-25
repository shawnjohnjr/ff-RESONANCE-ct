local f=assert(io.open('src/vision_progression.lua'));local source=f:read('*a');f:close()
local plan=assert(load(source..'\nreturn visionPlan'))()
local snapshot={units={1001,1002},visions={
 {id=13024,address=100,awakening=0,synchro={[1001]={point=10,address=200},[1002]={point=0,address=220},[1008]={point=7,address=240}}},
 {id=13045,address=300,awakening=3,synchro={[1001]={point=4195,address=400},[1002]={point=0,address=420}}},
}}
local function limits(id,kind)if kind==0 then return 3,3 end;return id==13024 and 4695 or 4195,9 end
local p=plan(snapshot,0,'both',limits);assert(#p==4)
for _,op in ipairs(p)do assert(op.unit~=1008,'Non-party characters must be untouched');assert(op.target>op.before)end
assert(p[2].target==4695 and p[4].target==4195,'Use per-vision growth limits')
assert(#plan(snapshot,13045,'awakening',limits)==0,'Repeated max awakening is a no-op')
assert(#plan(snapshot,13024,'awakening',limits)==1,'Single selection must not affect another vision')
assert(not pcall(plan,snapshot,13100,'both',limits),'Unowned vision must be rejected')
assert(not pcall(plan,snapshot,0,'wrong',limits))
assert(not pcall(plan,snapshot,0,'both',function()return 2147483647,9 end),'Reject implausible limits')
snapshot.visions[1].awakening=4
assert(not pcall(plan,snapshot,0,'awakening',limits),'Do not silently downgrade out-of-range data')
snapshot.visions[1].awakening=0;snapshot.visions[1].synchro[1002]=nil
assert(not pcall(plan,snapshot,13024,'synchro',limits),'Do not create missing character records')
snapshot.units={};assert(not pcall(plan,snapshot,0,'synchro',limits),'Empty party must fail')
assert(#plan(snapshot,13024,'awakening',limits)==1)
print('Vision progression planning tests passed')
