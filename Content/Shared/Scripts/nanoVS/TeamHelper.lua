-- Helper for team based gamemodes
-- nano / April 2021

-- worldInfo : CWorldInfoEntity
local worldInfo = worldGlobals.worldInfo

-- First, register the network descriptor
RegisterNetworkDescriptor("NanoVS_PlayerTeamDescriptor", {
  {"server", "CString", "net_sTeam"}
})

-- Now, prepare the players for net sync
netPrepareClassForScriptNetSync("CPlayerPuppetEntity")

-- Helper function to check if the descriptors actually exist
-- so we don't accidentally break something while trying to assign
-- to a descriptor.
worldGlobals.NanoVS_HasNetworkDescriptorsAttached = function(player)
  return (player.net_sTeam ~= nil)
end

-- Helper for dumping the descriptors.
-- Useful in debugging scenarios
worldGlobals.NanoVS_DumpDescriptorsFor = function(player)
  conWarningF("Beginning descriptor dump:\n----------------\n")
  conWarningF("[DESCRIPTOR] CPlayerPuppetEntity::net_sTeam => " .. tostring(player.net_sTeam) .. "\n")
  conWarningF("----------------\n")  
end

worldGlobals.NanoVS_ForceRegisterDescriptors = function(player)
  conInfoF("[TeamHelper] Assigning net descriptor for player: " .. player:GetPlayerName() .. "\n")
  player:AssignScriptNetworkDescriptor("NanoVS_PlayerTeamDescriptor")
  
  -- Set up defaults
  if (worldGlobals.netIsHost) then
    worldGlobals.NanoVS_THplayers[player:GetPlayerIndex()] = true
    player.net_sTeam = "?" 
  end
end

if (not worldGlobals.netIsHost) then return end

-- Try forcing the register?
worldGlobals.NanoVS_THplayers = {}

-- Finally, assign the descriptor to every new player
RunHandled(
  function()
    WaitForever()
  end,
  
  -- player : CPlayerPuppetEntity
  OnEvery(Event(worldInfo.PlayerBorn)),
    function(playerBornEvt)
      local player = playerBornEvt:GetBornPlayer()
      
      -- If it's nil, then we haven't attached the shit to this player yet
      -- so let's do it!
      local hasDesc = worldGlobals.NanoVS_HasNetworkDescriptorsAttached(player)
      if (worldGlobals.NanoVS_THplayers[player:GetPlayerIndex()] == nil or not hasDesc) then
        -- pcall just to be safe
        pcall(
          function()
            worldGlobals.NanoVS_ForceRegisterDescriptors(player)
          end
        )
      else
        print("[TeamHelper] Not registering descriptors for player (" .. player:GetPlayerName() .. "): THplayers=" .. tostring(worldGlobals.NanoVS_THplayers[player:GetPlayerId()] == nil) .. " hasDesc=" .. tostring(hasDesc))
      end
    end
)