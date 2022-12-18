-- Bootstrap for nano's Versus
-- nano / March 2021

-- worldInfo : CWorldInfoEntity
local worldInfo = worldGlobals.worldInfo
local gamemode = worldInfo:GetGameMode()

-- Hashmap containing all of the executed lua scripts for a gamemode
local includesForGamemodes = {
  Deathmatch = {"Content/Shared/Scripts/nanoVS/WeaponDropHelper.lua", "Content/Shared/Scripts/nanoVS/AnnouncerSounds.lua", "Content/Shared/Scripts/nanoVS/SeriousDamage.lua", "Content/Shared/Scripts/nanoVS/PlayerHelpers.lua"},
  InstantKill = {"Content/Shared/Scripts/nanoVS/AnnouncerSounds.lua", "Content/Shared/Scripts/nanoVS/InstantKill.lua", "Content/Shared/Scripts/nanoVS/SeriousDamage.lua", "Content/Shared/Scripts/nanoVS/PlayerHelpers.lua"},
  MyBurden = {"Content/Shared/Scripts/nanoVS/WeaponDropHelper.lua", "Content/Shared/Scripts/nanoVS/AnnouncerSounds.lua", "Content/Shared/Scripts/nanoVS/MyBurden.lua", "Content/Shared/Scripts/nanoVS/SeriousDamage.lua", "Content/Shared/Scripts/nanoVS/PlayerHelpers.lua"},
  LastManStanding = {"Content/Shared/Scripts/nanoVS/WeaponDropHelper.lua", "Content/Shared/Scripts/nanoVS/AnnouncerSounds.lua", "Content/Shared/Scripts/nanoVS/SeriousDamage.lua", "Content/Shared/Scripts/nanoVS/PlayerHelpers.lua"},
  TeamDeathmatch = {"Content/Shared/Scripts/nanoVS/WeaponDropHelper.lua", "Content/Shared/Scripts/nanoVS/AnnouncerSounds.lua", "Content/Shared/Scripts/nanoVS/SeriousDamage.lua", "Content/Shared/Scripts/nanoVS/PlayerHelpers.lua"},
  CaptureTheFlag = {"Content/Shared/Scripts/nanoVS/TeamHelper.lua", "Content/Shared/Scripts/nanoVS/TeamIndicators.lua", "Content/Shared/Scripts/nanoVS/GameEndHelper.lua", "Content/Shared/Scripts/nanoVS/AnnouncerSounds.lua", "Content/Shared/Scripts/nanoVS/CaptureTheFlag.lua", "Content/Shared/Scripts/nanoVS/PlayerHelpers.lua", "Content/Shared/Scripts/nanoVS/ThirdPersonHelper.lua"},
  OneFlagCTF = {"Content/Shared/Scripts/nanoVS/TeamHelper.lua", "Content/Shared/Scripts/nanoVS/TeamIndicators.lua", "Content/Shared/Scripts/nanoVS/GameEndHelper.lua", "Content/Shared/Scripts/nanoVS/AnnouncerSounds.lua", "Content/Shared/Scripts/nanoVS/OneFlagCTF.lua", "Content/Shared/Scripts/nanoVS/PlayerHelpers.lua", "Content/Shared/Scripts/nanoVS/ThirdPersonHelper.lua"}
}

-- Do all of the included files
local includes = includesForGamemodes[gamemode]
if (includes ~= nil) then
  conInfoF("[nano's VS] Bootstrapping " .. tostring(#includes) .. " script(s) for gamemode: '" .. gamemode .. "'\n")
  
  local settingsFile = "Content/Shared/Scripts/nanoVS/Settings/" .. gamemode .. "_Settings.lua"
  if (scrFileExists(settingsFile)) then
    conInfoF("[nano's VS] Loading gamemode settings.\n")
    dofile(settingsFile)
  else
    conErrorF("[nano's VS] Bootstrap couldn't find settings file for '" .. gamemode .. "'! This shouldn't happen on gamemodes from the official pack")
  end
  
  local scriptName = string.gsub(worldInfo:GetWorldFileName(), ".wld", "") .. "_config.lua"
  
  if scrFileExists(scriptName) then
    conInfoF("[nano's VS] Found config file for this world, processing.\n")
    dofile(scriptName)
  else
    conInfoF("[nano's VS] No config file found for this world, this is fine.\n")
  end
  
  for i = 1, #includes, 1 do
    RunAsync(
      function()
        dofile(includes[i])
      end
    )
  end
end