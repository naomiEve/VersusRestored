-- Helper script that extracts some data for the VS gamemodes
-- nano / March 2021
RunHandled(
  function()
    WaitForever()
  end, 

  OnEvery(CustomEvent("XML_Log")),
    function(xmlEvtPayload) 
      local line = xmlEvtPayload:GetLine()
      if (line:find("roundstart") ~= nil) then
        local timeLimit  = line:match("goalslimit=\".-\"")
        local fTimeLimit = tonumber(timeLimit:sub(13,-2))
        local fragLimit  = line:match("fraglimit=\".-\"")
        local fFragLimit = tonumber(fragLimit:sub(12,-2))
        local flagLimit  = line:match("timelimit=\".-\"")
        local fFlagLimit = tonumber(flagLimit:sub(12,-2))        
        
        plpSetProfileLong("NanoVSTimeLimit", fTimeLimit)
        plpSetProfileLong("NanoVSFragLimit", fFragLimit)
        plpSetProfileLong("NanoVSFlagLimit", fFlagLimit)
        
        -- TODO(nano): Why is this called only in XML_Log?
        plpSetProfileLong("NanoVSPreferredTP",           prj_iGameOptionPreferredView)
        plpSetProfileLong("NanoVSPreferredVehicleTP",    prj_iGameOptionPreferredRidingView)
      end
    end
)