-- Pepper Spray Killer
-- Automatically buys Pepper Spray, glues to target front, locks rotation, and stomps.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local MainEvent = ReplicatedStorage:WaitForChild("MainEvent")

-- Configuration
local Config = {
    Distance = 3, -- Studs in front of target
    StompDelay = 0.25,
    VoidDelay = 3, -- Default
    Debug = false
}

-- State
local IsActive = false
local CurrentParams = nil 
local LastBuyAttempt = 0
local LastStomp = 0
local LockStartTime = 0
local LastTargetId = nil
local IsVoided = false

-- Void Helper
local function SetVoid(bool)
    if api and api.get_ui_object then
        local voidIn = api:get_ui_object("character_prot_void_in")
        local voidOut = api:get_ui_object("character_prot_void_out")
        if voidIn then voidIn:SetValue(bool) end
        if voidOut then voidOut:SetValue(not bool) end
    end
end

-- Logging Helper
local function LogToFile(msg)
    if not Config.Debug then return end
    local timeStr = os.date("%H:%M:%S")
    local logLine = string.format("[%s] %s\n", timeStr, msg)
    
    -- Console Mirror
    print("[PepperDebug] " .. msg)
    
    if appendfile then
        appendfile("pepper_log.txt", logLine)
    elseif writefile and readfile then
        -- Fallback if appendfile missing
        local content = isfile("pepper_log.txt") and readfile("pepper_log.txt") or ""
        writefile("pepper_log.txt", content .. logLine)
    end
end

-- Handler Requirement (assuming it's in the same folder or loaded)
-- If running standalone, we'll implement minimal needed logic inline for portability
-- Helper to get silent aim target
local function GetTarget()
    -- Try to get the current silent aim target from API
    -- Based on user request to "target out silent aim target"
    if api and api.get_target then
        return api:get_target("silent")
    end
    
    -- Fallback to Ragebot target if silent not found or API differs
    if api then
        local uiObj = api:get_ui_object("ragebot_targets")
        if uiObj then
            local val = uiObj.Value
            if type(val) == "string" and val ~= "" then
                return Players:FindFirstChild(val)
            end
        end
    end
    return nil
end

local function Unglue()
    if getgenv().sethiddenproperty and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        sethiddenproperty(LocalPlayer.Character.HumanoidRootPart, "PhysicsRepRootPart", nil)
    end
end

-- Debug Logic
local LastDamageTime = 0
local DamageConnection = nil

local function MonitorDamage(target)
    if DamageConnection then DamageConnection:Disconnect() end
    if not target or not target.Character then return end
    
    local humanoid = target.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local oldHealth = humanoid.Health
    
    DamageConnection = humanoid.HealthChanged:Connect(function(newHealth)
        if newHealth < oldHealth then
            -- Damage Dealt
            local now = tick()
            if LastDamageTime > 0 then
                local diff = now - LastDamageTime
                if Config.Debug then
                     print(string.format("[PepperDebug] Damage Delay: %.4fs", diff))
                     api:notify(string.format("Dmg Delay: %.4fs", diff), 1)
                     LogToFile(string.format("Damage Delay: %.4fs", diff))
                end
            end
            LastDamageTime = now
        end
        oldHealth = newHealth
    end)
end

local function IsKO(player)
    if not player or not player.Character then return false end
    local be = player.Character:FindFirstChild("BodyEffects")
    if not be then return false end
    local ko = be:FindFirstChild("K.O")
    return ko and ko.Value
end

-- Main Logic
local function Loop()
    -- Always try to get a target if we don't have one locked, or update it
    local target = GetTarget()
    
    -- If no target, ensure we aren't glued/voided and return
    if not target or not target.Character then 
        if CurrentParams then LogToFile("Target Lost or Invalid") end
        Unglue()
        SetVoid(false)
        CurrentParams = nil
        return 
    end
    
    -- Target Logic & Timing reset
    if LastTargetId ~= target.UserId then
        LogToFile("New Target Acquired: " .. target.Name)
        LastTargetId = target.UserId
        LockStartTime = tick()
        SetVoid(false) -- Reset void state for new target
    end
    
    CurrentParams = {Target = target}
    local localChar = LocalPlayer.Character
    local targetChar = target.Character
    
    if not localChar then return end
    
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not localRoot or not targetRoot then return end
    
    -- 1. Auto Buy & Equip
    local toolName = "[PepperSpray]" -- User confirmed exact name
    local tool = localChar:FindFirstChild(toolName)
    
    if not tool then
        -- Check backpack
        local bpTool = LocalPlayer.Backpack:FindFirstChild(toolName) or LocalPlayer.Backpack:FindFirstChild("PepperSpray")
        if bpTool then
            LogToFile("Accessing Tool from Backpack")
            bpTool.Parent = localChar
            tool = bpTool
        end
    end

    if not tool then
        -- REQUEST: "dont stick to target when buying"
        Unglue()
        SetVoid(false)
        
        -- Buy with debounce and desync check
        -- Mimicking AutoBag logic: if not tool and api:can_desync() then ...
        if api and api.buy_item and api.can_desync and api:can_desync() then
            if tick() - (LastBuyAttempt or 0) > 1 then
                LogToFile("Tool Missing. Attempting Purchase...")
                LastBuyAttempt = tick()
                api:buy_item("pepperspray")
            end
        end
        return -- Exit loop while buying
    else
        -- We have the tool, ensure it's equipped and activating
        tool:Activate()
        
        -- Debug Monitor Hook
        if CurrentParams and CurrentParams.MonitoredTarget ~= target then
             LogToFile("Hooking Damage Monitor to: " .. target.Name)
             CurrentParams.MonitoredTarget = target
             MonitorDamage(target)
        end
    end
    
    -- 2. Glue / Void Timing Logic
    -- As requested: "remove te unstuck void for now... lets just debug"
    
    -- Force Normal Spray Mode
    SetVoid(false)
    IsVoided = false
    
    -- Glue & Face Target (The "Nasty Combo")
    if getgenv().sethiddenproperty then
        sethiddenproperty(localRoot, "PhysicsRepRootPart", targetRoot)
    end
    
    -- Calculate position exactly in front of target
    local targetCFrame = targetRoot.CFrame
    local goalPos = targetCFrame.Position + (targetCFrame.LookVector * Config.Distance)
    local goalCFrame = CFrame.lookAt(goalPos, targetCFrame.Position)
    
    -- Force CFrame
    if api and api.set_desync_cframe then
        api:set_desync_cframe(goalCFrame)
    else
        localRoot.CFrame = goalCFrame
        localRoot.Velocity = Vector3.zero 
        localRoot.RotVelocity = Vector3.zero
    end
    
    --[[ REMOVED FOR DEBUGGING
    local timeLocked = tick() - LockStartTime
    
    if timeLocked > Config.VoidDelay then
        -- "When spray unstick and go void"
        Unglue()
        SetVoid(true)
    else
        -- Normal Spray Mode
        SetVoid(false)
        -- ...
    end
    ]]
    
    -- 3. Stomp Logic
    if IsKO(target) then
        if tick() - (LastStomp or 0) > Config.StompDelay then
            LastStomp = tick()
            MainEvent:FireServer("Stomp")
        end
    end
end

-- Toggle Function
local function Toggle(bool)
    IsActive = bool
    if bool then
        api:notify("Pepper Spray Killer: Scanning for Silent Aim Target...", 3)
        RunService:BindToRenderStep("PepperSprayLoop", Enum.RenderPriority.Character.Value + 1, Loop)
        LockStartTime = tick() -- Init start time
    else
        RunService:UnbindFromRenderStep("PepperSprayLoop")
        Unglue()
        SetVoid(false)
        CurrentParams = nil
    end
end

-- UI Integration
local Tab = api:GetTab("Combat") or api:AddTab("Combat")
local Group = Tab:AddRightGroupbox("Pepper Spray Killer")

local EnableToggle = Group:AddToggle("PepperSprayKiller_Enabled", { 
    Text = "Enable Pepper Spray Killer", 
    Default = false,
    Tooltip = "Automatically glues, faces, sprays and stomps Silent Aim target" 
})

local DistanceSlider = Group:AddSlider("PepperSprayKiller_Distance", {
    Text = "Distance",
    Default = 3,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Suffix = "studs"
})

local StompDelaySlider = Group:AddSlider("PepperSprayKiller_StompDelay", {
    Text = "Stomp Delay",
    Default = 0.25,
    Min = 0.05,
    Max = 1,
    Rounding = 2,
    Suffix = "s"
})

local VoidDelaySlider = Group:AddSlider("PepperSprayKiller_VoidDelay", {
    Text = "Unstick/Void Delay",
    Default = 3,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Suffix = "s",
    Tooltip = "Time to spray before unsticking and going void"
})

local DebugToggle = Group:AddToggle("PepperSprayKiller_Debug", {
    Text = "Debug Spray Cooldown",
    Default = false,
    Tooltip = "Prints time between sprays to console (F9)"
})

-- Listeners
DistanceSlider:OnChanged(function() Config.Distance = DistanceSlider.Value end)
StompDelaySlider:OnChanged(function() Config.StompDelay = StompDelaySlider.Value end)
VoidDelaySlider:OnChanged(function() Config.VoidDelay = VoidDelaySlider.Value end)
DebugToggle:OnChanged(function() Config.Debug = DebugToggle.Value end)

-- Hook into main loop for tool monitoring
local OriginalActivate = nil
-- We need to ensure we monitor the tool once we find it
-- We can add a check in the loop to attach the monitor

EnableToggle:OnChanged(function()
    Toggle(EnableToggle.Value)
end)

-- Cleanup
api:on_event("unload", function()
    Toggle(false)
    if DamageConnection then DamageConnection:Disconnect() end
end)

api:notify("Pepper Spray Script Loaded with UI", 5)
