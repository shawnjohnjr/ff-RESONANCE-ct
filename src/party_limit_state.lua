-- Once per live party member per battle; command changes do not re-arm it.
local function partyLimitState()
 local state={key=nil,done={},battles=0,refills=0}
 function state.reset()state.key=nil;state.done={}end
 function state.enter(key)
  if state.key~=key then state.key=key;state.done={};state.battles=state.battles+1 end
 end
 function state.pending(identity)return not state.done[identity]end
 function state.mark(identity)state.done[identity]=true;state.refills=state.refills+1 end
 return state
end
