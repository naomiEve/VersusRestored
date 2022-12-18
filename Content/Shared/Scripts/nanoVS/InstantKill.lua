-- Instant Kill manager
-- nano / March 2021

if (not worldGlobals.netIsHost) then return end

-- worldInfo : CWorldInfoEntity
local worldInfo = worldGlobals.worldInfo
local sniper = LoadResource("Content/SeriousSam4/Databases/Weapons/SniperWeapon.ep")

RunHandled(
  function()
    WaitForever()
  end,
  
  -- evtPayload : CPlayerBornScriptEvent
  -- player : CPlayerPuppetEntity
  OnEvery(Event(worldInfo.PlayerBorn)),
  function(evtPayload)
    local player = evtPayload:GetBornPlayer()
    player:RemoveAllWeapons()
    
    player:AwardWeapon(sniper)
    player:AwardAmmoForWeapon(sniper, 100)
    player:SelectWeapon(sniper)
  end
)