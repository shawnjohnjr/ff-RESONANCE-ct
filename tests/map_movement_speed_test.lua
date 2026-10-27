local root=(...) or '.'
local f=assert(io.open(root..'/src/map_movement_speed.lua'));local source=f:read('*a');f:close()
local function test()
 local mem={[0x9AA0540]=100000,[100000+0x228]=200000,[200000+0x38]=300000,[200000+0x40]=1,[300000]=400000,[400000+0x30]=500000,[500000+0x2E8]=600000,[600032]=700000,[700000+0xC0]=100000,[600000+0xA08]=1,[800032]=100000,[800000+0x80]=0,[600000+0x86C]=180,[600000+0x870]=450,[600000+0x874]=230}
 local env=setmetatable({}, {__index=_G});env._G=env
 env.readPointer=function(a)return mem[a]end;env.readInteger=env.readPointer;env.readBytes=env.readPointer;env.readFloat=env.readPointer
 env.writeFloat=function(a,v)mem[a]=v;return true end;env.getOpenedProcessID=function()return 1 end;env.checkCode=function()end
 env.battleDirectLinks=function()return {refresh=function()end}end
 local b={interfaces={[800000]=true},live=function(o)return o and tostring(o)end,isa=function(o,c)return c=='CPP_MapUnit_Playable'end}
 local create=assert(load(source..'\nreturn mapMovementSpeed','test','t',env))()
 local speed=create({base=0,pid=1},b)
 speed.apply(1.5);assert(mem[600000+0x874]==345)
 speed.apply(3);assert(mem[600000+0x874]==690,'Must not compound')
 speed.apply(1);assert(mem[600000+0x86C]==180 and mem[600000+0x870]==450 and mem[600000+0x874]==230)
 mem[600000+0x874]=999;assert(not pcall(speed.apply,2));assert(mem[600000+0x86C]==180,'External change must reject before writing')
 mem[600000+0x874]=230;mem[800000+0x80]=1;assert(not pcall(speed.apply,2));assert(mem[600000+0x874]==230)
end
test();return 'PASS: multipliers, no compounding, restore, external change and battle guards'
