if not game:IsLoaded() then
  game.Loaded:Wait()
end

local HttpService = game:GetService("HttpService")
local WebSocketInstance = nil

local function log(msg)
  print("[WebSocket] " .. msg)
end

game:GetService("LogService").MessageOut:Connect(function(message, messageType)
  if WebSocketInstance then
    WebSocketInstance:Send(HttpService:JSONEncode({
      type = "log",
      data = {
        message = message,
        type = messageType.Value
      }
    }))
  end
end)

game:GetService("ScriptContext").ErrorDetailed:Connect(function(message, stackTrace, script, details, securityLevel)
  if WebSocketInstance then
    WebSocketInstance:Send(HttpService:JSONEncode({
      type = "detailed_error",
      data = {
        message = message,
        stackTrace = stackTrace,
        details = details,
        securityLevel = securityLevel,
      }
    }))
  end
end)

local function connect()
  WebSocketInstance = ((syn and syn.websocket) or WebSocket).connect("ws://localhost:42121")
  
  local localPlayer = game:GetService("Players").LocalPlayer
  WebSocketInstance:Send(HttpService:JSONEncode({
    type = "connect",
    data = {
      displayName = localPlayer.DisplayName,
      name = localPlayer.Name
    }
  }))

  WebSocketInstance.OnMessage:Connect(function(msg)
    local success, json = pcall(function() return HttpService:JSONDecode(msg) end)
    if success then
      if json.type == "run_luas" then
        for _, lua in pairs(json.data.luas) do
          pcall(loadstring(lua))
        end
      end
    else
      log("Failed to parse JSON: " .. tostring(msg))
    end
  end)

  WebSocketInstance.OnClose:Connect(function()
    WebSocketInstance = nil
    log("WebSocket closed")
  end)
end

while true do
  if not WebSocketInstance then
    local success, err = pcall(connect)
    if not success then
      log("Connection error: " .. tostring(err))
    end
  end
  task.wait(1)
end
