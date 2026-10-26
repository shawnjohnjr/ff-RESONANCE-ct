local f=assert(io.open('src/vision_acquisition.lua'));local source=f:read('*a');f:close()
local missing,verify=assert(load(source..'\nreturn missingVisions,verifyVisionAcquisition'))()
local function vision(id,p)
 local v={id=id,awakening=p,synchro={}}
 for unit=1001,1008 do v.synchro[unit]={point=p}end
 return v
end
local old=vision(13024,3)
local before={count=1,partyCount=2,units={1001,1002},visions={old}}
local catalog={[13024]=true,[13045]=true,[13100]=true}
local ids=missing(before,catalog,0);assert(#ids==2 and ids[1]==13045 and ids[2]==13100)
assert(#missing(before,catalog,13024)==0,'Already-owned selection is a no-op')
assert(#missing(before,catalog,13100)==1)
assert(not pcall(missing,before,catalog,99999),'Reject unknown IDs')
local after={count=2,partyCount=2,units={1001,1002},visions={vision(13024,3),vision(13045,0)}}
verify(before,after,13045)
assert(#missing(after,{[13024]=true,[13045]=true},0)==0,'Repeated run must not duplicate')
after.visions[1].awakening=0;assert(not pcall(verify,before,after,13045),'Preserve existing growth');after.visions[1].awakening=3
after.visions[2].synchro[1008]=nil;assert(not pcall(verify,before,after,13045),'Require all eight unit records');after.visions[2]=vision(13045,0)
after.visions[2].synchro[1003].point=1;assert(not pcall(verify,before,after,13045),'Do not grant unexpected MRP');after.visions[2]=vision(13045,0)
after.units[2]=1003;assert(not pcall(verify,before,after,13045),'Stop on party changes');after.units[2]=1002
after.visions[1].synchro[1008].point=4;assert(not pcall(verify,before,after,13045),'Preserve non-party MRP')
print('Vision acquisition planning/readback tests passed')
