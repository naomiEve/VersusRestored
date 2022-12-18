-- One Flag CTF
-- nano / January 2022

-- worldInfo : CWorldInfoEntity
-- player : CPlayerPuppetEntity
-- gameInfo : CGameInfo
local worldInfo = worldGlobals.worldInfo
local gameInfo = worldInfo:GetGameInfo()

dofile("Content/Shared/Scripts/nanoVS/CTFCommon.lua")

local nowhere = mthQuatVect(mthHPBToQuaternion(0, 0, 0), mthVector3f(-1000, -1000, -1000))

local flagHeldModel = worldGlobals.NanoVS_CTFTemplate:SpawnEntityFromTemplateByName("GenericFlagHeld", worldInfo, nowhere)
local flagHolder = nil
local flagTaken = false

worldGlobals.CreateRPC("server", "reliable", "CTFSetFlagHolder",
  function(player)
    flagHolder = player   
  end
)

RunAsync(
  function()
    while true do
      Wait(CustomEvent("OnStep"))
      
      -- Move the flags to their respective positions
      worldGlobals.NanoVS_CTFHandleFlagPosUpdate(flagHeldModel, flagHolder)
    end
  end
)

if not worldGlobals.netIsHost then return end

worldGlobals.NanoVS_CTFStalkFlagHolder = function(player)
  RunAsync(
    function()
      local eventPayload = Wait(Any(Event(player.Died), CustomEvent("RespawnFlag")))  
      
      -- If the payload is just a boolean, we've probably capped the flag
      -- just abandon operation
      if (type(eventPayload.any.signaled) == "boolean") then 
        return
      end
      
      -- Reset the flag holder
      worldGlobals.CTFSetFlagHolder(nil)
      
      -- First, figure out where the item should drop
      local hEn, hVec = CastRay(worldInfo, player, player:GetPlacement():GetVect(), mthVector3f(0, -1, 0), 1000, 0, "bullet")
      
      local spawnPos
      
      -- If the hit entity handle is nil, then we should make the flag respawn
      -- in the base
      if (hEn == nil) then
        worldGlobals.NanoVS_CTFPerformFlagReturn()
        return
      -- Otherwise we're clear to spawn there
      else
        spawnPos = mthQuatVect(mthHPBToQuaternion(0, 0, 0), hVec)
      end
      
      local flag = worldGlobals.NanoVS_CTFTemplate:SpawnEntityFromTemplateByName("GenericFlagItem", worldInfo, spawnPos)
      worldGlobals.NanoVS_CTFWaitForFlagItemPicked(flag)
    end
  )
end

worldGlobals.NanoVS_CTFPerformFlagReturn = function()
  worldGlobals.NetPerformAnnouncement("TheirFlagReturned")   
  SignalEvent("RespawnFlag")
end

worldGlobals.NanoVS_CTFWaitForFlagItemPicked = function(flag)
  RunAsync(
    function()
      local pickEvtPayload = Wait(Any(Event(flag.Picked), Delay(25)))
      
      -- If the event was a boolean, we know to return the flag
      -- cause it means that 
      if (type(pickEvtPayload.any.signaled) == "boolean") then
        -- Destroy the flag and return it
        flag:Delete()
        
        worldGlobals.CTFSetFlagHolder(nil)
        worldGlobals.NanoVS_CTFPerformFlagReturn()
        
        return
      end
      
      local player = pickEvtPayload.any.signaled:GetPicker()
      local team = worldGlobals.NanoVS_CTFPlayerData[player:GetPlayerId()].Team
      local oppositeTeam = worldGlobals.NanoVS_CTFGetOppositeTeam(team)
      
      
      worldGlobals.CTFAnnounceToTeam("TheirTeamTookFlag", oppositeTeam)
      worldGlobals.CTFAnnounceToTeam("YourTeamTookFlag", team)  
          
      worldGlobals.CTFSetFlagHolder(player)
      worldGlobals.NanoVS_CTFStalkFlagHolder(player)        
    end
  )
end

-- composite : CCompositeEntity
-- flagDetector : CDetectorAreaEntity
-- flagModel : CStaticModelEntity
worldGlobals.NanoVS_CTFHandleTeamBase = function(composite, team)
  print("[CTF] Found composite for " .. team)
  local flagDetector = composite:GetPartEntity("FlagDetector")
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
      
      local playerTeam = worldGlobals.NanoVS_CTFPlayerData[player:GetPlayerId()].Team
      
      -- If the player is the flag holder, and they're not on this team
      -- then they capped the flag.
      if (playerTeam ~= team and flagHolder == player) then
        worldGlobals.CTFSetFlagHolder(nil)
        worldInfo:AddScore(1, player)
        
        -- Award the player a flag cap
        local id = player:GetPlayerId()
        worldGlobals.NanoVS_CTFPlayerData[id].Caps = worldGlobals.NanoVS_CTFPlayerData[id].Caps + 1
        
        worldGlobals.CTFSpawnItemFromTemplateForTeam("TeamCappedFlag", oppositeTeam)
        worldGlobals.CTFSpawnItemFromTemplateForTeam("EnemyCappedFlag", team)
        worldGlobals.NetPerformAnnouncement(oppositeTeam .. "TeamScores")
        
        SignalEvent("RespawnFlag")
        
        worldGlobals.NanoVS_CTFRecalculateTeamScorage()
      end
      
      Wait(Delay(0.1))
      flagDetector:Recharge()
    end
  )
end

worldGlobals.NanoVS_CTFHandleGenericFlag = function(composite)
  print("[CTF] Found generic flag composite.")
  local flagDetector = composite:GetPartEntity("FlagDetector")
  local flagModel = composite:GetPartEntity("Flag")
  
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
      
      if (not flagTaken) then
        worldGlobals.CTFSetFlagHolder(player)
        flagModel:Disappear()
        
        local team = worldGlobals.NanoVS_CTFPlayerData[player:GetPlayerId()].Team
        local oppositeTeam = worldGlobals.NanoVS_CTFGetOppositeTeam(team)
        
        worldGlobals.CTFAnnounceToTeam("TheirTeamTookFlag", oppositeTeam)
        worldGlobals.CTFAnnounceToTeam("YourTeamTookFlag", team)
        
        worldGlobals.NanoVS_CTFStalkFlagHolder(player)
        flagTaken = true
      end
      
      Wait(Delay(0.1))
      flagDetector:Recharge()
    end,
    
    OnEvery(CustomEvent("RespawnFlag")),
    function()
      flagTaken = false
      flagModel:Appear()
    end
  )
end

worldGlobals.NanoVS_CTFRunFlagBaseLogic()
worldGlobals.NanoVS_CTFRunPlayerTeamAssignLogic()