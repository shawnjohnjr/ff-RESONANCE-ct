-- Mocked links: stale weak pointers, wrong classes/owners and world changes.
local f=assert(io.open('src/battle_direct_links.lua'));local source=f:read('*a');f:close()
local memory,objects={},{}
local now=1000
local env=setmetatable({readPointer=function(a)return memory[a]end,readInteger=function(a)return memory[a]end,
 readBytes=function(a)return memory[a]end,getTickCount=function()return now end},{__index=_G})
local function obj(a,class,id)objects[a]={class=class,id=id or tostring(a)};return a end
local world=obj(0x100000,'World');local gi=obj(0x200000,'GameInstance')
local ui=obj(0x300000,'CPP_UI_BattleSubsystem');local widgets=obj(0x400000,'CPP_GameWidgetManagerSubsystem')
local root=obj(0x500000,'WBP_OverAllLayout_C');local widget=obj(0x600000,'WBP_BattleLayout_C','20:2')
local command=obj(0x700000,'WBP_BtlCmdLayout_C');local view=obj(0x800000,'CPP_VM_BtlCmd')
local result=obj(0x900000,'WBP_Btl_ResultLayout_C')
local function map(owner,offset,value,key,p)
 obj(key,objects[value].class);memory[owner+offset]=p;memory[owner+offset+8]=1;memory[owner+offset+12]=1
 memory[owner+offset+0x20]=0;memory[owner+offset+0x10]=1;memory[owner+offset+0x28]=1
 memory[p]=key;memory[p+8]=value;memory[value+0x20]=owner
end
map(world,0x930,ui,0xA00000,0xC00000);map(gi,0x108,widgets,0xB00000,0xD00000)
memory[0x9AA0540]=world;memory[world+0x228]=gi;memory[widgets+0x80]=root
memory[ui+0x40]=20;memory[ui+0x44]=2;memory[ui+0x48]=result;memory[ui+0x80]=1
memory[widget+0x5A0]=command;memory[command+0x5A8]=view
local b={interfaces={},views={},results={},roots={}}
b.live=function(o)return objects[o] and objects[o].id end
b.isa=function(o,c)return objects[o] and objects[o].class==(type(c)=='number' and objects[c].class or c)end
b.reflectClass=function()end
local s={base=0,oname=function(o)return objects[o] and objects[o].class end,at=function(i)if i==20 then return widget end end}
local d=assert(load(source..'\nreturn battleDirectLinks','direct','t',env))()(s,b)
assert(d.refresh());assert(b.views[view] and b.interfaces[ui] and b.results[result] and b.roots[root])
local function clear()now=now+300;b.views={};b.interfaces={};b.results={};b.roots={};d.clear()end
clear();memory[ui+0x44]=1;assert(not d.refresh() and not next(b.views),'Stale weak serial must fail closed')
clear();memory[ui+0x44]=2;objects[command].class='OtherWidget';assert(not d.refresh() and not next(b.views))
clear();objects[command].class='WBP_BtlCmdLayout_C';memory[ui+0x20]=gi;assert(not d.refresh() and not next(b.interfaces),'Reject wrong subsystem owner')
clear();memory[ui+0x20]=world;memory[world+0x930+12]=100000;assert(not d.refresh(),'Bound sparse map sizes')
clear();memory[world+0x930+12]=1;assert(d.refresh())
now=now+300;memory[0x9AA0540]=obj(0xE00000,'World');assert(not d.refresh(),'Do not reuse subsystem cache across worlds')
print('Direct battle link safety tests passed')
