-- My Burden helper
-- nano / March 2021

-- worldInfo : CWorldInfoEntity
local worldInfo = worldGlobals.worldInfo
local nowhere = mthQuatVect(mthHPBToQuaternion(0, 0, 0), mthVector3f(-1000, -1000, -1000))

-- THESE PARAMS CAN BE CHANGED BY THE MAPPER --
worldGlobals.NanoVS_MyBurdenScoreAwarded = worldGlobals.NanoVS_MyBurdenScoreAwarded or 1
worldGlobals.NanoVS_MyBurdenDelay = worldGlobals.NanoVS_MyBurdenDelay or 0.1
local burdenTemplatePath = worldGlobals.NanoVS_BurdenTemplatePath or "Content/Shared/Presets/Templates/NanoVS/MyBurden.rsc"

-- myBurdenTemplate : CTemplatePropertiesHolder
local currentBurdenHolder = nil
local myBurdenTemplate = LoadResource(burdenTemplatePath)
local timeSinceLastAward = 0

local playerScores = {}
local highestScoreSoFar = -999
local highestScoreHolder = nil

-- currentBurdenHolder : CPlayerPuppetEntity
-- burdenPfx : CParticleEffectEntity
local burdenPfx = myBurdenTemplate:SpawnEntityFromTemplate(0, worldInfo, nowhere)

worldGlobals.CreateRPC("server", "reliable", "NetSetBurdenHolder",
  function(player)
    currentBurdenHolder = player
  end
)

RunAsync(
  function()
    while true do
      -- step : COnStepScriptEvent 
      local step = Wait(CustomEvent("OnStep"))
      if (currentBurdenHolder ~= nil) then
        -- Progress time for awarding
        timeSinceLastAward = timeSinceLastAward + step:GetTimeStep()
        
        local pos = currentBurdenHolder:GetPlacement():GetVect()
        local height = currentBurdenHolder:GetBoundingBoxSize()
        
        local newPos = mthQuatVect(mthHPBToQuaternion(0, 0, 0), mthVector3f(pos.x, pos.y + height.y, pos.z))
        burdenPfx:SetPlacement(newPos)
        
        -- If we're the host, award score.
        if worldGlobals.netIsHost and timeSinceLastAward >= worldGlobals.NanoVS_MyBurdenDelay then
          local playerId = currentBurdenHolder:GetPlayerId()
          playerScores[playerId] = playerScores[playerId] + worldGlobals.NanoVS_MyBurdenScoreAwarded
          worldInfo:AddScore(worldGlobals.NanoVS_MyBurdenScoreAwarded, currentBurdenHolder)
          
          if (playerScores[playerId] > highestScoreSoFar) then
            -- Check if we aren't the current highest score holder
            -- if that's the case, announce it to ourselves
            if (highestScoreHolder ~= currentBurdenHolder) then
              -- If the previous score holder was a person
              -- we need to let them know they lost
              if (highestScoreHolder ~= nil) then
                worldGlobals.NetPerformTargettedAnnouncement(highestScoreHolder, "LostTheLead")
              end
              
              worldGlobals.NetPerformTargettedAnnouncement(currentBurdenHolder, "TakenTheLead")
              highestScoreHolder = currentBurdenHolder
            end
            
            highestScoreSoFar = playerScores[playerId]
          end
          timeSinceLastAward = 0
        end
      else
        burdenPfx:SetPlacement(nowhere)
        timeSinceLastAward = 0
      end
    end
  end
)

if not worldGlobals.netIsHost then return end

local scoreFeedingItem
local originalScoreFeederPos

worldGlobals.NanoVS_MBStalkPlayer = function(player)
  RunAsync(
    function()
      local playerId = player:GetPlayerId()
      if (playerScores[playerId] == nil) then
        playerScores[playerId] = 0
      end
    
      Wait(Event(player.Died))
      
      -- First, figure out where the item should drop
      local hEn, hVec = CastRay(worldInfo, player, player:GetPlacement():GetVect(), mthVector3f(0, -1, 0), 1000, 0, "bullet")
      
      local spawnPos
      
      -- If the hit entity handle is nil, then we should respawn
      -- on the original placement
      if (hEn ~= nil) then
        spawnPos = mthQuatVect(originalScoreFeederPos:GetQuat(), hVec)
      -- Otherwise we're clear to spawn there
      else
        spawnPos = originalScoreFeederPos
      end
      
      local feeder = myBurdenTemplate:SpawnEntityFromTemplate(1, worldInfo, spawnPos)
      RunAsync(
        function()
          worldGlobals.NanoVS_MBWaitForItemPicked(feeder)
        end
      )
      worldGlobals.NetSetBurdenHolder(nil)
    end
  )
end

worldGlobals.NanoVS_MBWaitForItemPicked = function(scoreFeeder)
  local pickedEvtPayload = Wait(Event(scoreFeeder.Picked))
  local picker = pickedEvtPayload:GetPicker()
    
  worldGlobals.NetSetBurdenHolder(picker)
  worldGlobals.NanoVS_MBStalkPlayer(picker)
end

-- Get the score feeder
-- scoreFeedingItem : CGenericItemEntity
local scoreFeederPos = worldInfo:GetAllEntitiesOfClassAndName("CPathMarkerEntity", "BurdenSpawnPos")[1]
originalScoreFeederPos = scoreFeederPos:GetPlacement()

local scoreFeedingItem = myBurdenTemplate:SpawnEntityFromTemplate(1, worldInfo, originalScoreFeederPos)

worldGlobals.NanoVS_MBWaitForItemPicked(scoreFeedingItem)