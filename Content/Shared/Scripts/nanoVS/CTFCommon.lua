-- Common includes for CTF
-- nano / March 2021 - January 2022

conInfoF("[CTF] Processing common includes for CTF...\n")

local worldInfo = worldGlobals.worldInfo
local gameInfo = worldInfo:GetGameInfo()

local nowhere = mthQuatVect(mthHPBToQuaternion(0, 0, 0), mthVector3f(-1000, -1000, -1000))
local ctfTemplatePath = worldGlobals.NanoVS_CTFTemplatePath or "Content/Shared/Presets/Templates/NanoVS/CaptureTheFlag.rsc"
worldGlobals.NanoVS_CTFTemplate = LoadResource(ctfTemplatePath)

-- GLOBAL DEFINES --
worldGlobals.NanoVS_CTFPlayerData = {}
worldGlobals.NanoVS_CTFTeamData  = {
  Red = {
    FlagTaken = false
  },
  
  Blue = {
    FlagTaken = false
  }
}

-- TEAM BASES --
worldGlobals.NanoVS_CTFRedTeamBase = worldInfo:GetAllEntitiesOfClassAndName("CDetectorAreaEntity", "RedTeam")[1]
worldGlobals.NanoVS_CTFBlueTeamBase = worldInfo:GetAllEntitiesOfClassAndName("CDetectorAreaEntity", "BlueTeam")[1]

-- RPCS --

worldGlobals.CreateRPC("server", "reliable", "CTFAnnounceToTeam",
  function(thing, team)
    local localPlayer = worldGlobals.NanoVS_GetLocalPlayer()
  
    -- If the local player is nil, what are we doing here?
    if (localPlayer == nil) then
      return
    end
    
    -- Check the descriptors
    local hasDesc = worldGlobals.NanoVS_HasNetworkDescriptorsAttached(localPlayer)
    if (not hasDesc) then
      -- Uh oh
      conWarningF("[CTF] Local player has no descriptors! This is bad.\n")
      worldGlobals.NanoVS_DumpDescriptorsFor(localPlayer)
      return
    end
    
    -- Finally, check the team and play the sound
    if (localPlayer.net_sTeam == team) then
      worldGlobals.NanoVS_DoLocalAnnouncement(thing)
    end
  end
)

worldGlobals.CreateRPC("server", "reliable", "CTFSpawnItemFromTemplateForTeam",
  function(item, team)
    local localPlayer = worldGlobals.NanoVS_GetLocalPlayer()
  
    if (localPlayer == nil) then
      return
    end
    
    local hasDesc = worldGlobals.NanoVS_HasNetworkDescriptorsAttached(localPlayer)
    if (not hasDesc) then
      conWarningF("[CTF] Local player has no descriptors! This is bad.\n")
      worldGlobals.NanoVS_DumpDescriptorsFor(localPlayer)
      return
    end
    
    if (localPlayer.net_sTeam == team) then
      worldGlobals.NanoVS_CTFTemplate:SpawnEntityFromTemplateByName(item, worldInfo, nowhere)
    end   
  end
)

worldGlobals.CreateRPC("server", "reliable", "CTFSpawnItemFromTemplateAtPoint",
  function(item, point)
    worldGlobals.NanoVS_CTFTemplate:SpawnEntityFromTemplateByName(item, worldInfo, mthQuatVect(mthHPBToQuaternion(0, 0, 0), point))  
  end
)

-- LOCAL FUNCTIONS --

worldGlobals.NanoVS_CTFConstructPlayerData = function(player)
  worldGlobals.NanoVS_CTFPlayerData[player:GetPlayerId()] = {
    Caps = 0,
    Team = "?",
    pointer = player
  }  
end

worldGlobals.NanoVS_CTFRecalculateTeamScorage = function()
  local flagLimit = plpGetProfileFloat("NanoVSFlagLimit")
  local redScore = 0
  local blueScore = 0
  
  -- Collect the score for both teams
  for id, data in pairs(worldGlobals.NanoVS_CTFPlayerData) do
    if (data.Team == "Red") then
      redScore = redScore + data.Caps
    else
      blueScore = blueScore + data.Caps
    end
  end
  
  -- Check if we went above the flag limit
  -- If so, end the game
  if (redScore >= flagLimit) then
    worldGlobals.NetPerformAnnouncement("RedTeamWon")
    worldGlobals.NanoVS_ForceEndMatch()
  elseif (blueScore >= flagLimit) then
    worldGlobals.NetPerformAnnouncement("BlueTeamWon")
    worldGlobals.NanoVS_ForceEndMatch()  
  end
end

worldGlobals.NanoVS_CTFHandleFlagPosUpdate = function(flag, holder)
  if (holder ~= nil) then
    local newPos = GetBonePlacementAbs(holder, "Spine2")
    
    if (holder:IsLocalOperator() and not worldGlobals.NanoVS_IsThirdPerson()) then
      flag:Disappear()
    else
      flag:Appear()
    end
    
    
    flag:SetPlacement(newPos)
  else
    flag:SetPlacement(nowhere)
  end  
end

worldGlobals.NanoVS_CTFGetOppositeTeam = function(team)
  if (team == "Red") then
    return "Blue"
  else
    return "Red"
  end
end

worldGlobals.NanoVS_CTFRunFlagBaseLogic = function()
  -- WARNING: All CTF derivatives need to implement these handle functions!!

  -- Gather all composite entities
  local compositeEntities = worldInfo:GetAllEntitiesOfClass("CCompositeEntity")
  for i = 1, #compositeEntities, 1 do
    local composite = compositeEntities[i]
  
    -- Check if they have a special marker that indicates that they belong to a team  
    local teamMarker = composite:GetPartEntity("TeamIndicator")
    if (teamMarker ~= nil) then
      -- If the flag name is "Generic" then we're dealing with a One Flag CTF
      -- generic flag.
      if (teamMarker:GetName() == "Generic") then
        RunAsync(
          function()
            worldGlobals.NanoVS_CTFHandleGenericFlag(composite)
          end
        )
      else
        RunAsync(
          function()
            worldGlobals.NanoVS_CTFHandleTeamBase(composite, teamMarker:GetName())
          end
        )
      end
    end
  end
end

worldGlobals.NanoVS_CTFRunPlayerTeamAssignLogic = function()
  RunHandled(
    function()
      WaitForever()
    end,
    
    -- bornEvtPayload : CPlayerBornScriptEvent
    OnEvery(Event(worldInfo.PlayerBorn)),
    function(bornEvtPayload)
      local player = bornEvtPayload:GetBornPlayer()
      
      local playerId = player:GetPlayerId()
      
      if (worldGlobals.NanoVS_CTFPlayerData[playerId] == nil) then
        worldGlobals.NanoVS_CTFConstructPlayerData(player)
      end
      
      -- Check where the player has spawned and set their team
      local playerPos = player:GetPlacement():GetVect()
      local team = ""
      if (worldGlobals.NanoVS_CTFRedTeamBase:IsPointInArea(playerPos, 0.1)) then
        team = "Red"
      elseif (worldGlobals.NanoVS_CTFBlueTeamBase:IsPointInArea(playerPos, 0.1)) then
        team = "Blue"
      else
        conWarningF("[CTF] Player " .. player:GetPlayerName() .. " spawned outside of team bound?\n")
        return
      end
      
      -- Set the team in the player data
      worldGlobals.NanoVS_CTFPlayerData[playerId].Team = team
      
      -- ...and in the player descriptor if it exists.
      -- (Ensure we don't do it every time, not to accidentally congest the network)
      local hasDesc = worldGlobals.NanoVS_HasNetworkDescriptorsAttached(player)
      
      -- If we don't have the descriptors yet, force assign them
      -- we don't want to end up with the player not having them
      if (not hasDesc) then
        worldGlobals.NanoVS_ForceRegisterDescriptors(player)
        hasDesc = true
      end
      
      if (hasDesc and player.net_sTeam ~= team) then
        player.net_sTeam = team
      end
    end
  )
end