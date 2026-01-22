-- Chat Command Bot
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local OWNER_USERNAME = "USER_NAME_HERE" -- Replace with owner's username
local MainEvent = ReplicatedStorage:WaitForChild("MainEvent")

-- Configuration
local SaveLocations = {
    bank = Vector3.new(-440, 38, -289),
    military = Vector3.new(37, 25, -892),
    revolver = Vector3.new(-639, 21, -125),
    tactical = Vector3.new(481, 48, -623),
    warehouse = Vector3.new(480, 47, -83),
    school = Vector3.new(-607, 21, 217),
    playground = Vector3.new(-271, 22, -759),
    gym = Vector3.new(-76, 23, -641),
    casino = Vector3.new(-891, 22, -68),
    -- Add more locations as needed
}

-- Helpers
local function levenshtein(str1, str2)
    local len1, len2 = #str1, #str2
    local matrix = {}
    
    for i = 0, len1 do matrix[i] = {[0] = i} end
    for j = 0, len2 do matrix[0][j] = j end
    
    for i = 1, len1 do
        for j = 1, len2 do
            local cost = (str1:sub(i, i) == str2:sub(j, j)) and 0 or 1
            matrix[i][j] = math.min(
                matrix[i-1][j] + 1,
                matrix[i][j-1] + 1,
                matrix[i-1][j-1] + cost
            )
        end
    end
    return matrix[len1][len2]
end

local function Get_Player(name)
    local lowerName = string.lower(name)
    local bestMatch, bestScore = nil, math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        local userName = string.lower(player.Name)
        local displayName = string.lower(player.DisplayName)
        
        -- Exact prefix match
        if userName:find(lowerName, 1, true) == 1 then return player end
        if displayName:find(lowerName, 1, true) == 1 then return player end
        
        -- Fuzzy match
        local distance = math.min(levenshtein(lowerName, userName), levenshtein(lowerName, displayName))
        if distance < bestScore and distance <= 3 then
            bestMatch, bestScore = player, distance
        end
    end
    return bestMatch
end

local function ParseArgs(message, prefix)
    local command = message:match("^" .. prefix .. "(%S+)")
    local argString = message:match("^" .. prefix .. "%S+%s+(.+)") or ""
    
    local args = {}
    for arg in argString:gmatch("[^,%s]+") do
        table.insert(args, arg)
    end
    return command, args, argString
end

local function IsKO(player)
    if not player.Character then return false end
    local bodyEffects = player.Character:FindFirstChild("BodyEffects")
    if bodyEffects and bodyEffects:FindFirstChild("K.O") then
        return bodyEffects["K.O"].Value
    end
    return false
end

local function IsDead(player)
    if not player.Character then return false end
    local bodyEffects = player.Character:FindFirstChild("BodyEffects")
    if bodyEffects and bodyEffects:FindFirstChild("Dead") then
        return bodyEffects["Dead"].Value
    end
    return false
end

-- Actions
local function TeleportToLocation(name)
    local pos = SaveLocations[name:lower()]
    if pos then 
        if api and api.teleport then
            api:teleport(CFrame.new(pos)) 
        else
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
        end
    end
end

local function WhitelistOwner()
    local owner = Players:FindFirstChild(OWNER_USERNAME)
    if owner and api then
        local whitelist = api:get_ui_object("ragebot_whitelist"):GetValue() or {}
        table.insert(whitelist, owner.Name)
        api:get_ui_object("ragebot_whitelist"):SetValue(whitelist)
    end
end

local function VoidBot(duration)
    if not api then return end
    api:get_ui_object("character_prot_void"):SetValue(true)
    task.wait(duration)
    api:get_ui_object("character_prot_void"):SetValue(false)
end

local function KnockPlayer(targetPlayer)
    if not api then return end
    if IsKO(targetPlayer) then return end
    
    api:get_ui_object("ragebot_targets"):SetValue(targetPlayer.Name)
    api:get_ui_object("ragebot_use_selected"):SetValue(true)
    api:get_ui_object("ragebot_keybind"):OverrideState(true)
    api:set_ragebot(true)
    
    local timeout = 0
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        timeout = timeout + dt
        
        if IsKO(targetPlayer) or IsDead(targetPlayer) or timeout >= 20 then
            api:get_ui_object("ragebot_targets"):SetValue({})
            api:get_ui_object("ragebot_keybind"):OverrideState(false)
            api:set_ragebot(false)
            conn:Disconnect()
        end
    end)
end

local function ReliableBring(targetPlayer)
    if not IsKO(targetPlayer) then return end
    if not api then return end
    
    local stompOffset = 3.5
    local owner = Get_Player(OWNER_USERNAME)
    if not owner then return end

    -- Position above target
    local positionLoop = RunService.Heartbeat:Connect(function()
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("UpperTorso") then
            api:set_desync_cframe(CFrame.new(targetPlayer.Character.UpperTorso.Position + Vector3.new(0, stompOffset, 0)))
        end
    end)
    
    task.wait(0.5)
    
    -- Persistent grab loop
    local grabbed = false
    for i = 1, 60 do
        if targetPlayer.Character:FindFirstChild("GRABBING_CONSTRAINT") then
            grabbed = true
            break
        end
        MainEvent:FireServer("Grabbing")
        task.wait(0.1)
    end
    
    positionLoop:Disconnect()
    
    if grabbed then
        -- Teleport to owner
        local bringPos = owner.Character.HumanoidRootPart.CFrame * CFrame.new(5, 0, 5)
        api:set_desync_cframe(bringPos)
        task.wait(0.5) -- Wait for teleport
        MainEvent:FireServer("Grabbing", false) -- Release
    end
end

local function ExecuteCommand(command, args, rawArgs)
    if command == "tp" and args[1] then
        TeleportToLocation(args[1])
    elseif command == "bring" and args[1] then
        local target = Get_Player(args[1])
        if target then ReliableBring(target) end
    elseif command == "kill" and args[1] then
        local target = Get_Player(args[1])
        if target then KnockPlayer(target) end
    elseif command == "void" then
        VoidBot(tonumber(args[1]) or 2)
    end
end

-- Listener
TextChatService.MessageReceived:Connect(function(msg)
    if msg.TextSource and msg.TextSource.UserId == Players:GetUserIdFromNameAsync(OWNER_USERNAME) then
        local cmd, args, raw = ParseArgs(msg.Text, ".")
        if cmd then
            ExecuteCommand(cmd, args, raw)
        end
    end
end)

api:notify("Chat Bot Loaded", 5)
