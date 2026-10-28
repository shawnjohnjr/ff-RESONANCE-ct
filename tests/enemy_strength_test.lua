local root=...
local f=assert(io.open(root..'/src/enemy_strength_plan.lua'));local src=f:read('*a');f:close()
local plan=assert(load(src..'\nreturn enemyStrengthPlan'))()
local rows={}
for cat=1,7 do rows[#rows+1]={id=cat,category=cat,MaxHitPoint=13500,Attack=335,Intelligence=0}end
local p=plan(rows);assert(#p==6,'Only enemies and bosses')
assert(p[1].before==13500 and p[1].after==40500)
assert(p[2].after==1005,'Triple base offensive stat')
assert(p[3].after==0,'Zero sentinel preserved')
assert(rows[2].Attack==335,'Planning must not mutate baseline')
local again=plan(rows);assert(again[2].after==1005,'Planning must not compound')
assert(not pcall(plan,{{id=1,category=2,MaxHitPoint=2147483647,Attack=0,Intelligence=0}}),'Overflow rejected')
assert(not pcall(plan,{rows[2],rows[2]}),'Duplicate definitions rejected')
assert(not pcall(plan,{{id=1,category=2,MaxHitPoint=-1,Attack=0,Intelligence=0}}),'Negative values rejected')
print('enemy strength planning tests passed')
