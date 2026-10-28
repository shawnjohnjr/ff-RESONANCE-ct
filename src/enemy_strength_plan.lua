-- UNIT_PARAMETER data-table fields, Steam build 24250053.
-- These are spawn inputs, not the battle actor's temporary resource snapshot.
-- Attack/Intelligence scale the offensive base stats, not final damage.
local ENEMY_STRENGTH_FIELDS={
 {name='MaxHitPoint',offset=0x58,multiplier=3},
 {name='Attack',offset=0x64,multiplier=3},
 {name='Intelligence',offset=0x6C,multiplier=3},
}
local function enemyStrengthPlan(rows)
 local plan,seen={},{}
 for _,row in ipairs(rows)do
  -- Enemy=2, Boss=3. Never infer affiliation from an ID range.
  if row.category==2 or row.category==3 then
   assert(not seen[row.id],'Duplicate enemy definition');seen[row.id]=true
   for _,field in ipairs(ENEMY_STRENGTH_FIELDS)do
    local before=row[field.name]
    assert(type(before)=='number' and before>=0 and before%1==0,'Invalid enemy base stat')
    local after=math.floor(before*field.multiplier+0.5)
    assert(after<=2147483647,'Enemy stat overflow')
    -- Preserve zero-valued sentinel/disabled stats rather than inventing a value.
    plan[#plan+1]={row=row,field=field.name,offset=field.offset,before=before,after=after}
   end
  end
 end
 assert(#plan>0,'No enemy definitions loaded')
 return plan
end
