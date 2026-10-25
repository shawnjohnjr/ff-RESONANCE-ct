local function checkCode(a,bytes)
 local actual=readBytes(a,#bytes,true);assert(actual,'Game function unavailable')
 for i=1,#bytes do assert(actual[i]==bytes[i],'Game function mismatch; stop') end
end
