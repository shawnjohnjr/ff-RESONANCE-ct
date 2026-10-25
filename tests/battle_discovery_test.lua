-- Lua 5.3+, run from the repository root; simulated registry, no game calls.
local f=assert(io.open('src/battle_objects.lua','r'));local source=f:read('*a');f:close()
local memory,names={},{}
local now,clockStep=0,0
local reads=0
local registry,chunks,chunk=0x9D84DD0,0x200000,0x300000
local count=10000
memory[registry]=chunks;memory[registry+0x14]=count;memory[chunks]=chunk
local env=setmetatable({
 readPointer=function(a)reads=reads+1;return memory[a]end,
 readInteger=function(a)reads=reads+1;return memory[a]end,
 readBytes=function(a)reads=reads+1;return memory[a]end,
 getTickCount=function()now=now+clockStep;return now end,
},{__index=_G})
local factory=assert(load(source..'\nreturn battleObjects','battle_objects','t',env))()
local b=factory({base=0,oname=function(o)return names[o] or '?'end})
local function object(index,address,klass,serial,name)
 memory[chunk+index*24]=address;memory[chunk+index*24+16]=serial
 memory[address+8]=0;memory[address+12]=index;memory[address+16]=klass
 names[address]=name
end
local class,view=0x400000,0x500000
object(1,class,0,1,'CPP_VM_BtlCmd');object(9000,view,class,1)
local cold=factory({base=0,oname=function(o)return names[o] or '?'end})
cold.context=function()return nil end
cold.scan(256,{attack=true});assert(cold.views[view],'Initial discovery must inspect high slots before completing the forward sweep')
b.seen=count;b.cursor=0
b.context=function()return nil,'missing-command-view'end
b.scan(256,{attack=true});assert(b.discovery.mode=='command-view' and b.discovery.inspected==4096)
assert(b.views[view]==b.live(view),'A high reused slot should be found in the first bidirectional burst')
b.scan(256,{attack=true});b.scan(256,{attack=true})
assert(b.views[view]==b.live(view),'Must find a view in a reused slot without registry growth')
b.context=function()return {}end
b.scan(256,{attack=true});assert(b.discovery.mode=='background' and b.discovery.inspected==256)
b.context=function()return nil,'missing-command-view'end
b.scan(256,{results=true});assert(b.discovery.mode=='background','Results-only mode must not request attack discovery')
b.context=function()return nil end
b.scan(256,{attack=true});assert(b.discovery.mode=='background','Exploration must not trigger a command-view burst')
-- A new object at the same address must not inherit the previous view identity.
b.activeView=view;b.activeViewIdentity=b.live(view)
object(9000,view,class,2)
b.prune();assert(not b.views[view] and not b.activeView)
b.cursor=8999;b.scan(4);assert(b.views[view]==b.live(view),'New lifetime must be rediscovered')
-- Reused class addresses must invalidate both classification and inheritance answers.
object(1,class,0,2,'UnrelatedClass');b.prune();b.cursor=9000;b.scan(1)
assert(not b.isa(view,'CPP_VM_BtlCmd'),'Old class inheritance answer must not survive reuse')
-- Cleanup covers caches that are not used by the enabled feature.
local dead=0x600000
for _,cache in ipairs({b.interfaces,b.views,b.results,b.roots})do cache[dead]='retired'end
b.functions.retired={object=dead,identity='retired'}
b.prune()
for _,cache in ipairs({b.interfaces,b.views,b.results,b.roots})do assert(cache[dead]==nil)end
assert(not b.functions.retired)
-- Class cleanup must remain bounded even after many distinct classes were cached.
for i=1,64 do
 local c,o=0x1000000+i*0x100,0x2000000+i*0x100
 object(100+i,c,0,1,'TransientClass');object(200+i,o,c,1)
 assert(not b.isa(o,'CPP_VM_BtlCmd'))
 memory[chunk+(100+i)*24+16]=2
end
reads=0;b.prune(8);assert(reads<200,'Incremental pruning must not walk every cached class')
for _=1,20 do b.prune(8) end
-- A slow read slice yields early; an empty registry performs no reads.
clockStep=20;b.scan(4096,{attack=true});assert(b.discovery.inspected<=32)
clockStep=0;memory[registry+0x14]=0;b.scan(256);assert(b.discovery.inspected==0)
b.clear();for _,cache in ipairs({b.interfaces,b.views,b.results,b.roots,b.functions})do assert(next(cache)==nil)end
print('Battle discovery tests passed')
