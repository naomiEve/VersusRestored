-- Team Indicators for team based gamemodes
-- nano / April 2021

-- worldInfo : CWorldInfoEntity
-- player : CPlayerPuppetEntity
local worldInfo = worldGlobals.worldInfo
local players = {}
local playersInGame = {}
local templatePath = worldGlobals.NanoVS_TeamIndicatorTemplate or "Content/Shared/Presets/Templates/NanoVS/TeamIndicator.rsc"

-- template : CTemplatePropertiesHolder
local localPlayer
local template = LoadResource(templatePath)

worldGlobals.NanoVS_TeamStalkPlayer = function(localPlayer, player)
  -- Protect ourselves
  players[player:GetPlayerId()] = true
  
  -- Create a new marker
  -- marker : CParticleEffectEntity
  local marker = template:SpawnEntityFromTemplateByName("TeamIndicator", worldInfo, mthQuatVect(mthHPBToQuaternion(0, 0, 0), mthVector3f(0, 0, 0)))
  
  RunHandled(
    function()
      -- Ensure we run for as long as the player exists
      while (not IsDeleted(player) and 
             player.net_sTeam == localPlayer.net_sTeam) do
        Wait(CustomEvent("OnStep"))
      end
    end,
        
    OnEvery(CustomEvent("OnStep")),
      function()
        -- Calculate the new position
        local bbox = player:GetBoundingBoxSize()
        local plac = player:GetPlacement():GetVect()
            
        -- Set it!
        local newPos = mthQuatVect(mthHPBToQuaternion(0, 0, 0), mthVector3f(plac.x, plac.y + bbox.y - 0.3, plac.z))
        marker:SetPlacement(newPos)
      end
  )
  
  -- Destroy the marker
  marker:Delete()
  
  players[player:GetPlayerId()] = nil
end

worldGlobals.NanoVS_TeamTrySpawnIndicator = function(player)
  -- First, check if the player is the local player
  -- without a local player, we can't proceed at all
  if (player:IsLocalViewer()) then
    localPlayer = player
    return
  elseif (localPlayer == nil) then 
    return
  end
  
  -- Now, check if we already "stalk" the player
  if (players[player:GetPlayerId()] ~= nil) then
    return
  end      
  
  -- Next, check if the player has a network desc
  -- If they don't, we have nothing to do with them
  local hasDesc = worldGlobals.NanoVS_HasNetworkDescriptorsAttached(player)
  if (not hasDesc) then
    return
  end
  
  -- Lastly, check if this player's team matches ours
  if (player.net_sTeam ~= localPlayer.net_sTeam) then
    return
  end
  
  RunAsync(
    function()
      worldGlobals.NanoVS_TeamStalkPlayer(localPlayer, player)
    end
  )
end

RunHandled(
  function()
    WaitForever()
  end,
  
  -- Completely arbitrary
  OnEvery(Delay(3)),
    function()
      if (#playersInGame ~= worldInfo:GetPlayersCount()) then
        playersInGame = worldInfo:GetAllPlayersInRange(worldInfo, 10000)
      end
      
      for i = 1, #playersInGame, 1 do
        worldGlobals.NanoVS_TeamTrySpawnIndicator(playersInGame[i])
      end
    end
)