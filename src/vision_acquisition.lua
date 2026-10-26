-- Native acquisition for retail build 24250053. The native function validates the
-- Vision DataTable, refuses duplicates, constructs all unit MRP entries and updates
-- collection achievements. It does not play the associated shrine/quest event.
local function missingVisions(snapshot,catalog,selected)
 local owned={};for _,v in ipairs(snapshot.visions)do owned[v.id]=true end
 local ids={};local known=false
 for id in pairs(catalog)do
  if selected==0 or id==selected then known=true;if not owned[id]then ids[#ids+1]=id end end
 end
 assert(known,'Unknown vision selection');table.sort(ids);return ids
end
local function verifyVisionAcquisition(before,after,added)
 assert(after.count==before.count+(added and 1 or 0),'Unexpected owned vision count')
 assert(after.partyCount==before.partyCount,'Party changed')
 for i,id in ipairs(before.units)do assert(after.units[i]==id,'Party changed')end
 local byId={};for _,v in ipairs(after.visions)do assert(not byId[v.id],'Duplicate vision');byId[v.id]=v end
 for _,old in ipairs(before.visions)do
  local v=assert(byId[old.id],'Owned vision disappeared')
  assert(v.awakening==old.awakening,'Existing awakening changed')
  for unit,value in pairs(old.synchro)do assert(v.synchro[unit] and v.synchro[unit].point==value.point,'Existing MRP changed')end
  for unit in pairs(v.synchro)do assert(old.synchro[unit],'Existing MRP map changed')end
 end
 if added then
  for _,v in ipairs(before.visions)do assert(v.id~=added,'Vision already owned')end
  local v=assert(byId[added],'Game did not grant vision')
  assert(v.awakening==0,'Unexpected initial awakening')
  local count=0
  for unit,value in pairs(v.synchro)do assert(unit>=1001 and unit<=1008 and value.point==0,'Unexpected initial MRP');count=count+1 end
  assert(count==8,'New vision is missing unit MRP records')
 end
end
local function visionCatalog(s,b)
 local world=readPointer(s.base+0x9AA0540);local gi=readPointer(world+0x228)
 local function mapPairs(m)
  local p,n=visionArray(m,256);local bits=readPointer(m+0x20);local bitCount=readInteger(m+0x28)
  assert(bitCount and bitCount>=n and bitCount<=256,'Invalid asset map')
  if not bits or bits==0 then bits=m+0x10 end
  local out={}
  for i=0,n-1 do local flags=assert(readInteger(bits+math.floor(i/32)*4));if (flags & (1<<(i%32)))~=0 then out[#out+1]=p+i*24 end end
  return out
 end
 local manager
 for _,a in ipairs(mapPairs(gi+0x108))do
  local k,v=readPointer(a),readPointer(a+8)
  if b.live(k,true) and s.oname(k)=='CPP_AppAssetManager' and b.live(v) and readPointer(v+32)==gi then assert(not manager,'Multiple asset managers');manager=v end
 end
 assert(manager,'Vision asset manager unavailable')
 local data
 for _,a in ipairs(mapPairs(manager+0xD0))do if readBytes(a,1)==0x2D then assert(not data,'Duplicate vision table');data=readPointer(a+8)end end
 assert(data and b.live(data),'Vision table unavailable')
 local catalog={};local n=0
 for _,row in ipairs(tableRows(s,data,'VISION_ITEM_DATA'))do
  local id=readInteger(row.p+8)
  assert(VISION_NAMES[id] and not catalog[id] and readBytes(row.p+0x70,1)==3,'Unsupported vision catalog')
  catalog[id]=row.p;n=n+1
 end
 assert(n==26,'Unexpected vision catalog size')
 return catalog,data
end
local function startVisionAcquisition(s,snapshot,catalog,selected)
 assert(not (_G.FFRS_VISION_ACQUISITION and _G.FFRS_VISION_ACQUISITION.running),'Vision acquisition already running')
 assert(not (_G.FFRS_VISION_UPGRADE and _G.FFRS_VISION_UPGRADE.running),'Wait for vision upgrade to finish')
 assert(not (_G.FFRS_BATTLE_AUTOMATION and _G.FFRS_BATTLE_AUTOMATION.running),'Turn off entries 07 and 08')
 local ids=missingVisions(snapshot,catalog,selected)
 if #ids==0 then showMessage('已持有選取的全部幻兵 / All selected visions are already owned.');return end
 local native=s.base+0x5006620
 checkCode(native,{0x4C,0x8B,0xDC,0x49,0x89,0x5B,0x20,0x55,0x49,0x8D,0x6B,0xB8,0x48,0x81,0xEC,0x40,0x01,0x00,0x00})
 checkCode(s.base+0x50067A4,{0x48,0x8D,0x4D,0xD0,0xE8,0x13,0xDE,0x0F,0x00,0x89,0x5D,0xD0})
 local b=battleObjects(s);local links=battleDirectLinks(s,b);links.refresh()
 local world=readPointer(s.base+0x9AA0540);local ui
 for o in pairs(b.interfaces)do if readPointer(o+32)==world then assert(not ui,'Multiple battle interfaces');ui=o end end
 assert(ui and readBytes(ui+0x80,1)==0,'Acquire visions outside battle')
 local fresh,tableObject=visionCatalog(s,b)
 for _,id in ipairs(ids)do assert(fresh[id]==catalog[id],'Vision data changed')end
 local function inventory()
  local p,n=visionArray(s.save+0xA8,10000);local list={}
  for i=0,n*2-1 do list[#list+1]=assert(readInteger(p+i*4))end
  return table.concat(list,',')
 end
 local initialInventory=inventory();local initialGil=readInteger(s.save+0x28)
 local expected=snapshot
 local function context(id)
  assert(getOpenedProcessID()==s.pid and readPointer(s.base+0x9AA0540)==world,'Game/world changed')
  local g={}
  for _,o in ipairs({world,s.manager,s.save,ui,tableObject})do assert(b.live(o,false,g),'Game object expired')end
  assert(readPointer(s.manager+0x60)==s.save and readPointer(ui+32)==world and readBytes(ui+0x80,1)==0,'Save/battle changed')
  assert(inventory()==initialInventory and readInteger(s.save+0x28)==initialGil,'Inventory/Gil changed')
  local now=visionSnapshot(s);verifyVisionAcquisition(expected,now)
  g[#g+1]={s.base+0x9AA0540,world};g[#g+1]={s.manager+0x60,s.save};g[#g+1]={ui+0x80,0,1}
  g[#g+1]={s.save+0x118,now.pointer};g[#g+1]={s.save+0x120,now.count,4}
  g[#g+1]={s.save+0x90,now.party};g[#g+1]={s.save+0x98,now.partyCount,4}
  for i,unit in ipairs(now.units)do g[#g+1]={now.party+(i-1)*4,unit,4}end
  for _,v in ipairs(now.visions)do g[#g+1]={v.address,v.id,4}end
  g[#g+1]={catalog[id]+8,id,4};g[#g+1]={native,readQword(native)}
  return g,now
 end
 -- Allocate only after preflight succeeds; the existing callback supplies RCX=id.
 context(ids[1])
 local thread=createGameThread(s)
 local r={running=true,completed=0,total=#ids,status='Waiting for game foreground'};_G.FFRS_VISION_ACQUISITION=r
 local timer=createTimer(nil,false);timer.Interval=250;r.timer=timer;local started=getTickCount()
 local function stop()
  if not r.running then return end
  r.running=false;timer.Enabled=false;timer.destroy();pcall(thread.stop);b.clear()
 end
 r.stop=function()r.status='Stopped; completed grants remain';stop()end
 timer.OnTimer=function()
  local ok,err=pcall(function()
   assert(getTickCount()-started<120000,'Vision acquisition timed out')
   assert(getOpenedProcessID()==s.pid,'CE changed process')
   assert(not (_G.FFRS_BATTLE_AUTOMATION and _G.FFRS_BATTLE_AUTOMATION.running),'Battle automation enabled; stop acquisition')
   assert(not (_G.FFRS_VISION_UPGRADE and _G.FFRS_VISION_UPGRADE.running),'Vision upgrade enabled; stop acquisition')
   if executeCodeEx(0,3000,assert(getAddressSafe('user32.GetForegroundWindow')))~=thread.hwnd then r.status='Waiting for game foreground';return end
   local id=ids[r.completed+1]
   if not id then r.status='Completed';stop();showMessage('幻兵取得完成 / Visions acquired: '..r.completed..'\n請重開幻兵選單確認，再另存新欄位。');return end
   local guards,before=context(id)
   assert(thread.call(native,id,0,guards),'Game focus or state changed; stopped')
   local after=visionSnapshot(s);verifyVisionAcquisition(before,after,id)
   assert(inventory()==initialInventory and readInteger(s.save+0x28)==initialGil,'Unexpected inventory/Gil change')
   expected=after;r.completed=r.completed+1;r.status=visionName(id)..' verified'
  end)
  if not ok then r.error=tostring(err);r.status='Stopped with error';stop();showMessage(r.error..'\nCompleted: '..r.completed..'; completed grants remain.')end
 end
 timer.Enabled=true;return r
end
