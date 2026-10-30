-- Run with Lua 5.3+ from the repository root. Uses fake memory only.
local source=assert(io.open('tools/tablet_probe.lua')):read('*a')
assert(load(source),'Standalone source must compile')
local start=assert(source:find('-- Standalone read%-only research API%.'))
local mem={}
local function put(a,v)mem[a]=v end
local save,manager,inv=1000000,2000000,3000000
local m=save+0x218
put(save+0xA8,inv);put(save+0xB0,1);put(save+0xB4,1)
put(inv,25004);put(inv+4,1);put(manager+0x60,save)
put(m,4000000);put(m+8,3);put(m+12,3);put(m+0x28,3)
put(m+0x10,5) -- slots 0 and 2 allocated; slot 1 must not be read
local function entry(slot,mid,uid,opened)
 local e=4000000+slot*0x110;local p=5000000+slot*100
 put(e,mid);put(e+8,p);put(e+16,1);put(e+20,1)
 put(p,4294967295);put(p+4,uid);put(p+8,opened);put(p+9,0);put(p+10,opened)
end
entry(0,2016,2,0);entry(2,2020,5,1)
local env=setmetatable({}, {__index=_G})
env.connect=function()return {save=save,manager=manager,pid=7}end
env.getOpenedProcessID=function()return 7 end
env.readPointer=function(a)return mem[a]end
env.readInteger=function(a)return mem[a]end
env.readBytes=function(a)return mem[a]end
env.print=function()end
local api=assert(load(source:sub(start),'tablet-probe-test','t',env))()
local output=(...) or os.tmpname()
local function export()
 assert(api.snapshot(output)==2)
 local f=assert(io.open(output));local text=f:read('*a');f:close()
 assert(text:find('SHARD_INVENTORY\t1\n',1,true))
 assert(text:find('PICKUP\t2016\t4294967295\t2\t0\t0\t0\n',1,true))
 assert(text:find('PICKUP\t2020\t4294967295\t5\t1\t0\t1\n',1,true))
 assert(text:sub(-7)=='END\tOK\n')
end
export() -- inline allocation bits
put(m+0x20,6000000);put(6000000,5)
export() -- heap allocation bits
put(5000000+8,2)
assert(not pcall(api.snapshot,output),'Invalid booleans must stop export')
put(5000000+8,0);put(manager+0x60,9999999)
assert(not pcall(api.snapshot,output),'Changed save must stop export')
os.remove(output)
print('tablet_probe_test: inline/heap sparse slots, bounds and save checks passed')
