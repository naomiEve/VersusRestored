-- Helper script that spawns weapon drops for weapons that don't have them set up
-- nano / March 2021

if not worldGlobals.netIsHost then return end

-- worldInfo : CWorldInfoEntity
-- itemTemplate : CTemplatePropertiesHolder
local worldInfo = worldGlobals.worldInfo
local itemTemplate = LoadResource("Content/Shared/Presets/Templates/NanoVS/Sam4DefaultWeaponDrops.rsc")
local players = {}
local playerHeldWeapon = {}
local downVect = mthVector3f(0, -1, 0)

-- player : CPlayerPuppetEntity
local SpawnOnDeath = function(player)
  RunAsync(
    function()
      while not IsDeleted(player) do
        Wait(Event(player.Died))
        local playerId = player:GetPlayerId()
        local playerPlacement = player:GetPlacement()
        
        -- Get the Y position at the bottom, so we can prevent entities being stuck in mid air
        local hHen, hVec = CastRay(worldInfo, player, playerPlacement:GetVect(), downVect, 10000, 0, "bullet")        

        if (playerHeldWeapon[playerId].Left ~= nil) then
          local leftPlacement = mthCloneQuatVect(playerPlacement)
          local leftVect = leftPlacement:GetVect()
          
          leftVect.x = leftVect.x + mthRndRangeL(-1, 1)
          leftVect.z = leftVect.z + mthRndRangeL(-1, 1)
          leftVect.y = hVec.y
          leftPlacement:SetVect(leftVect)
          
          itemTemplate:SpawnEntityFromTemplateByName(playerHeldWeapon[playerId].Left, worldInfo, leftPlacement)
        end
        
        if (playerHeldWeapon[playerId].Right ~= nil) then  
          local rightPlacement = mthCloneQuatVect(playerPlacement)
          local rightVect = rightPlacement:GetVect()
          
          rightVect.x = rightVect.x + mthRndRangeL(-1, 1)
          rightVect.z = rightVect.z + mthRndRangeL(-1, 1)
          rightVect.y = hVec.y
          rightPlacement:SetVect(rightVect)
                    
          itemTemplate:SpawnEntityFromTemplateByName(playerHeldWeapon[playerId].Right, worldInfo, rightPlacement)
        end        
      end
    end
  )
end

RunHandled(
  function()
    WaitForever()
  end,
  
  OnEvery(CustomEvent("OnStep")),
  function()
    -- Make sure we don't get the players every frame, but only
    -- when the list actually updates
    if (#players ~= worldInfo:GetPlayersCount()) then
      players = worldInfo:GetAllPlayersInRange(worldInfo, 10000)
    end
    
    for i = 1, #players, 1 do
      local player = players[i]
      
      if player:IsAlive() then
        local playerId = player:GetPlayerId()
      
        -- Construct the weapon array only once
        if (playerHeldWeapon[playerId] == nil) then
          -- Accomodate for both left and right weapons
          -- Who knows what people will want to do in MP
          playerHeldWeapon[playerId] = {
            Left = nil,
            Right = nil
          }
          
          SpawnOnDeath(player)
        end
      
        local rightWeapon = player:GetRightHandWeapon()
        if (rightWeapon ~= nil) then
          local params = rightWeapon:GetParams()
          local paramsName = params:GetName()
          
          if (playerHeldWeapon[playerId].Right ~= paramsName) then
            playerHeldWeapon[playerId].Right = paramsName
          end
        else
          playerHeldWeapon[playerId].Right = nil
        end
      
        local leftWeapon = player:GetLeftHandWeapon()
        if (leftWeapon ~= nil) then
          local params = leftWeapon:GetParams()
          local paramsName = params:GetName()
          
          if (playerHeldWeapon[playerId].Left ~= paramsName) then
            playerHeldWeapon[playerId].Left = paramsName
          end
        else
          playerHeldWeapon[playerId].Left = nil
        end
      end
    end
  end
)