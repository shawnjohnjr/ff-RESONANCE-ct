-- Restore only values still owned by this feature, never recycled objects.
local function restoreMapSpeedRecord(s,b,record)
 if getOpenedProcessID()~=s.pid or b.live(record.pawn)~=record.identity then return end
 local offsets={0x86C,0x870,0x874}
 for i,o in ipairs(offsets)do
  local current=readFloat(record.pawn+o)
  if current==record.base[i]*record.multiplier then
   assert(writeFloat(record.pawn+o,record.base[i]),'Restore write failed')
   assert(readFloat(record.pawn+o)==record.base[i],'Restore readback failed')
  end
 end
 record.multiplier=1
end
local function startMapSpeedRuntime(s,b)
 assert(not (_G.FFRS_MAP_SPEED_RUNTIME and _G.FFRS_MAP_SPEED_RUNTIME.running),'Map speed is already active')
 local run={running=true,status='Waiting for map control',changes=0}
 _G.FFRS_MAP_SPEED_RUNTIME=run
 local timer=createTimer(nil,false);timer.Interval=250
 local active
 local function restoreActive()
  if active then restoreMapSpeedRecord(s,b,active);active=nil end
 end
 function run.stop()
  if not run.running then return end
  run.running=false;timer.Enabled=false;timer.destroy()
  local ok,err=pcall(restoreActive)
  b.clear()
  if not ok then run.error=tostring(err);run.status='Restore failed: '..run.error;error(err)end
  run.status='Stopped; original speed restored for live owned values'
 end
 timer.OnTimer=function()
  if not run.running then return end
  local ok,err=pcall(function()
   if getOpenedProcessID()~=s.pid then run.stop();return end
   local available,speed=pcall(mapMovementSpeed,s,b,true)
   if not available then restoreActive();run.status='Waiting: '..tostring(speed);return end
   if active and (active.pawn~=speed.pawn or active.identity~=speed.identity)then restoreActive()end
   active=speed.record
   local target=speed.mounted and 3.5 or 3
   if speed.multiplier~=target then
    run.walk,run.run,run.jog=speed.apply(target);run.changes=run.changes+1
   else
    for i,o in ipairs({0x86C,0x870,0x874})do assert(readFloat(speed.pawn+o)==speed.record.base[i]*target,'Speed changed externally')end
   end
   run.mounted=speed.mounted;run.pawn=speed.pawn
   run.status=(speed.mounted and 'Mounted 3.5x' or 'On foot 3x')
  end)
  if not ok then
   run.error=tostring(err);pcall(run.stop);run.status='Stopped: '..run.error
   print('FFRS map speed: '..run.status)
  end
 end
 timer.Enabled=true
 return run
end
