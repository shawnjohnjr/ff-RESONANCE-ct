-- One-shot, map-only unlock using the live-tested native skill and refresh calls.
assert(not (_G.FFRS_FEL_METEOR and _G.FFRS_FEL_METEOR.running),'Unlock already pending')
local s=connect();local b=battleObjects(s);battleDirectLinks(s,b).refresh()
local world=readPointer(s.base+0x9AA0540);local ui
for o in pairs(b.interfaces)do if readPointer(o+32)==world then ui=o end end
assert(ui and readBytes(ui+0x80,1)==0,'Wait outside battle')
local units=readPointer(s.save+0x60);local count=readInteger(s.save+0x68);assert(count and count>=0 and count<=8 and units and units>65536)
local u
for i=0,count-1 do local a=units+i*0xA0;if readInteger(a)==1006 then u=a end end
assert(u,'Dark Fina missing')
local function skills()
 local p,n=readPointer(u+0x50),readInteger(u+0x58);assert(n and n>=0 and n<1000 and (n==0 or p and p>65536))
 local a={};for i=0,n-1 do a[#a+1]=readInteger(p+i*4) end;return a
end
local before=skills();for _,id in ipairs(before)do if id==408160 then b.clear();showMessage('魔人菲娜已學會地獄隕石，無需重複解鎖。');return end end
local xp=readInteger(u+4);assert(xp and xp>=0,'Invalid EXP')
checkCode(s.base+0x5108640,{0x48,0x89,0x74,0x24,0x10,0x57,0x48,0x83,0xEC,0x20,0x8B,0xFA,0x8B,0xF1})
checkCode(s.base+0x524B3A0,{0x48,0x89,0x5C,0x24,0x18,0x48,0x89,0x74,0x24,0x20,0x57,0x48,0x81,0xEC,0xD0,1,0,0})
local al=getAddressList();for i=0,al.Count-1 do if al[i].ID==7 or al[i].ID==8 then assert(not al[i].Active,'Turn off automation') end end
local thread=createGameThread(s);local t=createTimer(nil,false);t.Interval=250;local start=getTickCount()
local run={running=true,status='Waiting for foreground'}
_G.FFRS_FEL_METEOR=run
local function report(v)run.status=v;print('FFRS Fel Meteor: '..v)end
local function stop()
 if not run.running then return end
 run.running=false;t.Enabled=false;t.destroy();pcall(thread.stop);b.clear()
end
run.stop=stop
t.OnTimer=function()
 local ok,err=pcall(function()
 assert(getTickCount()-start<120000,'Timed out')
 assert(getOpenedProcessID()==s.pid,'Game process changed')
 if executeCodeEx(0,3000,getAddressSafe('user32.GetForegroundWindow'))~=thread.hwnd then return end
 assert(readPointer(s.manager+0x60)==s.save and readPointer(s.base+0x9AA0540)==world and readBytes(ui+0x80,1)==0,'Context changed')
 assert(readPointer(s.save+0x60)==units and readInteger(s.save+0x68)==count,'Unit array changed')
 local current=skills();assert(#current==#before);for i,id in ipairs(before)do assert(current[i]==id)end
 local g={};for _,o in ipairs({world,s.save,s.manager,ui})do assert(b.live(o,false,g))end
 g[#g+1]={s.manager+0x60,s.save};g[#g+1]={s.base+0x9AA0540,world};g[#g+1]={ui+0x80,0,1};g[#g+1]={s.save+0x60,units};g[#g+1]={s.save+0x68,count,4};g[#g+1]={u,1006,4};g[#g+1]={u+4,xp,4}
 assert(thread.call(s.base+0x5108640,1006,408160,g),'Skill call rejected')
 local after=skills();assert(#after==#before+1 and after[#after]==408160,'Skill readback failed');for i,id in ipairs(before)do assert(after[i]==id)end
 report('Learned skill appended; refreshing live parameters with unchanged EXP')
 assert(thread.call(s.base+0x524B3A0,1006,xp,g,0),'Refresh rejected; skill already appended')
 assert(readInteger(u+4)==xp,'EXP unexpectedly changed')
 report('Complete: learned 408160; live refresh completed; EXP unchanged')
 showMessage('魔人菲娜已學會地獄隕石。請重開招式詳情確認；本項不會主動存檔。')
 stop()
 end)
 if not ok then report('ERROR: '..tostring(err));stop()end
end
t.Enabled=true
