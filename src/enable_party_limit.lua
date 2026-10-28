-- Deliberately silent: status stays in Lua, never opens a notification window.
local ok,err=pcall(function()startPartyLimitRefill(connect(true))end)
if not ok then _G.FFRS_PARTY_LIMIT={running=false,status='Stopped',error=tostring(err)}end
