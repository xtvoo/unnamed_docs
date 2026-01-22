-- Music Player & Visualizer
-- Plays audio by ID and visualizes it using PlaybackLoudness.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local Config = {
    SoundID = "rbxassetid://142376088", -- Default ID
    Volume = 2,
    Loop = true,
    VisualizerMode = "Pulse", -- "Pulse", "Spectrum", "Off"
    PulseColor = Color3.fromRGB(255, 0, 0), -- Default Red
}

-- State
local SoundObj = nil
local VisParts = {} -- Storage for visualizer parts
local Connection = nil
local IsPlaying = false

-- Cleanup Function
local function CleanupVisuals()
    for _, part in pairs(VisParts) do
        if part then part:Destroy() end
    end
    table.clear(VisParts)
end

-- Audio System
local function InitSound()
    if SoundObj then SoundObj:Destroy() end
    SoundObj = Instance.new("Sound")
    SoundObj.Name = "MusicPlayer_Sound"
    SoundObj.Parent = workspace
    SoundObj.Looped = Config.Loop
    SoundObj.Volume = Config.Volume
    return SoundObj
end

local function PlayMusic()
    if not SoundObj then InitSound() end
    
    -- Format ID
    local id = Config.SoundID
    if not string.match(id, "rbxassetid://") then
        if tonumber(id) then
            id = "rbxassetid://" .. id
        end
    end
    
    SoundObj.SoundId = id
    SoundObj:Play()
    IsPlaying = true
end

local function StopMusic()
    if SoundObj then
        SoundObj:Stop()
    end
    IsPlaying = false
    CleanupVisuals()
end

-- Visualizer Logic
local function UpdateVisuals()
    if not SoundObj or not SoundObj.IsPlaying then return end
    
    local loudness = SoundObj.PlaybackLoudness
    local normLoudness = math.clamp(loudness / 1000, 0, 1) -- Normalized 0-1 (approx)
    
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if Config.VisualizerMode == "Pulse" then
        -- Simple Pulse Sphere
        if #VisParts == 0 then
            local p = Instance.new("Part")
            p.Shape = Enum.PartType.Ball
            p.Material = Enum.Material.Neon
            p.Anchored = true
            p.CanCollide = false
            p.Transparency = 0.5
            p.Color = Config.PulseColor
            p.Parent = workspace
            table.insert(VisParts, p)
        end
        
        local part = VisParts[1]
        part.CFrame = root.CFrame
        
        -- Scale based on loudness
        local scale = 5 + (loudness * 0.05)
        part.Size = Vector3.new(scale, scale, scale)
        part.Color = Config.PulseColor
        
    elseif Config.VisualizerMode == "Spectrum" then
        -- 3D Bars behind player
        local numBars = 10
        if #VisParts == 0 then
            for i = 1, numBars do
                local p = Instance.new("Part")
                p.Anchored = true
                p.CanCollide = false
                p.Material = Enum.Material.Neon
                p.Size = Vector3.new(1, 1, 1)
                p.Parent = workspace
                table.insert(VisParts, p)
            end
        end
        
        local center = root.CFrame
        for i, part in ipairs(VisParts) do
            -- Arrange in arc behind player
            local angle = math.rad(180 / (numBars + 1)) * i
            local offset = CFrame.new(math.cos(angle) * 10, 0, math.sin(angle) * 10) -- Semi-circle? needs tuning
            
            -- Simpler linear arrangement for now
            local space = 2
            local startOffset = -((numBars * space) / 2)
            local currentOffset = startOffset + (i * space)
            local pos = center * CFrame.new(currentOffset, 0, 5)
            
            -- Randomize height slightly for "spectrum" effect since we only have 1 loudness value
            -- Real spectrum requires Frequency info which Roblox doesn't expose easily without hacky FFT
            -- We'll just sim it with loudness + random variation
            local noise = math.random() * 0.5
            local height = 1 + (loudness * 0.02) * (0.8 + noise)
            
            part.Size = Vector3.new(1.5, height, 1.5)
            part.CFrame = pos * CFrame.new(0, height/2, 0) -- Pivot at bottom
            part.Color = Color3.fromHSV((tick() * 0.5 + (i/numBars)) % 1, 1, 1) -- Rainbow wave
        end
    end
end

-- UI Integration
local Tab = api:GetTab("Music") or api:AddTab("Music")
local Group = Tab:AddRightGroupbox("Music Visualizer Utils")

local IDInput = Group:AddInput("Music_ID", {
    Default = "142376088",
    Numeric = true,
    Finished = false,
    Text = "Sound ID",
    Tooltip = "Enter Roblox Audio ID",
    Placeholder = "142376088",
})

local PlayBtn = Group:AddButton("Play", function()
    Config.SoundID = IDInput.Value
    PlayMusic()
end)

local StopBtn = Group:AddButton("Stop", function()
    StopMusic()
end)

local VolSlider = Group:AddSlider("Music_Volume", {
    Text = "Volume",
    Default = 2,
    Min = 0,
    Max = 10,
    Rounding = 1,
})

local LoopToggle = Group:AddToggle("Music_Loop", {
    Text = "Loop",
    Default = true,
})

local VisDropdown = Group:AddDropdown("Music_VisMode", {
    Values = {"Off", "Pulse", "Spectrum"},
    Default = "Pulse",
    Multi = false,
    Text = "Visualizer Mode",
})

-- Listeners
IDInput:OnChanged(function() Config.SoundID = IDInput.Value end)
VolSlider:OnChanged(function() 
    Config.Volume = VolSlider.Value 
    if SoundObj then SoundObj.Volume = Config.Volume end
end)
LoopToggle:OnChanged(function()
    Config.Loop = LoopToggle.Value
    if SoundObj then SoundObj.Looped = Config.Loop end
end)
VisDropdown:OnChanged(function()
    Config.VisualizerMode = VisDropdown.Value
    CleanupVisuals() -- Reset parts on mode change
end)

-- Main Loop
if Connection then Connection:Disconnect() end
Connection = RunService.RenderStepped:Connect(function()
    if IsPlaying then
        UpdateVisuals()
    end
end)

-- Cleanup on Unload
api:on_event("unload", function()
    StopMusic()
    CleanupVisuals()
    if Connection then Connection:Disconnect() end
    if SoundObj then SoundObj:Destroy() end
end)

api:notify("Music Player Loaded", 5)
