-- Serious Damage handler for Nano's VS
-- nano / March 2021

-- worldInfo : CWorldInfoEntity
local worldInfo = worldGlobals.worldInfo

-- player : CPlayerPuppetEntity
worldGlobals.CreateRPC("server", "reliable", "NetSetAmbientLight",
  function(player, ambient)
    player:SetAmbientBias(ambient)
  end
)

if not worldGlobals.netIsHost then return end

local seriousDamageDelay = 40
local seriousDamageAmbientBias = mthVector3f(10, 1, 0)
local defaultAmbientBiases = {}
local seriousDamageSpawners = worldInfo:GetAllEntitiesOfClass("CGenericPowerUpItemEntity")

-- seriousDamageSpawner : CGenericPowerUpItemEntity
local HandleSeriousDamage = function(seriousDamageSpawner)
  RunAsync(
    function()
      while true do
        local pickedEvtPayload = Wait(Event(seriousDamageSpawner.Picked))
        local player = pickedEvtPayload:GetPicker()
        
        worldGlobals.NetPerformAnnouncement("SeriousDamage")
        
        if (defaultAmbientBiases[player:GetPlayerId()] == nil) then
          defaultAmbientBiases[player:GetPlayerId()] = player:GetAmbientBias()
        end
        
        worldGlobals.NetSetAmbientLight(player, seriousDamageAmbientBias)
        worldGlobals.NanoVS_SDWaitForPlayerToRunOut(player)
      end
    end
  )
end

worldGlobals.NanoVS_SDWaitForPlayerToRunOut = function(player)
  RunAsync(
    function()
      Wait(Any(Event(player.Died), Delay(seriousDamageDelay)))
      worldGlobals.NetSetAmbientLight(player, defaultAmbientBiases[player:GetPlayerId()])
    end
  )
end

-- itemParams : CGenericPowerUpItemParams
for i = 1, #seriousDamageSpawners, 1 do
  local seriousDamageSpawner = seriousDamageSpawners[i]
  
  local itemParams = seriousDamageSpawner:GetItemParams()
  if (string.find(itemParams:GetFileName(), "SeriousDamage") ~= nil) then
    HandleSeriousDamage(seriousDamageSpawner)
  end
end