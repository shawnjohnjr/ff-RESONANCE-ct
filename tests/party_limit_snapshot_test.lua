local root=...
local f=assert(io.open(root..'/src/party_limit_snapshot.lua'));local source=f:read('*a');f:close()
local memory={};readPointer=function(a)return memory[a]end;readInteger=readPointer
local M,E,O,S,R=0x100000,0x200000,0x300000,0x400000,0x500000
memory[M+0x78]=E;memory[M+0x80]=2;memory[M+0x84]=2
memory[E]=0;memory[E+8]=O;memory[O+0x48]=S;memory[O+0x50]=1;memory[O+0x54]=1
memory[S+8]=R;memory[S+0x10]=2;memory[S+0x14]=2
memory[R]=0;memory[R+12]=50;memory[R+20]=1;memory[R+32]=65
local b={live=function(o)return o==O and 'valid-owner' or nil end,isa=function(o,c)return o==O and c=='CPP_BtlDelEventCmd'end}
local selectSnapshot=assert(load(source..'\nreturn partyLimitSnapshot'))()
local roster={manager=M};local member={id=1005,uniqueId=1}
local result=assert(selectSnapshot(b,roster,member));assert(result.address==R+32 and result.value==65)
assert(memory[R+12]==50 and memory[R+32]==65,'Discovery must be read-only')
member.uniqueId=1005;assert(selectSnapshot(b,roster,member)==nil,'Character ID must not match actor ID')
member.uniqueId=1;memory[O+0x50]=2;assert(selectSnapshot(b,roster,member)==nil,'Queued snapshots must wait')
memory[O+0x50]=1;memory[R]=1;assert(selectSnapshot(b,roster,member)==nil,'Duplicate rows must not be guessed')
memory[R]=0;memory[S+0x10]=3;assert(selectSnapshot(b,roster,member)==nil,'Corrupt counts must be rejected')
print('party limit snapshot tests passed')
