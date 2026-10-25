-- UE DataTable rows: sparse TMap<FName, uint8*> with allocation-bit checks.
local function tableRows(s,o,expected)
 assert(s.cname(o)=='DataTable' and s.oname(readPointer(o+0x28))==expected,'Data table changed; retry')
 local m=o+0x30;local p=readPointer(m);local n=readInteger(m+8);local cap=readInteger(m+12)
 assert(n and cap and n>=0 and n<=cap and cap<=10000,'Invalid table size')
 assert(n==0 or (p and p>65536),'Invalid row data')
 local bits=readPointer(m+0x20);if not bits or bits==0 then bits=m+0x10 end
 local bitCount=readInteger(m+0x28);assert(bitCount and bitCount>=n and bitCount<=10000,'Invalid allocation flags')
 local out={}
 for i=0,n-1 do
  local b=assert(readInteger(bits+math.floor(i/32)*4),'Unreadable allocation flags')
  if (b & (1 << (i%32)))~=0 then
   local a=p+i*24;local row=readPointer(a+8)
   assert(row and row>65536,'Invalid row pointer')
   out[#out+1]={key=s.name(readInteger(a)),p=row}
  end
 end
 return out
end
local function findTable(s,row)
 local found
 for _,t in ipairs(s.tables) do
  if t.row==row then
   assert(s.at(t.index)==t.object and s.oname(t.object)==t.name,'Table cache expired; reopen CT')
   assert(not found,'Multiple matching tables; stop')
   found=t.object
  end
 end
 return assert(found,'Required table not loaded: '..row)
end
