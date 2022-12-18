-- Capture The Flag gamemode
-- nano / March 2021

-- worldInfo : CWorldInfoEntity
-- player : CPlayerPuppetEntity
-- gameInfo : CGameInfo
local worldInfo = worldGlobals.worldInfo
local gameInfo = worldInfo:GetGameInfo()

dofile("Content/Shared/Scripts/nanoVS/CTFCommon.lua")

local nowhere = mthQuatVect(mthHPBToQuaternion(0, 0, 0), mthVector3f(-1000, -1000, -1000))

local redFlagHeldModel = worldGlobals.NanoVS_CTFTemplate:SpawnEntityFromTemplateByName("RedFlagHeld", worldInfo, nowhere)
local blueFlagHeldModel = worldGlobals.NanoVS_CTFTemplate:SpawnEntityFromTemplateByName("BlueFlagHeld", worldInfo, nowhere)
local redFlagHolder = nil
local blueFlagHolder = nil

worldGlobals.CreateRPC("server", "reliable", "CTFSetFlagHolderForTeam",
  function(player, team)
    if (team == "Red") then
      redFlagHolder = player
    else
      blueFlagHolder = player   
    end    
  end
)

RunAsync(
  function()
    while true do
      Wait(CustomEvent("OnStep"))
      
      -- Move the flags to their respective positions
      worldGlobals.NanoVS_CTFHandleFlagPosUpdate(redFlagHeldModel, redFlagHolder)
      worldGlobals.NanoVS_CTFHandleFlagPosUpdate(blueFlagHeldModel, blueFlagHolder)
    end
  end
)

if not worldGlobals.netIsHost then return end


worldGlobals.NanoVS_CTFStalkFlagHolder = function(player, team)
  RunAsync(
    function()
      local eventPayload = Wait(Any(Event(player.Died), CustomEvent(team .. "RespawnFlag")))  
      
      -- If the payload is just a boolean, we've probably capped the flag
      -- just abandon operation
      if (type(eventPayload.any.signaled) == "boolean") then 
        return
      end
      
      -- Reset the flag holder
      worldGlobals.CTFSetFlagHolderForTeam(nil, team)
      
      -- First, figure out where the item should drop
      local hEn, hVec = CastRay(worldInfo, player, player:GetPlacement():GetVect(), mthVector3f(0, -1, 0), 1000, 0, "bullet")
      
      local spawnPos
      
      -- If the hit entity handle is nil, then we should make the flag respawn
      -- in the base
      if (hEn == nil) then
        worldGlobals.NanoVS_CTFPerformFlagReturn(team)
        return
      -- Otherwise we're clear to spawn there
      else
        spawnPos = mthQuatVect(mthHPBToQuaternion(0, 0, 0), hVec)
      end
      
      local flag = worldGlobals.NanoVS_CTFTemplate:SpawnEntityFromTemplateByName(team .. "FlagItem", worldInfo, spawnPos)
      worldGlobals.NanoVS_CTFWaitForFlagItemPicked(flag, team)
    end
  )
end

worldGlobals.NanoVS_CTFPerformFlagReturn = function(team)
  local oppositeTeam = worldGlobals.NanoVS_CTFGetOppositeTeam(team)
        
  worldGlobals.CTFAnnounceToTeam("YourFlagReturned", team)
  worldGlobals.CTFAnnounceToTeam("TheirFlagReturned", oppositeTeam)
  worldGlobals.NetPerformAnnouncement(team .. "FlagReturned")
        
  SignalEvent(team .. "RespawnFlag")
end

worldGlobals.NanoVS_CTFWaitForFlagItemPicked = function(flag, team)
  RunAsync(
    function()
      local pickEvtPayload = Wait(Any(Event(flag.Picked), Delay(25)))
      
      -- If the event was a boolean, we know to return the flag
      -- cause it means that 
      if (type(pickEvtPayload.any.signaled) == "boolean") then
        -- Destroy the flag and return it
        flag:Delete()
        
        worldGlobals.CTFSetFlagHolderForTeam(nil, team)
        worldGlobals.NanoVS_CTFPerformFlagReturn(team)
        
        return
      end
      
      local player = pickEvtPayload.any.signaled:GetPicker()
      local playerTeam = worldGlobals.NanoVS_CTFPlayerData[player:GetPlayerId()].Team
      
      -- If the team of the player that picked up the flag is the same
      -- as the flag's team, then we need to return the flag
      if (playerTeam == team) then
        worldGlobals.CTFSetFlagHolderForTeam(nil, team)
        worldGlobals.NanoVS_CTFPerformFlagReturn(team)
        
      -- Otherwise pick up the flag
      else
        local oppositeTeam = worldGlobals.NanoVS_CTFGetOppositeTeam(team)
        
        worldGlobals.CTFSetFlagHolderForTeam(player, team)
        worldGlobals.NanoVS_CTFTeamData[team].FlagTaken = true
        
        worldGlobals.CTFAnnounceToTeam("TheyHaveYourFlag", team)
        worldGlobals.CTFAnnounceToTeam("YouHaveTheirFlag", oppositeTeam)
        
        worldGlobals.NanoVS_CTFStalkFlagHolder(player, team)        
      end
    end
  )
end

-- composite : CCompositeEntity
-- flagDetector : CDetectorAreaEntity
-- flagModel : CStaticModelEntity
worldGlobals.NanoVS_CTFHandleTeamBase = function(composite, team)
  print("[CTF] Found composite for " .. team)
  local flagDetector = composite:GetPartEntity("FlagDetector")
  local flagModel = composite:GetPartEntity("Flag")
  
  local oppositeTeam = worldGlobals.NanoVS_CTFGetOppositeTeam(team)
  
  RunHandled(
    function()
      WaitForever()
    end,
    
    -- actEvtPayload : CActivatedScriptEvent
    OnEvery(Event(flagDetector.Activated)),
    function(actEvtPayload)
      local player = actEvtPayload:GetActivator()

      -- Why would the player be null?      
      if (player == nil or player:GetClassName() ~= "CPlayerPuppetEntity") then 
        Wait(Delay(0.1))
        flagDetector:Recharge()
        
        return     
      end
      
      local oppositeFlagHolder = worldGlobals.NanoVS_CTFGetFlagHolderFor(oppositeTeam)
      local playerTeam = worldGlobals.NanoVS_CTFPlayerData[player:GetPlayerId()].Team
      
      -- If the player that took the flag isn't on the same team
      -- That means he took it
      if (playerTeam ~= team and not worldGlobals.NanoVS_CTFTeamData[team].FlagTaken) then
        worldGlobals.CTFSetFlagHolderForTeam(player, team)
        flagModel:Disappear()
        
        worldGlobals.NanoVS_CTFTeamData[team].FlagTaken = true
        
        worldGlobals.CTFAnnounceToTeam("TheyHaveYourFlag", team)
        worldGlobals.CTFAnnounceToTeam("YouHaveTheirFlag", oppositeTeam)
        
        worldGlobals.NanoVS_CTFStalkFlagHolder(player, team)
        
      -- If the team is the same and the flag holder is the player
      -- then the player has capped the flag
      elseif (playerTeam == team and oppositeFlagHolder == player and not worldGlobals.NanoVS_CTFTeamData[team].FlagTaken) then
        worldGlobals.CTFSetFlagHolderForTeam(nil, oppositeTeam)
        worldInfo:AddScore(1, player)
        
        -- Award the player a flag cap
        local id = player:GetPlayerId()
        worldGlobals.NanoVS_CTFPlayerData[id].Caps = worldGlobals.NanoVS_CTFPlayerData[id].Caps + 1
        
        worldGlobals.CTFSpawnItemFromTemplateForTeam("TeamCappedFlag", team)
        worldGlobals.CTFSpawnItemFromTemplateForTeam("EnemyCappedFlag", oppositeTeam)
        worldGlobals.NetPerformAnnouncement(team .. "TeamScores")
        
        SignalEvent(oppositeTeam .. "RespawnFlag")
        
        worldGlobals.NanoVS_CTFRecalculateTeamScorage()
      end
      
      Wait(Delay(0.1))
      flagDetector:Recharge()
    end,
    
    OnEvery(CustomEvent(team .. "RespawnFlag")),
    function()
      flagModel:Appear()
      worldGlobals.NanoVS_CTFTeamData[team].FlagTaken = false
    end
  )
end

worldGlobals.NanoVS_CTFGetFlagHolderFor = function(team)
  if (team == "Red") then
    return redFlagHolder
  else
    return blueFlagHolder
  end
end

worldGlobals.NanoVS_CTFRunFlagBaseLogic()
worldGlobals.NanoVS_CTFRunPlayerTeamAssignLogic()