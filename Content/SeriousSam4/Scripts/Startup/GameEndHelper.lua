-- Game end force helper
-- nano / March 2021

local prevGlobalData = -1
local function EndMatch()
  if gam_bAutoCycleMaps then
    samNextMap()
  else
    samRestartMap()
  end
end

while true do
  Wait(Delay(0.05))
  if (prevGlobalData ~= GetGlobalData() and GetGlobalData() == 2420727) then
    print("[NanoVS] Asked to force end game, obeying.\n")
    EndMatch()
    
    SetGlobalData(prevGlobalData)
    prevGlobalData = GetGlobalData()
  end
end