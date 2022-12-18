-- Helper for determining whether a player is in third person
-- nano / August 2021

local worldInfo = worldGlobals.worldInfo
local gameInfo = worldInfo:GetGameInfo()

-- Internal state
local thirdPersonButtonPressed = false
local isChatting = false

-- Defines for the third person value
-- This can be got via "worldGlobals.NanoVS_IsThirdPerson()"
-- We won't expose the actual third person param, just to ensure
-- that no other script modifies it by accident.
local isInThirdPerson = false
worldGlobals.NanoVS_IsThirdPerson = function()
  return isInThirdPerson
end

-- Handler that checks for player leaving or entering a vehicle
-- We need to do it, since the third person values may be entered
-- based on the preferred third person vehicle riding cvar.
local function DoRidingHandlers(player)
  RunAsync(
    function()
      local tpcopy = false
      
      RunHandled(
        function()
          WaitForever()
        end,
        
        OnEvery(Event(player.StartedRiding)),
          function()
            -- Copy the isInThirdPerson variable to restore it later
            tpcopy = isInThirdPerson
            
            isInThirdPerson = (plpGetProfileFloat("NanoVSPreferredVehicleTP") ~= 0)
          end,
          
        OnEvery(Event(player.StoppedRiding)),
          function()
            -- And restore!
            isInThirdPerson = tpcopy
          end
       )
    end
  )
end

-- Fence and wait on the local player
-- player : CPlayerPuppetEntity
worldGlobals.NanoVS_WaitOnLocalPlayer()
local player = worldGlobals.NanoVS_GetLocalPlayer()

-- Set up the TP vehicle checks
DoRidingHandlers(player)
            
-- God save me
if (plpGetProfileFloat("NanoVSPreferredTP") ~= 0) then
  isInThirdPerson = true
else
  isInThirdPerson = (gameInfo:GetSessionValueInt("SceneTraversalTP") ~= 0)
end    


while true do
  Wait(CustomEvent("OnStep"))
  if (player:IsCommandPressed("plcmdTalk")) then
    isChatting = true
  end
      
  -- Only do that if we aren't chatting
  if (not isChatting) then
    if (player:IsCommandPressed("plcmdThirdPersonView") and not thirdPersonButtonPressed) then
      thirdPersonButtonPressed = true
    elseif (player:IsCommandReleased("plcmdThirdPersonView") and thirdPersonButtonPressed) then
      thirdPersonButtonPressed = false

      isInThirdPerson = not isInThirdPerson
          
      -- Save the thing for later
      gameInfo:SetSessionValueInt("SceneTraversalTP", isInThirdPerson and 1 or 0)
    end
          
  -- Now, here comes the fun part.
  -- Figure out if the player is still chatting!
  else
    if (IsKeyPressed("Escape") or IsKeyPressed("Enter")) then
      isChatting = false
    end
  end
end