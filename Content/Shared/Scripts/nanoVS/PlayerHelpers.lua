-- Helper for various player related shenanigans.
-- This is used to reduce code duplication in various Nano's VS scripts
-- and helps automate repetitive tasks like finding first-time joining clients
-- or finding the local client's player.
-- nano / August 2021

local worldInfo = worldGlobals.worldInfo

-- The table will be indexed with the player IDs, not their steam ones,
-- to ensure that we actually pick up players that have rejoined.
local playerTable = {}

-- Local variable holding the local player
-- It's set to local so no other script can modify it and fuck around.
local localPlayer = nil

-- Helpers for finding local player without having to duplicate code
-- The waiting coro can just call "worldGlobals.NanoVS_WaitOnLocalPlayer()"
-- and it will stall the current coro endlessly spinning until we have the player.
-- The script can then access the local player via "worldGlobals.NanoVS_GetLocalPlayer()"

-- NOTE: This will (obviously) cause the current coro context to stall!
--       Remember to call it from a RunAsync context if you want the script to run properly.
worldGlobals.NanoVS_GetLocalPlayer = function()
  return localPlayer
end

worldGlobals.NanoVS_WaitOnLocalPlayer = function()
  while (localPlayer == nil) do
    Wait(Delay(0.05))
  end
end

RunHandled(
  function()
    WaitForever()
  end,
  
  OnEvery(Event(worldInfo.PlayerBorn)),
    function(payload)
      -- player : CPlayerPuppetEntity
      local player = payload:GetBornPlayer()
      
      -- Check if we already have this player
      -- If we do, this is a no-op.
      if (playerTable[player:GetPlayerIndex()] ~= nil) then
        return
      end
      
      -- Check if this player is us, if they are
      -- set them as our own player
      if (player:IsLocalOperator()) then
        localPlayer = player
      end
      
      playerTable[player:GetPlayerIndex()] = true
      
      -- Signal the event
      SignalEvent("ClientConnected", player)
    end
)