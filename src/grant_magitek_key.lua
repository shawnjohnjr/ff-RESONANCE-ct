local function grantMagitekKey()
 assert(not (_G.FFRS_MAGITEK_KEY and _G.FFRS_MAGITEK_KEY.running),'Key grant already pending')
local s=connect();local b=battleObjects(s);battleDirectLinks(s,b).refresh()
local world=readPointer(s.base+0x9AA0540);local ui
for o in pairs(b.interfaces)do if readPointer(o+32)==world then ui=o end end
assert(ui and readBytes(ui+0x80,1)==0,'Wait outside battle')
local function inventory()
 local p,n=readPointer(s.save+0xA8),readInteger(s.save+0xB0);assert(n>=0 and n<=5000)
 local out={};for i=0,n-1 do local id,qty=readInteger(p+i*8),readInteger(p+i*8+4);assert(id and qty and not out[id]);out[id]=qty end;return out
end
local expected=inventory();local old=expected[29500] or 0;if old>=1 then b.clear();showMessage('已持有魔導裝甲之鑰，未新增。請在遊戲道具介面使用來切換外觀。');return end
checkCode(s.base+0x5107500,{0x48,0x89,0x5C,0x24,0x08,0x57,0x48,0x83,0xEC,0x20,0x8B,0xDA,0x8B,0xF9})
local list=getAddressList();for i=0,list.Count-1 do if list[i].ID==7 or list[i].ID==8 then list[i].Active=false end end
local thread=createGameThread(s);local t=createTimer(nil,false);t.Interval=250;local start=getTickCount()
local run={running=true,status='Waiting for game foreground'}
_G.FFRS_MAGITEK_KEY=run
local function report(text)run.status=text;print('FFRS Magitek Key: '..text)end
local function stop()
 if not run.running then return end
 run.running=false;t.Enabled=false;t.destroy();pcall(thread.stop);b.clear()
end
run.stop=stop
t.OnTimer=function()
 local ok,err=pcall(function()
  assert(getTickCount()-start<120000,'Timed out without grant')
  if executeCodeEx(0,3000,getAddressSafe('user32.GetForegroundWindow'))~=thread.hwnd then return end
  assert(getOpenedProcessID()==s.pid and readPointer(s.base+0x9AA0540)==world and readPointer(s.manager+0x60)==s.save and readBytes(ui+0x80,1)==0,'Context changed')
  local before=inventory();for id,q in pairs(expected)do assert(before[id]==q)end;for id,q in pairs(before)do assert(expected[id]==q)end
  local g={};for _,o in ipairs({world,s.save,s.manager,ui})do assert(b.live(o,false,g))end
  g[#g+1]={s.base+0x9AA0540,world};g[#g+1]={s.manager+0x60,s.save};g[#g+1]={ui+0x80,0,1}
  local gil=readInteger(s.save+0x28)
  assert(thread.call(s.base+0x5107500,29500,1,g),'Call rejected')
  local after=inventory();expected[29500]=old+1
  for id,q in pairs(expected)do assert(after[id]==q,'Inventory readback mismatch')end
  for id,q in pairs(after)do assert(expected[id]==q,'Unexpected item change')end
  assert(readInteger(s.save+0x28)==gil,'Gil changed')
  report('SUCCESS: Magitek Armor Key 29500 '..old..' -> '..after[29500]..'; other inventory and Gil unchanged');stop();showMessage('魔導裝甲之鑰已加入 1 把。取得陸行鳥後，可在遊戲道具介面使用來切換外觀。')
 end)
 if not ok then report('ERROR: '..tostring(err));stop()end
end
t.Enabled=true

end
