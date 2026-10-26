--[[
Reference: https://github.com/Darjjj/resonance-game-boosters
MIT License

Copyright (c) 2026 FxDarj

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

-- Run reflected calls on the game's window thread, following the reference mod.
-- No executable bytes or DLL files are replaced. Retain callback memory until
-- process exit: UnhookWindowsHookEx does not guarantee an in-flight return ended.
local function createGameThread(s)
 local p=assert(allocateMemory(4096,nil,0x04),'Cannot allocate read/write game-thread mailbox')
 local code=assert(allocateMemory(4096,nil,0x40),'Cannot allocate separate callback page')
 local function api(n) return assert(getAddressSafe(n),'Missing Windows API: '..n) end
 writeBytes(p,table.unpack({0,0,0,0,0,0,0,0}))
 writeString(p+0x100,'UnrealWindow',true)
 local hwnd=executeCodeEx(0,3000,api('user32.FindWindowW'),p+0x100,0)
 assert(hwnd and hwnd~=0,'Game window unavailable')
 local tid=executeCodeEx(0,3000,api('user32.GetWindowThreadProcessId'),hwnd,p+0x180)
 assert(readInteger(p+0x180)==s.pid and tid~=0,'Game window belongs to another process')
 local assembly=string.format([[
define(mailbox,%X)
define(callback,%X)
define(clock,%X)
define(foreground,%X)
define(nextHook,%X)
define(queryMemory,%X)
label(forward)
label(reject)
label(checkGuard)
label(guardByte)
label(guardDword)
label(guardNext)
label(invoke)
callback:
 push rbx
 push rsi
 push rdi
 push r12
 sub rsp,98
 mov [rsp+20],ecx
 mov [rsp+28],rdx
 mov [rsp+30],r8
 test ecx,ecx
 js forward
 cmp edx,1
 jne forward
 mov rbx,mailbox
 mov rcx,rbx
 lea rdx,[rsp+40]
 mov r8d,30
 mov rax,queryMemory
 call rax
 cmp rax,30
 jne forward
 cmp dword ptr [rsp+60],1000
 jne forward
 mov eax,[rsp+64]
 test eax,101
 jnz forward
 test eax,EE
 jz forward
 mov rax,[rsp+40]
 add rax,[rsp+58]
 lea rcx,[rbx+1000]
 cmp rax,rcx
 jb forward
 cmp dword ptr [rbx],1
 jne forward
 mov eax,1
 mov ecx,2
 lock cmpxchg [rbx+4],ecx
 jne forward
 mov dword ptr [rbx+48],1
 mov rax,clock
 call rax
 cmp rax,[rbx+8]
 jae reject
 mov dword ptr [rbx+48],2
 mov rax,foreground
 call rax
 cmp rax,[rbx+38]
 jne reject
 mov dword ptr [rbx+48],3
 mov edi,[rbx+30]
 lea rsi,[rbx+400]
checkGuard:
 mov [rbx+4C],edi
 test edi,edi
 jz invoke
 mov rcx,[rsi]
 lea rdx,[rsp+40]
 mov r8d,30
 mov rax,queryMemory
 call rax
 cmp rax,30
 jne reject
 cmp dword ptr [rsp+60],1000
 jne reject
 mov eax,[rsp+64]
 test eax,101
 jnz reject
 test eax,EE
 jz reject
 mov rax,[rsp+40]
 add rax,[rsp+58]
 mov rcx,[rsi]
 mov edx,[rsi+10]
 add rcx,rdx
 cmp rax,rcx
 jb reject
 mov rax,[rsi]
 mov rdx,[rsi+8]
 cmp dword ptr [rsi+10],1
 je guardByte
 cmp dword ptr [rsi+10],4
 je guardDword
 cmp [rax],rdx
 jne reject
 jmp guardNext
guardByte:
 cmp [rax],dl
 jne reject
 jmp guardNext
guardDword:
 cmp [rax],edx
 jne reject
guardNext:
 add rsi,18
 dec edi
 jmp checkGuard
invoke:
 mov dword ptr [rbx+48],0
 mov rcx,[rbx+18]
 mov rdx,[rbx+20]
 mov r8,[rbx+28]
 mov rax,[rbx+10]
 call rax
 mov dword ptr [rbx+4],3
 jmp forward
reject:
 mov dword ptr [rbx+4],4
forward:
 xor ecx,ecx
 mov edx,[rsp+20]
 mov r8,[rsp+28]
 mov r9,[rsp+30]
 mov rax,nextHook
 call rax
 add rsp,98
 pop r12
 pop rdi
 pop rsi
 pop rbx
 ret
]],p,code,api('kernel32.GetTickCount64'),api('user32.GetForegroundWindow'),api('user32.CallNextHookEx'),api('kernel32.VirtualQuery'))
 assert(autoAssemble(assembly),'Cannot assemble window-thread callback')
 writeQword(p+0x38,hwnd)
 local hook=executeCodeEx(0,3000,api('user32.SetWindowsHookExW'),3,code,0,tid)
 assert(hook and hook~=0,'Cannot install game window callback')
 writeInteger(p,1)
 local stopped=false
 local t={buffer=p+0x200,base=p,code=code,hwnd=hwnd,tid=tid}
 function t.stop()
  if stopped then return end
  stopped=true
  if getOpenedProcessID()~=s.pid or readSmallInteger(s.base)~=0x5A4D then return end
  writeInteger(p,0)
  -- An already executing command can finish; no new one will begin.
  executeCodeEx(0,3000,api('user32.UnhookWindowsHookEx'),hook)
 end
 function t.call(process,target,fn,guards,nativeR8)
  assert(not stopped,'Game-thread dispatcher stopped')
  assert(#guards<=100,'Too many call guards')
  assert(getOpenedProcessID()==s.pid and readInteger(p)==1,'Mailbox unavailable; stop automation')
  local state=readInteger(p+4)
  assert(state~=1 and state~=2,'Previous command still pending; stop automation')
  writeQword(p+0x10,process);writeQword(p+0x18,target)
  writeQword(p+0x20,fn);writeQword(p+0x28,nativeR8 or t.buffer)
  writeInteger(p+0x30,#guards)
  for i,g in ipairs(guards) do
   local a=p+0x400+(i-1)*24
   writeQword(a,g[1]);writeQword(a+8,g[2]);writeInteger(a+16,g[3] or 8)
  end
  -- CE and the game use the same Windows uptime clock in this Wine bottle.
  writeQword(p+8,getTickCount()+1000)
  writeInteger(p+4,1)
  executeCodeEx(0,3000,api('user32.PostThreadMessageW'),tid,0,0,0)
  local start=getTickCount()
  repeat
   state=readInteger(p+4)
   if state==3 then return true end
   if state==4 then return false end
   sleep(5)
  until getTickCount()-start>1200
  t.stop();error('Game window did not process the command; automation stopped')
 end
 return t
end
