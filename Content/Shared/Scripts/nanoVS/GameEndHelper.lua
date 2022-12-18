-- Helper for ending a game
-- nano / March 2021, January 2022

-- This script used to be much simpler, but Croteam is Croteam
-- and decided that samEndMultiplayerGame() has to be locked
-- behind cheats. So now, we need to simulate that ourselves!
-- \(^o^)/

-- Helper for bringing up the player list.
worldGlobals.NanoVS_ShowPlayerList = function()
  -- player : CPlayerPuppetEntity
  local player = worldGlobals.NanoVS_GetLocalPlayer()
  player:BlockAllCommandsExcept("plcmdQuickSaveTogglePlayerList")
  local counter = 0
  
  while counter < 5 do
    -- We need to set it every couple of seconds because 
    -- for some reason CT does not want you to open the
    -- player list when you have the sprint button pressed.
    -- EVEN IF the command is disabled.
    inpSetCommandValue("plcmdQuickSaveTogglePlayerList", 1)
    Wait(Delay(0.1))
    counter = counter + 0.1
    
    if (counter > 1) then
      player:UnblockAllCommands()
    end
  end
end

worldGlobals.CreateRPC("server", "reliable", "ForceShowPlayerList",
  function()
    RunAsync(
      function()
        worldGlobals.NanoVS_ShowPlayerList()
      end
    )
  end
)

worldGlobals.NanoVS_ForceEndMatch = function()
  worldGlobals.ForceShowPlayerList()

  RunAsync(
    function()
      -- Wait a bit before actually telling the game to progress
      -- We want to show the scoreboard like in other sam games first.
      Wait(Delay(5))
      
      -- Hand selected constant, cute and funny
      SetGlobalData(2420727)
    end
  )
end