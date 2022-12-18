-- Announcer sounds for VS gamemodes
-- nano / March 2021

-- worldInfo : CWorldInfoEntity
-- player : CPlayerPuppetEntity
local worldInfo = worldGlobals.worldInfo

local doubleKillMax = 4.00
local fiveMinutes = 5 * 60
local oneMinute = 1 * 60

-- Hell
local announcementTable = {
  OneFragLeft = LoadResource(worldGlobals.NanoVS_AnnouncerOneFragLeft or "Content/Shared/Sounds/NanoVS/OneFragLeft.ogg"),
  TwoFragsLeft = LoadResource(worldGlobals.NanoVS_AnnouncerTwoFragsLeft or "Content/Shared/Sounds/NanoVS/TwoFragsLeft.ogg"),
  ThreeFragsLeft = LoadResource(worldGlobals.NanoVS_AnnouncerThreeFragsLeft or "Content/Shared/Sounds/NanoVS/ThreeFragsLeft.ogg"),
  YouWon = LoadResource(worldGlobals.NanoVS_AnnouncerYouWon or "Content/Shared/Sounds/NanoVS/YouWon.ogg"),
  
  FiveMinutesLeft = LoadResource(worldGlobals.NanoVS_AnnouncerFiveMinutesLeft or "Content/Shared/Sounds/NanoVS/FiveMinutesLeft.ogg"),
  OneMinuteLeft = LoadResource(worldGlobals.NanoVS_AnnouncerOneMinuteLeft or "Content/Shared/Sounds/NanoVS/OneMinuteLeft.ogg"),
  One = LoadResource(worldGlobals.NanoVS_AnnouncerOne or "Content/Shared/Sounds/NanoVS/One.ogg"),
  Two = LoadResource(worldGlobals.NanoVS_AnnouncerTwo or "Content/Shared/Sounds/NanoVS/Two.ogg"),
  Three = LoadResource(worldGlobals.NanoVS_AnnouncerThree or "Content/Shared/Sounds/NanoVS/Three.ogg"),  
  
  LostTheLead = LoadResource(worldGlobals.NanoVS_AnnouncerLostTheLead or "Content/Shared/Sounds/NanoVS/LostTheLead.ogg"), 
  TakenTheLead = LoadResource(worldGlobals.NanoVS_AnnouncerTakenTheLead or "Content/Shared/Sounds/NanoVS/TakenTheLead.ogg"),
  TiedForALead = LoadResource(worldGlobals.NanoVS_AnnouncerTiedForALead or "Content/Shared/Sounds/NanoVS/TiedForALead.ogg"),
  
  SeriousDamage = LoadResource(worldGlobals.NanoVS_AnnouncerSeriousDamage or "Content/Shared/Sounds/NanoVS/SeriousDamage.wav"),
  
  TeamCappedFlag = LoadResource(worldGlobals.NanoVS_AnnouncerTeamCappedFlag or "Content/Shared/Sounds/NanoVS/flagcapture_yourteam.wav"),
  EnemyCappedFlag = LoadResource(worldGlobals.NanoVS_AnnouncerEnemyCappedFlag or "Content/Shared/Sounds/NanoVS/flagcapture_opponent.wav"),
  
  YourFlagReturned = LoadResource(worldGlobals.NanoVS_AnnouncerYourFlagReturned or "Content/Shared/Sounds/NanoVS/flagreturn_yourteam.wav"),
  TheirFlagReturned = LoadResource(worldGlobals.NanoVS_AnnouncerTheirFlagReturned or "Content/Shared/Sounds/NanoVS/flagreturn_opponent.wav"),
  
  YourTeamTookFlag = LoadResource(worldGlobals.NanoVS_AnnouncerYourFlagReturned or "Content/Shared/Sounds/NanoVS/flagtaken_yourteam.wav"),
  TheirTeamTookFlag = LoadResource(worldGlobals.NanoVS_AnnouncerTheirFlagReturned or "Content/Shared/Sounds/NanoVS/flagtaken_opponent.wav"),  
  
  RedFlagReturned = LoadResource(worldGlobals.NanoVS_AnnouncerRedFlagReturned or "Content/Shared/Sounds/NanoVS/RedFlagReturned.ogg"),
  BlueFlagReturned = LoadResource(worldGlobals.NanoVS_AnnouncerBlueFlagReturned or "Content/Shared/Sounds/NanoVS/BlueFlagReturned.ogg"),    
  
  YouHaveTheirFlag = LoadResource(worldGlobals.NanoVS_AnnouncerYouHaveTheirFlag or "Content/Shared/Sounds/NanoVS/YouHaveTheirFlag.ogg"),
  TheyHaveYourFlag = LoadResource(worldGlobals.NanoVS_AnnouncerTheyHaveYourFlag or "Content/Shared/Sounds/NanoVS/TheyHaveYourFlag.ogg"),
  
  BlueTeamScores = LoadResource(worldGlobals.NanoVS_AnnouncerBlueTeamScores or "Content/Shared/Sounds/NanoVS/BlueTeamScores.ogg"),
  RedTeamScores = LoadResource(worldGlobals.NanoVS_AnnouncerRedTeamScores or "Content/Shared/Sounds/NanoVS/RedTeamScores.ogg"),
  
  BlueTeamWon = LoadResource(worldGlobals.NanoVS_AnnouncerBlueTeamWon or "Content/Shared/Sounds/NanoVS/BlueTeamWon.ogg"),
  RedTeamWon = LoadResource(worldGlobals.NanoVS_AnnouncerRedTeamWon or "Content/Shared/Sounds/NanoVS/RedTeamWon.ogg")  
}

worldGlobals.CreateRPC("server", "reliable", "NetPerformAnnouncement",
  function(announcementName)
    worldInfo:Announce(announcementTable[announcementName])
  end
)

worldGlobals.CreateRPC("server", "reliable", "NetPerformTargettedAnnouncement",
  function(player, announcementName)
    if (player:IsLocalViewer()) then
      worldInfo:Announce(announcementTable[announcementName])
    end
  end
)

worldGlobals.NanoVS_DoLocalAnnouncement = function(announcementName)
  worldInfo:Announce(announcementTable[announcementName])
end

if not worldGlobals.netIsHost then return end

local timeSinceStart = 0
local lastTimeLeftNotif = 99999999
local previousTop = nil
local previousTopScore = -9999
local playerData = {}
local lastTiedCount = 0
local lastTiedPlayers = {}

local ConstructPlayerDataFor = function(player)
  print("Constructing player data...")
  local id = player:GetPlayerId()
  
  playerData[id] = {
    lastKillAt = 0,
    killCount = 0,
    doubleKillOnCooldown = false,
    pointer = player
  }
  
  -- Construct a player stalker
  RunAsync(
    function()
      RunHandled(
        function()
          while not IsDeleted(player) do
            Wait(CustomEvent("OnStep"))
          end
        end,
        
        -- playerDiedEvt : CDiedScriptEvent
        OnEvery(Event(player.Died)),
        function(playerDiedEvt)
          local killerPlayer = playerDiedEvt:GetKillerPlayer()
          
          worldGlobals.NanoVS_OnKilledHandler(player, killerPlayer, timeSinceStart)
        end
      )
    end
  )
end

worldGlobals.NanoVS_OnKilledHandler = function(player, killer, timestamp)
  local playerId = player:GetPlayerId()
  
  if (killer ~= nil and player ~= killer) then
    local killerId = killer:GetPlayerId()
    playerData[killerId].killCount = playerData[killerId].killCount + 1
    
    if (playerData[killerId].killCount > 1 and 
       (timestamp - playerData[killerId].lastKillAt) <= doubleKillMax and
       not playerData[killerId].doubleKillOnCooldown) then
       
       worldGlobals.NetPerformTargettedAnnouncement(killer, "MultiKill")
       playerData[killerId].doubleKillOnCooldown = true
       
       -- Enable the cooldown coroutine
       RunAsync(
         function()
           Wait(Delay(5.00))
           playerData[killerId].doubleKillOnCooldown = false
         end
       )
    end
    
    local fragLimit = plpGetProfileLong("NanoVSFragLimit")
    
    if (fragLimit > 0 and playerData[killerId].killCount >= previousTopScore) then
      local fragsLeft = fragLimit - playerData[killerId].killCount
      
      if (fragsLeft == 3) then
        worldGlobals.NetPerformAnnouncement("ThreeFragsLeft")
      elseif (fragsLeft == 2) then
        worldGlobals.NetPerformAnnouncement("TwoFragsLeft")
      elseif (fragsLeft == 1) then
        worldGlobals.NetPerformAnnouncement("OneFragLeft")
      elseif (fragsLeft == 0) then
        worldGlobals.NetPerformTargettedAnnouncement(killer, "YouWon")
      end
    end
    
    playerData[killerId].lastKillAt = timestamp
  else -- If the killer isn't a player, just assume the player killed themselves.
    playerData[playerId].killCount = playerData[playerId].killCount - 1
  end
  
  worldGlobals.NanoVS_ANSortTable()
end

worldGlobals.NanoVS_ANSortTable = function()
  local top = -999999
  local topPlayer = 0
  local tiedPlayers = {}
  for id, data in pairs(playerData) do
    if (data.killCount > top) then
      top = data.killCount
      topPlayer = data.pointer
      
      -- Reset the list of tied players
      tiedPlayers = {}
      lastTiedPlayers = {}
      
    -- If the kill count is the same as the current top value, just mark the player as tied
    elseif (data.killCount == top) then
      table.insert(tiedPlayers, data.pointer)
    end
  end
  
  if (top ~= previousTopScore) then
    if (previousTop ~= nil and previousTop ~= topPlayer and #tiedPlayers < 2) then
      worldGlobals.NetPerformTargettedAnnouncement(previousTop, "LostTheLead")
      worldGlobals.NetPerformTargettedAnnouncement(topPlayer, "TakenTheLead")
    end
    
    if (#tiedPlayers > 1) then
      for i = 1, #tiedPlayers, 1 do
        worldGlobals.NetPerformTargettedAnnouncement(tiedPlayers[i], "TiedForALead")
      end
    end
    
    previousTopScore = top
    previousTop = topPlayer
  else
    if (#tiedPlayers > 1 and #tiedPlayers ~= lastTiedCount) then
      for i = 1, #tiedPlayers, 1 do
        -- Only send that to players who haven't been notified before that they've been tied
        -- for the lead.
        if (lastTiedPlayers[tiedPlayers[i]:GetPlayerId()] == nil) then
          worldGlobals.NetPerformTargettedAnnouncement(tiedPlayers[i], "TiedForALead")
          lastTiedPlayers[tiedPlayers[i]:GetPlayerId()] = true
        end
      end
      
      lastTiedCount = #tiedPlayers
    end
  end
end

RunHandled(
  function()
    WaitForever()
  end,
  
  -- bornEvtPayload : CPlayerBornScriptEvent
  
  OnEvery(CustomEvent("ClientConnected")),
  function(player)
    if (worldGlobals.NanoVS_AnnouncerSettings["FragCounter"] == true) then
      ConstructPlayerDataFor(player)
    end
  end,
  
  -- delta : COnStepScriptEvent
  OnEvery(CustomEvent("OnStep")),
  function(delta)
    timeSinceStart = timeSinceStart + delta:GetTimeStep()
    
    local timeLimit = plpGetProfileLong("NanoVSTimeLimit") * 60
    
    if (timeLimit > 0 and worldGlobals.NanoVS_AnnouncerSettings["Time"] == true) then
      local timeLeft = timeLimit - timeSinceStart
    
      if (timeLeft <= fiveMinutes and lastTimeLeftNotif > fiveMinutes) then
        worldGlobals.NetPerformAnnouncement("FiveMinutesLeft")
        lastTimeLeftNotif = fiveMinutes
      elseif (timeLeft <= oneMinute and lastTimeLeftNotif > oneMinute) then
        worldGlobals.NetPerformAnnouncement("OneMinuteLeft")
        lastTimeLeftNotif = oneMinute     
      elseif (timeLeft <= 3 and lastTimeLeftNotif > 3) then
        worldGlobals.NetPerformAnnouncement("Three")
        lastTimeLeftNotif = 3         
      elseif (timeLeft <= 2 and lastTimeLeftNotif > 2) then
        worldGlobals.NetPerformAnnouncement("Two")
        lastTimeLeftNotif = 2         
      elseif (timeLeft <= 1 and lastTimeLeftNotif > 1) then
        worldGlobals.NetPerformAnnouncement("One")
        lastTimeLeftNotif = 1             
      end
    end
  end
)