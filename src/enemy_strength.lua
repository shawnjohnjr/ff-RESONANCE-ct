-- One session-owned baseline prevents repeated toggles from compounding.
-- Changes are in the loaded DataTable only: game files and save data are not written.
-- Reloaded tables have different object identities and must never inherit old pointers.
local function startEnemyStrength(s)
 local prior=_G.FFRS_ENEMY_STRENGTH
 if prior and prior.active then
  if prior.pid==s.pid then prior.validate();return prior end
  -- A terminated/replaced process needs no restoration in the new process.
  prior.active=false
 end
 local b=battleObjects(s)
 local tableObject=findTable(s,'UNIT_PARAMETER');local identity=assert(b.live(tableObject))
 local rows={}
 for _,r in ipairs(tableRows(s,tableObject,'UNIT_PARAMETER'))do
  local row={id=readInteger(r.p+8),category=readBytes(r.p+0x42,1),address=r.p,key=r.key}
  for _,field in ipairs(ENEMY_STRENGTH_FIELDS)do row[field.name]=readInteger(r.p+field.offset)end
  rows[#rows+1]=row
 end
 local plan=enemyStrengthPlan(rows)
 local run={pid=s.pid,active=false,status='Prepared',count=#plan/3,plan=plan}
 local function validateRows()
  assert(getOpenedProcessID()==s.pid and b.live(tableObject)==identity,'Enemy table expired; no stale writes allowed')
  local liveRows={}
  for _,r in ipairs(tableRows(s,tableObject,'UNIT_PARAMETER'))do liveRows[r.p]=true end
  for _,item in ipairs(plan)do
   local row=item.row
   assert(liveRows[row.address] and readInteger(row.address+8)==row.id and readBytes(row.address+0x42,1)==row.category,'Enemy row changed')
  end
 end
 run.validate=validateRows
 function run.stop()
  if not run.active then return end
  local ok,err=pcall(function()
   validateRows()
   -- Preflight all fields before restoring any. Leave another mod's values alone.
   for _,p in ipairs(plan)do assert(readInteger(p.row.address+p.offset)==p.after,'Enemy stat changed externally; restoration stopped')end
   for _,p in ipairs(plan)do assert(writeInteger(p.row.address+p.offset,p.before),'Enemy restoration failed')end
   for _,p in ipairs(plan)do assert(readInteger(p.row.address+p.offset)==p.before,'Enemy restoration readback failed')end
  end)
  if ok then run.active=false;run.status='Restored original enemy definitions'
  else run.error=tostring(err);run.status='Restoration failed: '..run.error end
  return ok
 end
 _G.FFRS_ENEMY_STRENGTH=run
 validateRows()
 for _,p in ipairs(plan)do assert(readInteger(p.row.address+p.offset)==p.before,'Enemy definitions changed before application')end
 local touched={}
 local ok,err=pcall(function()
  for _,p in ipairs(plan)do
   touched[#touched+1]=p
   assert(writeInteger(p.row.address+p.offset,p.after),'Enemy write failed')
   assert(readInteger(p.row.address+p.offset)==p.after,'Enemy write readback failed')
  end
 end)
 if not ok then
  -- Application occurs before the next battle, and all row identities were checked.
  -- Undo only our own values on failure; never blindly overwrite an external edit.
  validateRows()
  for _,p in ipairs(touched)do if readInteger(p.row.address+p.offset)==p.after then writeInteger(p.row.address+p.offset,p.before)end end
  error(err)
 end
 run.active=true;run.status='Enemy definitions strengthened: HP x3, Attack/Intelligence x3'
 return run
end
