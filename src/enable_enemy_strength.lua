local ok,err=pcall(function()startEnemyStrength(connect())end)
if not ok then
 local r=_G.FFRS_ENEMY_STRENGTH or {};r.error=tostring(err);r.status='Stopped: '..r.error
 _G.FFRS_ENEMY_STRENGTH=r
end
