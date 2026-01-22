--[[
    Unnamed Addon: Music Player with Visualizer v2.0
    Loads MP3/OGG/WAV/M4A from a folder and plays with visual effects
    Multiple visualizer styles!
]]

api:set_lua_name("MusicPlayer")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer

-- Config
local MUSIC_FOLDER = "MusicPlayer"

-- Sound setup
local Sound = Instance.new("Sound")
Sound.Parent = SoundService
Sound.Looped = false
Sound.Volume = 0.5

-- Modular Visualizer System
local VisParts = {} -- All active visualizer parts
local Visualizers = {} -- Registry
local CurrentVisualizer = nil

-- Utility for modular viz
local function ClearVis()
    for _, p in pairs(VisParts) do pcall(function() p:Destroy() end) end
    table.clear(VisParts)
end

local function CreatePart(name, size, material, shape)
    local p = Instance.new("Part")
    p.Anchored, p.CanCollide = true, false
    p.Material = material or Enum.Material.Neon
    p.Size = size or Vector3.new(0.3, 1, 0.3)
    p.Shape = shape or Enum.PartType.Block
    p.Name = name or "VisPart"
    p.Parent = workspace
    table.insert(VisParts, p)
    return p
end

local function CreateIcon(name, textureId)
    local p = CreatePart(name, Vector3.new(1,1,1), Enum.Material.Air, Enum.PartType.Block)
    p.Transparency = 1
    
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(5,0,5,0)
    bb.AlwaysOnTop = true
    bb.Parent = p
    
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(1,0,1,0)
    img.BackgroundTransparency = 1
    img.Image = "rbxassetid://" .. textureId
    img.ScaleType = Enum.ScaleType.Fit
    img.Parent = bb
    
    return p
end
local Hue = 0

-- UI Setup
local tabs = { Misc = api:GetTab("misc") or api:AddTab("misc") }
local sec = tabs.Misc:AddLeftGroupbox("Music Player")

local EnableToggle = sec:AddToggle("MP_Enable", { Text = "Enable", Default = false })
local VisualizerToggle = sec:AddToggle("MP_Vis", { Text = "Visualizer", Default = true })
local VisStyle = sec:AddDropdown("MP_Style", { Text = "Visualizer Style", Default = "Bars", Values = {
    "Bars", "Ring", "Orbs", "Wave", "Platform", "Helix", "Sphere",
    "BlackHole", "SolarSystem", "Galaxy", "StarField", "Nebula",
    "MatrixRain", "Circuit", "Glitch", "Equalizer", "DNA",
    "Inferno", "Tsunami", "Tornado", "Lightning", "Snow", "Rain", "Lava", "EarthQuake",
    "Pyramid", "CubeSwarm", "HexGrid",
    "Hearts", "Skulls", "Money", "Ghosts", "Aliens", "Smiles", "Music", "Swords"
} })
local LoopToggle = sec:AddToggle("MP_Loop", { Text = "Loop", Default = false })
local AutoNextToggle = sec:AddToggle("MP_AutoNext", { Text = "Auto Next", Default = true })
local VolumeSlider = sec:AddSlider("MP_Vol", { Text = "Volume", Default = 50, Min = 0, Max = 1000, Rounding = 0 })
local VisRadiusSlider = sec:AddSlider("MP_Radius", { Text = "Vis Radius", Default = 4, Min = 2, Max = 12, Rounding = 1 })
local VisIntensity = sec:AddSlider("MP_Intensity", { Text = "Intensity", Default = 15, Min = 5, Max = 400, Rounding = 0 })
local VisSpeedSlider = sec:AddSlider("MP_Speed", { Text = "Animation Speed", Default = 2, Min = 0.5, Max = 5, Rounding = 1 })
local ColorMode = sec:AddDropdown("MP_Color", { Text = "Color Mode", Default = "Rainbow", Values = {"Rainbow", "Pulse", "Static", "Gradient"} })
local StaticColor = sec:AddLabel("Static Color"):AddColorPicker("MP_StaticCol", { Default = Color3.fromRGB(0, 200, 255) })

local sec2 = tabs.Misc:AddRightGroupbox("Playlist")
local SongDropdown = sec2:AddDropdown("MP_Songs", { Text = "Select Song", Values = {}, Default = nil, AllowNull = true })
sec2:AddButton({ Text = "▶ Play", Func = function()
    local sel = SongDropdown.Value
    if sel and Songs[sel] then PlaySong(Songs[sel]) end
end })
sec2:AddButton({ Text = "⏸ Pause/Resume", Func = function()
    if Sound.IsPlaying then Sound:Pause() else Sound:Resume() end
end })
sec2:AddButton({ Text = "⏹ Stop", Func = function() Sound:Stop() end })
sec2:AddButton({ Text = "⏭ Next", Func = function() PlayNext() end })
sec2:AddButton({ Text = "⏮ Previous", Func = function() PlayPrev() end })
sec2:AddButton({ Text = "🔄 Refresh", Func = function() LoadSongs() end })

-- Song storage
Songs = {}
SongList = {}
CurrentIndex = 0

-- Helpers
local function GetFileName(path)
    local str = tostring(path):gsub("\\", "/")
    local idx = str:match("^.*()/")
    if idx then str = str:sub(idx + 1) end
    return str:gsub("%.%w+$", "")
end

local function GetColor(progress, loudness)
    local mode = ColorMode.Value
    local t = tick()
    
    if mode == "Rainbow" then
        return Color3.fromHSV((Hue + progress * 0.3) % 1, 0.9, 1)
    elseif mode == "Pulse" then
        local pulse = math.clamp(loudness / 500, 0.3, 1)
        return Color3.fromHSV(Hue, pulse, 1)
    elseif mode == "Static" then
        return StaticColor.Value
    elseif mode == "Gradient" then
        local grad = (math.sin(t + progress * math.pi * 2) + 1) / 2
        return Color3.fromHSV((Hue + grad * 0.5) % 1, 0.8, 1)
    end
    return Color3.fromHSV(Hue, 1, 1)
end

-- Load songs
function LoadSongs()
    Songs, SongList, CurrentIndex = {}, {}, 0
    local ok, files = pcall(function() return listfiles(MUSIC_FOLDER) end)
    if not ok or type(files) ~= "table" then
        api:notify("Create folder: workspace/" .. MUSIC_FOLDER, 3)
        return
    end
    for _, path in pairs(files) do
        local lower = path:lower()
        if lower:find("%.mp3$") or lower:find("%.ogg$") or lower:find("%.wav$") or lower:find("%.m4a$") then
            local asset = getcustomasset(path)
            if asset then
                local name = GetFileName(path)
                Songs[name] = { path = path, asset = asset, name = name }
                table.insert(SongList, name)
            end
        end
    end
    table.sort(SongList)
    SongDropdown:SetValues(SongList)
    api:notify("Loaded " .. #SongList .. " songs", 2)
end

function PlaySong(data)
    if not data then return end
    Sound:Stop()
    Sound.SoundId = data.asset
    repeat task.wait() until Sound.IsLoaded or not EnableToggle.Value
    Sound:Play()
    api:notify("▶ " .. data.name, 2)
    for i, n in ipairs(SongList) do if n == data.name then CurrentIndex = i break end end
end

function PlayNext()
    if #SongList == 0 then return end
    CurrentIndex = CurrentIndex % #SongList + 1
    if Songs[SongList[CurrentIndex]] then PlaySong(Songs[SongList[CurrentIndex]]) end
end

function PlayPrev()
    if #SongList == 0 then return end
    CurrentIndex = CurrentIndex - 2
    if CurrentIndex < 0 then CurrentIndex = #SongList - 1 end
    CurrentIndex = CurrentIndex + 1
    if Songs[SongList[CurrentIndex]] then PlaySong(Songs[SongList[CurrentIndex]]) end
end

-- Visualizer implementations
Visualizers.Bars = {
    Create = function()
        for i = 1, 32 do
            local p = CreatePart("MusicBar_"..i)
            p:SetAttribute("Offset", math.random() * math.pi * 2)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local angle = (i / #VisParts) * math.pi * 2 + t
            local offset = p:GetAttribute("Offset") or 0
            local wave = math.abs(math.sin(t * 2 + offset))
            local height = 0.5 + (loudness / 1000 * intensity * wave)
            
            p.Position = basePos + Vector3.new(math.cos(angle) * radius, height / 2 - 2.5, math.sin(angle) * radius)
            p.Size = Vector3.new(0.25, height, 0.25)
            p.Color = GetColor(i / #VisParts, loudness)
            p.Transparency = 0.1
        end
    end
}

Visualizers.Ring = {
    Create = function()
        for i = 1, 48 do
            local p = CreatePart("MusicRing_"..i, Vector3.new(0.2, 0.2, 0.2), Enum.Material.Neon, Enum.PartType.Ball)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        local pulseRadius = radius + (loudness / 500)
        for i, p in ipairs(VisParts) do
            local angle = (i / #VisParts) * math.pi * 2 + t * 0.5
            local yWave = math.sin(angle * 3 + t * 2) * (loudness / 300)
            
            p.Position = basePos + Vector3.new(math.cos(angle) * pulseRadius, yWave, math.sin(angle) * pulseRadius)
            local size = 0.2 + (loudness / 800)
            p.Size = Vector3.new(size, size, size)
            p.Color = GetColor(i / #VisParts, loudness)
            p.Transparency = 0.2
        end
    end
}

Visualizers.Orbs = {
    Create = function()
         for i = 1, 12 do
            local p = CreatePart("MusicOrb_"..i, Vector3.new(0.5, 0.5, 0.5), Enum.Material.Neon, Enum.PartType.Ball)
            p:SetAttribute("Phase", math.random() * math.pi * 2)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local phase = p:GetAttribute("Phase") or 0
            local angle = (i / #VisParts) * math.pi * 2 + t * 0.3
            local yOffset = math.sin(t * 2 + phase) * 2
            local orbitRadius = radius + math.sin(t + phase) * 1.5
            
            p.Position = basePos + Vector3.new(math.cos(angle) * orbitRadius, yOffset, math.sin(angle) * orbitRadius)
            local size = 0.4 + (loudness / 400)
            p.Size = Vector3.new(size, size, size)
            p.Color = GetColor(i / #VisParts, loudness)
            p.Transparency = 0.3
        end
    end
}

Visualizers.Wave = {
    Create = function()
        for i = 1, 40 do
            local p = CreatePart("MusicWave_"..i, Vector3.new(0.15, 0.15, 0.15), Enum.Material.Neon, Enum.PartType.Ball)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local progress = (i - 1) / (#VisParts - 1)
            local xPos = (progress - 0.5) * radius * 3
            local yWave = math.sin(progress * math.pi * 4 + t * 3) * (loudness / 200)
            local zWave = math.cos(progress * math.pi * 2 + t * 2) * 1
            
            p.Position = basePos + Vector3.new(xPos, yWave, zWave)
            local size = 0.15 + (loudness / 1000)
            p.Size = Vector3.new(size, size, size)
            p.Color = GetColor(progress, loudness)
            p.Transparency = 0.2
        end
    end
}

Visualizers.Platform = {
    Create = function()
        -- Platform is special, let's treat it as a part for now or just generic parts
        -- The refactor merged VisRings/VisOrbs into VisParts generally, but let's handle the specific request for a platform
        -- We will just make the platform the first part
        local plat = CreatePart("MusicPlatform", Vector3.new(8, 0.2, 8), Enum.Material.Neon)
        plat:SetAttribute("IsPlatform", true)
        
        for i = 1, 24 do
            local p = CreatePart("PlatformRing_"..i, Vector3.new(0.15, 0.15, 0.15), Enum.Material.Neon, Enum.PartType.Ball)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        local pulse = 1 + (loudness / 800)
        local ringCount = 0
        
        for i, p in ipairs(VisParts) do
            if p:GetAttribute("IsPlatform") then
                p.Position = basePos + Vector3.new(0, -3, 0)
                p.Size = Vector3.new(6 * pulse, 0.1, 6 * pulse)
                p.Color = GetColor(0.5, loudness)
                p.Transparency = 0.5
            else
                ringCount = ringCount + 1
                -- We don't have total ring count easily available unless we count, but we know it's local
                -- Or we can approximate index
                local localIdx = i - 1 -- since platform is 1
                local totalRings = #VisParts - 1
                local angle = (localIdx / totalRings) * math.pi * 2 + t
                local ringRadius = radius + (loudness / 300) * math.sin(t * 3 + localIdx)
                
                p.Position = basePos + Vector3.new(math.cos(angle) * ringRadius, -2.9, math.sin(angle) * ringRadius)
                p.Size = Vector3.new(0.2, 0.2, 0.2)
                p.Color = GetColor(localIdx / totalRings, loudness)
                p.Transparency = 0.1
            end
        end
    end
}

Visualizers.Helix = {
    Create = function()
        for i = 1, 48 do
            local p = CreatePart("MusicHelix_"..i, Vector3.new(0.2, 0.2, 0.2), Enum.Material.Neon, Enum.PartType.Ball)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local progress = (i - 1) / (#VisParts - 1)
            local angle = progress * math.pi * 4 + t * 2
            local yPos = (progress - 0.5) * intensity * 0.5
            local helixRadius = radius * 0.6 + math.sin(t + progress * math.pi) * 0.5
            
            p.Position = basePos + Vector3.new(math.cos(angle) * helixRadius, yPos, math.sin(angle) * helixRadius)
            local size = 0.2 + (loudness / 600)
            p.Size = Vector3.new(size, size, size)
            p.Color = GetColor(progress, loudness)
            p.Transparency = 0.2
        end
    end
}

Visualizers.Sphere = {
    Create = function()
        for i = 1, 60 do
            local p = CreatePart("MusicSphere_"..i, Vector3.new(0.15, 0.15, 0.15), Enum.Material.Neon, Enum.PartType.Ball)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local phi = math.acos(1 - 2 * (i / #VisParts))
            local theta = math.pi * (1 + 5^0.5) * i + t
            local sphereRadius = radius * 0.8 + (loudness / 400)
            
            local x = math.sin(phi) * math.cos(theta) * sphereRadius
            local y = math.sin(phi) * math.sin(theta) * sphereRadius
            local z = math.cos(phi) * sphereRadius
            
            p.Position = basePos + Vector3.new(x, y, z)
            local size = 0.12 + (loudness / 800)
            p.Size = Vector3.new(size, size, size)
            p.Color = GetColor(i / #VisParts, loudness)
            p.Transparency = 0.2
        end
    end
}

-- COSMIC PACK
Visualizers.BlackHole = {
    Create = function()
        -- Event Horizon (Core)
        local core = CreatePart("BH_Core", Vector3.new(4, 4, 4), Enum.Material.Neon, Enum.PartType.Ball)
        core.Color = Color3.new(0,0,0)
        core.Transparency = 0.1
        core:SetAttribute("IsCore", true)
        
        -- Accretion Disk (Particles)
        for i = 1, 60 do
            local p = CreatePart("BH_Disk_"..i, Vector3.new(0.3, 0.3, 0.3), Enum.Material.Neon, Enum.PartType.Block)
            p:SetAttribute("Angle", math.random() * math.pi * 2)
            p:SetAttribute("Dist", 5 + math.random() * 8)
            p:SetAttribute("Speed", 0.5 + math.random() * 1.5)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        local coreScale = 1 + (loudness / 800)
        
        for i, p in ipairs(VisParts) do
            if p:GetAttribute("IsCore") then
                p.Size = Vector3.new(4 * coreScale, 4 * coreScale, 4 * coreScale)
                p.Position = basePos + Vector3.new(0, 5, 0)
                p.Color = Color3.new(0,0,0) -- Always black
                -- Add a slight chaotic wobble
                p.CFrame = p.CFrame * CFrame.Angles(math.random()*0.1, math.random()*0.1, math.random()*0.1)
            else
                local angle = p:GetAttribute("Angle") + (t * p:GetAttribute("Speed"))
                local dist = p:GetAttribute("Dist") - (loudness / 5000) -- Suck in slightly on beat
                if dist < 4 then dist = 12 end -- Reset if too close
                p:SetAttribute("Dist", dist)
                
                local swirlRadius = dist * (1 - (loudness / 2000))
                
                local x = math.cos(angle) * swirlRadius
                local z = math.sin(angle) * swirlRadius
                local y = 5 + math.sin(angle * 3) * (loudness/1000) -- Disk height variation
                
                p.Position = basePos + Vector3.new(x, y, z)
                p.CFrame = CFrame.lookAt(p.Position, basePos + Vector3.new(0,5,0)) -- Point at core
                p.Size = Vector3.new(0.2 + (loudness/1000), 0.2, 0.5 + (loudness/500))
                p.Color = GetColor(dist/15, loudness)
            end
        end
    end
}

Visualizers.SolarSystem = {
    Create = function()
        -- Sun
        local sun = CreatePart("Sun", Vector3.new(3,3,3), Enum.Material.Neon, Enum.PartType.Ball)
        sun:SetAttribute("IsSun", true)
        
        -- Planets
        for i = 1, 8 do
            local p = CreatePart("Planet_"..i, Vector3.new(1,1,1), Enum.Material.Plastic, Enum.PartType.Ball)
            p:SetAttribute("OrbitRadius", 5 + (i * 2))
            p:SetAttribute("OrbitSpeed", 0.5 / i)
            p:SetAttribute("SizeBase", 0.5 + (math.random() * 0.8))
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            if p:GetAttribute("IsSun") then
                p.Position = basePos + Vector3.new(0, 6, 0)
                local s = 3 + (loudness / 300)
                p.Size = Vector3.new(s,s,s)
                p.Color = Color3.fromRGB(255, 200 + (loudness/10), 50)
            else
                local orbitR = p:GetAttribute("OrbitRadius")
                local speed = p:GetAttribute("OrbitSpeed")
                local angle = t * speed * 2
                
                -- Elliptical orbit distortion on beat
                local r = orbitR + (loudness/800)
                
                p.Position = basePos + Vector3.new(math.cos(angle) * r, 6, math.sin(angle) * r)
                
                local sb = p:GetAttribute("SizeBase")
                p.Size = Vector3.new(sb, sb, sb)
                p.Color = GetColor(i/#VisParts, loudness)
            end
        end
    end
}

Visualizers.Galaxy = {
    Create = function()
        local arms = 3
        local partsPerArm = 20
        for arm = 1, arms do
            for i = 1, partsPerArm do
                local p = CreatePart("Star", Vector3.new(0.2,0.2,0.2), Enum.Material.Neon, Enum.PartType.Ball)
                p:SetAttribute("Arm", arm)
                p:SetAttribute("Progress", i/partsPerArm) -- 0 to 1 distance from center
            end
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local arm = p:GetAttribute("Arm")
            local prog = p:GetAttribute("Progress")
            
            local armAngle = (arm / 3) * math.pi * 2
            local spiralOffset = prog * math.pi * 2 -- Spiral twist
            local rot = t * 0.5
            
            local finalAngle = armAngle + spiralOffset + rot
            local dist = prog * 15 * (radius/4)
            
            -- Height variation (Galaxy bulge)
            local y = 6 + math.exp(-dist*0.5) * math.sin(t*5) * (loudness/500)
            
            p.Position = basePos + Vector3.new(math.cos(finalAngle) * dist, y, math.sin(finalAngle) * dist)
            
            local s = 0.2 + (loudness/1000) * (1-prog) -- Inner stars pulsate more
            p.Size = Vector3.new(s,s,s)
            p.Color = GetColor(prog, loudness)
        end
    end
}

Visualizers.StarField = {
    Create = function()
        for i = 1, 50 do
            local p = CreatePart("Star", Vector3.new(0.3,0.3,3), Enum.Material.Neon, Enum.PartType.Block)
            p:SetAttribute("Dir", Vector3.new(math.random()-0.5, math.random()-0.5, math.random()-0.5).Unit)
            p:SetAttribute("Dist", math.random() * 20)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local dir = p:GetAttribute("Dir")
            local dist = p:GetAttribute("Dist")
            local speed = 0.1 + (loudness/2000)
            
            dist = dist + speed
            if dist > 20 then dist = 1 end -- Respawn center
            p:SetAttribute("Dist", dist)
            
            p.Position = basePos + Vector3.new(0,5,0) + (dir * dist)
            p.CFrame = CFrame.lookAt(p.Position, basePos + Vector3.new(0,5,0))
            
            local width = 0.1 + (loudness/2000)
            local len = 0.5 + (speed * 5)
            p.Size = Vector3.new(width, width, len)
            p.Color = GetColor(dist/20, loudness)
        end
    end
}

Visualizers.Nebula = {
    Create = function()
        for i = 1, 20 do
            local p = CreatePart("Gas", Vector3.new(2,2,2), Enum.Material.ForceField, Enum.PartType.Ball)
            p:SetAttribute("BasePos", Vector3.new(math.random()-0.5, math.random()-0.5, math.random()-0.5) * 8)
            p:SetAttribute("NoiseOff", math.random() * 100)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local bp = p:GetAttribute("BasePos")
            local no = p:GetAttribute("NoiseOff")
            
            -- Floating noise movement
            local nx = math.sin(t + no) * 2
            local ny = math.cos(t * 0.8 + no) * 2
            local nz = math.sin(t * 1.2 + no) * 2
            
            p.Position = basePos + Vector3.new(0,5,0) + bp + Vector3.new(nx, ny, nz)
            
            local expansion = loudness / 200
            p.Size = Vector3.new(3+expansion, 3+expansion, 3+expansion)
            p.Color = GetColor(i/20, loudness)
            p.Transparency = 0.3 + (math.sin(t+no)*0.2)
        end
    end
}



-- TECH PACK
Visualizers.MatrixRain = {
    Create = function()
        for i = 1, 50 do
            local p = CreatePart("Matrix", Vector3.new(0.2, 2, 0.2), Enum.Material.Neon, Enum.PartType.Block)
            p:SetAttribute("Speed", 5 + math.random() * 10)
            p:SetAttribute("X", (math.random() - 0.5) * 20)
            p:SetAttribute("Z", (math.random() - 0.5) * 20)
            p:SetAttribute("Y", math.random() * 20)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local speed = p:GetAttribute("Speed") + (loudness / 500)
            local y = p:GetAttribute("Y") - (speed * 0.1)
            
            if y < -5 then y = 20 end
            p:SetAttribute("Y", y)
            
            p.Position = basePos + Vector3.new(p:GetAttribute("X"), y, p:GetAttribute("Z"))
            p.Color = Color3.fromRGB(0, 255, 50)
            p.Transparency = 0.3
            
            -- Glitch size on beat
            if loudness > 100 and math.random() > 0.8 then
                p.Size = Vector3.new(0.4, 4, 0.4)
            else
                p.Size = Vector3.new(0.2, 2, 0.2)
            end
        end
    end
}

Visualizers.Circuit = {
    Create = function()
        for i = 1, 40 do
            local p = CreatePart("Circuit", Vector3.new(0.2, 0.2, 2), Enum.Material.Neon, Enum.PartType.Block)
            p:SetAttribute("Angle", (math.floor(math.random() * 4) * 90) * (math.pi/180)) -- 90 deg steps
            p:SetAttribute("Dist", math.random() * 10)
            p:SetAttribute("Speed", (math.random() > 0.5 and 1 or -1) * (0.5 + math.random()))
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local angle = p:GetAttribute("Angle")
            local dist = p:GetAttribute("Dist") + (t * p:GetAttribute("Speed"))
            dist = dist % 15
            
            local x = math.cos(angle) * dist
            local z = math.sin(angle) * dist
            
            p.Position = basePos + Vector3.new(x, -2.5, z)
            p.CFrame = CFrame.lookAt(p.Position, basePos + Vector3.new(0,-2.5,0))
            
            local width = 0.2 + (loudness/2000)
            p.Size = Vector3.new(width, 0.2, 2 + (loudness/500))
            p.Color = Color3.fromHSV(0.5 + (dist/30), 1, 1) -- Cyan/Blue tech feel
        end
    end
}

Visualizers.Glitch = {
    Create = function()
        for i = 1, 30 do
            local p = CreatePart("Glitch", Vector3.new(1,1,1), Enum.Material.Neon, Enum.PartType.Block)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            if math.random() > 0.7 then
                -- Teleport randomly around player
                local offset = Vector3.new(math.random()-0.5, math.random()-0.5, math.random()-0.5) * radius * 2
                p.Position = basePos + offset
                p.Size = Vector3.new(math.random(), math.random(), math.random()) * (1 + loudness/300)
                p.Color = Color3.fromHSV(math.random(), 0.8, 1)
                p.Transparency = math.random() * 0.5
            else
                -- Freeze in place transparently
                p.Transparency = 1
            end
        end
    end
}

Visualizers.Equalizer = {
    Create = function()
        for i = 1, 10 do -- 10 bands
            for j = 1, 5 do -- 5 segments per band
                local p = CreatePart("EQ_"..i.."_"..j, Vector3.new(0.8, 0.5, 0.8), Enum.Material.Neon, Enum.PartType.Block)
                p:SetAttribute("Band", i)
                p:SetAttribute("Segment", j)
            end
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        local bandWidth = 1.2
        for i, p in ipairs(VisParts) do
            local band = p:GetAttribute("Band")
            local seg = p:GetAttribute("Segment")
            
            -- Simulate freq breakdown by varying sensitivity per band
            local bandSens = 1 + math.sin(t*5 + band) * 0.5
            local val = (loudness / 500) * bandSens * 5 -- Max 5 segments active
            
            local active = val >= seg
            
            -- Arrange in a line or arc
            local x = (band - 5.5) * bandWidth
            local y = (seg - 1) * 0.8 - 2
            
            p.Position = basePos + Vector3.new(x, y, -5) -- Wall in front of player
            
            if active then
                p.Transparency = 0
                p.Color = Color3.fromHSV(seg/5 * 0.3, 1, 1) -- Green to Red gradient
                p.Size = Vector3.new(1, 0.6, 1)
            else
                p.Transparency = 0.8
                p.Color = Color3.new(0.2,0.2,0.2)
                p.Size = Vector3.new(0.8, 0.5, 0.8)
            end
        end
    end
}

Visualizers.DNA = {
    Create = function()
        for i = 1, 40 do
            local p = CreatePart("DNA", Vector3.new(0.3,0.3,0.3), Enum.Material.Neon, Enum.PartType.Ball)
            p:SetAttribute("Idx", i)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local idx = p:GetAttribute("Idx")
            local progress = idx / 40
            local y = (progress - 0.5) * 10
            local angle = progress * math.pi * 4 + t
            
            -- Strand 1 or 2 based on index parity
            local strand = (idx % 2 == 0) and 1 or -1
            local r = 2 + (loudness/1000)
            
            local x = math.cos(angle) * r * strand
            local z = math.sin(angle) * r * strand
            
            p.Position = basePos + Vector3.new(x, y, z)
            p.Color = (strand == 1) and Color3.new(0,1,1) or Color3.new(1,0,1)
            p.Size = Vector3.new(0.4, 0.4, 0.4)
        end
    end
}



-- ELEMENTAL PACK
Visualizers.Inferno = {
    Create = function()
        for i = 1, 60 do
            local p = CreatePart("Fire", Vector3.new(0.5, 0.5, 0.5), Enum.Material.Neon, Enum.PartType.Ball)
            p:SetAttribute("BaseX", (math.random()-0.5) * 10)
            p:SetAttribute("BaseZ", (math.random()-0.5) * 10)
            p:SetAttribute("Speed", 1 + math.random() * 2)
            p:SetAttribute("Offset", math.random() * 10)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local spd = p:GetAttribute("Speed") + (loudness/500)
            local y = (t * spd + p:GetAttribute("Offset")) % 10
            
            -- Tapering flame shape
            local width = 1 - (y/10)
            local x = p:GetAttribute("BaseX") * width
            local z = p:GetAttribute("BaseZ") * width
            
            p.Position = basePos + Vector3.new(x, y-2, z)
            p.Size = Vector3.new(0.5*width, 0.5*width, 0.5*width) * (1 + loudness/500)
            p.Color = Color3.fromHSV(0.05 + (y/30), 1, 1) -- Red to Orange/Yellow
            p.Transparency = y/10
        end
    end
}

Visualizers.Tsunami = {
    Create = function()
        for i = 1, 50 do
             local p = CreatePart("Water", Vector3.new(1, 1, 1), Enum.Material.Glass, Enum.PartType.Block)
             p:SetAttribute("Idx", i)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local idx = p:GetAttribute("Idx")
            local progress = idx / 50
            local x = (progress - 0.5) * 40
            
            local waveHeight = math.sin(t * 2 + progress * 5) * 5 + (loudness/100)
            local z = math.cos(t * 2 + progress * 5) * 5
            
            p.Position = basePos + Vector3.new(x, waveHeight, -10 + z)
            p.Size = Vector3.new(1, waveHeight + 5, 20)
            p.Color = Color3.fromHSV(0.6, 0.8, 1) -- Blue
            p.Transparency = 0.5
        end
    end
}

Visualizers.Tornado = {
    Create = function()
        for i = 1, 60 do
            local p = CreatePart("Wind", Vector3.new(0.5, 0.5, 0.5), Enum.Material.Neon, Enum.PartType.Ball)
            p:SetAttribute("Height", i * 0.3)
            p:SetAttribute("Angle", math.random() * math.pi * 2)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local h = p:GetAttribute("Height")
            local angle = p:GetAttribute("Angle") + (t * 5) + (loudness/500)
            
            local funnelWidth = 2 + (h * 0.5)
            local x = math.cos(angle) * funnelWidth
            local z = math.sin(angle) * funnelWidth
            
            p.Position = basePos + Vector3.new(x, h, z)
            p.Size = Vector3.new(0.5, 0.5, 0.5) * (1 + loudness/1000)
            p.Color = Color3.fromRGB(200, 200, 200)
            p.Transparency = 0.3
        end
    end
}

Visualizers.Lightning = {
    Create = function()
        for i = 1, 10 do
            local p = CreatePart("Bolt", Vector3.new(0.2, 10, 0.2), Enum.Material.Neon, Enum.PartType.Block)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            if math.random() > 0.9 then -- Flash
                local offset = Vector3.new((math.random()-0.5)*20, 10, (math.random()-0.5)*20)
                p.Position = basePos + offset
                p.Orientation = Vector3.new(math.random(-20,20), math.random(0,360), math.random(-20,20))
                p.Transparency = 0
                p.Color = Color3.new(1, 1, 0.8)
                p.Size = Vector3.new(0.2 + (loudness/1000), 10 + (loudness/100), 0.2 + (loudness/1000))
            else
                p.Transparency = 1
            end
        end
    end
}

Visualizers.Snow = {
    Create = function()
        for i = 1, 80 do
            local p = CreatePart("Snow", Vector3.new(0.2, 0.2, 0.2), Enum.Material.Plastic, Enum.PartType.Ball)
            p:SetAttribute("BaseX", (math.random()-0.5) * 30)
            p:SetAttribute("BaseZ", (math.random()-0.5) * 30)
            p:SetAttribute("Offset", math.random() * 20)
            p:SetAttribute("Speed", 0.5 + math.random())
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local off = p:GetAttribute("Offset")
            local y = 20 - ((t * p:GetAttribute("Speed") + off) % 20)
            
            p.Position = basePos + Vector3.new(p:GetAttribute("BaseX"), y, p:GetAttribute("BaseZ"))
            
            -- Snow stops in mid air on bass beat
            local size = 0.2
            if loudness > 100 then size = 0.4 end
            p.Size = Vector3.new(size, size, size)
            p.Color = Color3.new(1,1,1)
        end
    end
}

Visualizers.Rain = {
    Create = function()
        for i = 1, 80 do
            local p = CreatePart("Rain", Vector3.new(0.05, 1, 0.05), Enum.Material.Neon, Enum.PartType.Block)
            p:SetAttribute("BaseX", (math.random()-0.5) * 30)
            p:SetAttribute("BaseZ", (math.random()-0.5) * 30)
            p:SetAttribute("Offset", math.random() * 20)
            p:SetAttribute("Speed", 5 + math.random() * 5)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local off = p:GetAttribute("Offset")
            local y = 20 - ((t * p:GetAttribute("Speed") + off) % 20)
            
            p.Position = basePos + Vector3.new(p:GetAttribute("BaseX"), y, p:GetAttribute("BaseZ"))
            p.Size = Vector3.new(0.05, 1 + (loudness/500), 0.05)
            p.Color = Color3.new(0.4, 0.4, 1)
        end
    end
}

Visualizers.Lava = {
    Create = function()
        for i = 1, 60 do
            local p = CreatePart("Lava", Vector3.new(2, 0.5, 2), Enum.Material.Neon, Enum.PartType.Ball)
            p:SetAttribute("BaseX", (math.random()-0.5) * 20)
            p:SetAttribute("BaseZ", (math.random()-0.5) * 20)
            p:SetAttribute("Phase", math.random() * math.pi * 2)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local y = -3 + math.sin(t + p:GetAttribute("Phase")) * 0.5 + (loudness/500)
            p.Position = basePos + Vector3.new(p:GetAttribute("BaseX"), y, p:GetAttribute("BaseZ"))
            p.Color = Color3.fromHSV(0 + (y+3)/10, 1, 0.8) -- Red to Orange
            p.Size = Vector3.new(2 + (loudness/800), 0.5 + (loudness/800), 2 + (loudness/800))
        end
    end
}

Visualizers.EarthQuake = {
    Create = function()
        for i = 1, 30 do
            local p = CreatePart("Rock", Vector3.new(1, 1, 1), Enum.Material.Slate, Enum.PartType.Block)
            p:SetAttribute("BasePos", Vector3.new((math.random()-0.5)*20, -3, (math.random()-0.5)*20))
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local bp = p:GetAttribute("BasePos")
            local shake = Vector3.new(math.random()-0.5, math.random(), math.random()-0.5) * (loudness/100)
            p.Position = basePos + bp + shake
            p.Rotation = Vector3.new(math.random()*360, math.random()*360, math.random()*360)
            p.Color = Color3.fromRGB(100, 80, 50)
            p.Size = Vector3.new(1,1,1) * (1 + loudness/1000)
        end
    end
}

-- GEOMETRY PACK
Visualizers.Pyramid = {
    Create = function()
        for i = 1, 5 do -- Layers
            local count = i * 4
            for j = 1, count do
                local p = CreatePart("Pyr", Vector3.new(1,1,1), Enum.Material.Glass, Enum.PartType.Block)
                p:SetAttribute("Layer", i)
                p:SetAttribute("Angle", (j/count) * math.pi * 2)
            end
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local layer = p:GetAttribute("Layer")
            local angle = p:GetAttribute("Angle") + (t * 0.5 * (layer % 2 == 0 and 1 or -1))
            
            local w = (6 - layer) * 3
            local x = math.cos(angle) * w
            local z = math.sin(angle) * w
            local y = layer * 2 - 2
            
            p.Position = basePos + Vector3.new(x, y, z)
            p.Orientation = Vector3.new(0, math.deg(angle), 0)
            
            local s = 1 + (loudness/500)
            p.Size = Vector3.new(s, s, s)
            p.Color = Color3.fromHSV((layer/6 + hue)%1, 1, 1)
        end
    end
}

Visualizers.CubeSwarm = {
    Create = function()
        for i = 1, 100 do
            local p = CreatePart("Cube", Vector3.new(0.5,0.5,0.5), Enum.Material.Neon, Enum.PartType.Block)
            p:SetAttribute("Home", Vector3.new(math.random()-0.5, math.random()-0.5, math.random()-0.5) * 15)
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        local swirl = (loudness/500)
        for i, p in ipairs(VisParts) do
            local home = p:GetAttribute("Home")
            local d = home.Magnitude
            
            local rot = CFrame.Angles(t + d, t*0.5, t*0.2)
            local pos = rot * home
            
            -- Push out on bass
            local push = pos.Unit * (loudness/50)
            
            p.Position = basePos + Vector3.new(0,5,0) + pos + push
            p.Rotation = Vector3.new(t*100, t*50, 0)
            p.Color = GetColor(d/15, loudness)
        end
    end
}

Visualizers.HexGrid = {
    Create = function()
        for x = -3, 3 do
            for z = -3, 3 do
                 local p = CreatePart("Hex", Vector3.new(1.8, 0.2, 1.8), Enum.Material.Neon, Enum.PartType.Cylinder)
                 p:SetAttribute("GX", x)
                 p:SetAttribute("GZ", z)
                 p.Orientation = Vector3.new(0,0,90) -- Cylinder on side
            end
        end
    end,
    Update = function(t, loudness, radius, intensity, basePos, hue)
        for i, p in ipairs(VisParts) do
            local x = p:GetAttribute("GX")
            local z = p:GetAttribute("GZ")
            
            local xPos = x * 2 + (z%2==0 and 0 or 1)
            local zPos = z * 1.75
            
            local dist = math.sqrt(xPos^2 + zPos^2)
            local y = math.sin(dist - t*3) * (loudness/300)
            
            p.Position = basePos + Vector3.new(xPos, y-3, zPos)
            p.Size = Vector3.new(0.2 + (y+1), 1.8, 1.8) -- Cylinder length is Y
            p.Color = Color3.fromHSV((dist/10 + hue)%1, 1, 1)
            p.Orientation = Vector3.new(0, 0, 90)
        end
    end
}

-- ICON PACK GENERATOR (ASSETS)
local function MakeIconVis(assetId)
    return {
        Create = function()
            for i = 1, 30 do
                local p = CreateIcon("Icon", assetId)
                p:SetAttribute("Speed", 2 + math.random() * 3)
                p:SetAttribute("Phase", math.random() * math.pi * 2)
                p:SetAttribute("Radius", 3 + math.random() * 5)
            end
        end,
        Update = function(t, loudness, radius, intensity, basePos, hue)
            for i, p in ipairs(VisParts) do
                local ph = p:GetAttribute("Phase")
                local r = p:GetAttribute("Radius")
                local spd = p:GetAttribute("Speed")
                
                local angle = t * spd * 0.2 + ph
                
                local y = math.sin(t * spd + ph) * 3 + 3
                local x = math.cos(angle) * r
                local z = math.sin(angle) * r
                
                p.Position = basePos + Vector3.new(x, y, z)
                
                -- Beat scale
                local s = 1 + (loudness/500)
                p:FindFirstChildOfClass("BillboardGui").Size = UDim2.new(s*2,0,s*2,0)
            end
        end
    }
end

-- Using generic/common asset IDs (You can replace these!)
Visualizers.Hearts = MakeIconVis("363795553") -- Heart
Visualizers.Skulls = MakeIconVis("4743494553") -- Skull
Visualizers.Money = MakeIconVis("6222876652") -- Money Bag
Visualizers.Ghosts = MakeIconVis("261807357") -- Ghost
Visualizers.Aliens = MakeIconVis("6342045237") -- Alien
Visualizers.Smiles = MakeIconVis("6753303429") -- Smile
Visualizers.Music = MakeIconVis("5857973059") -- Music Note
Visualizers.Swords = MakeIconVis("5689038936") -- Sword

function DestroyVisualizer()
    CurrentVisualizer = nil
    ClearVis()
end

function CreateVisualizer()
    DestroyVisualizer()
    local style = VisStyle.Value
    if Visualizers[style] and Visualizers[style].Create then
        Visualizers[style].Create()
        CurrentVisualizer = Visualizers[style]
    end
    -- Fallback for legacy styles not yet migrated? No, let's migrate all.
end



-- Sync settings
VolumeSlider:OnChanged(function() Sound.Volume = VolumeSlider.Value / 100 end)
LoopToggle:OnChanged(function() Sound.Looped = LoopToggle.Value end)
VisStyle:OnChanged(function() if EnableToggle.Value and VisualizerToggle.Value then CreateVisualizer() end end)

-- Main update
local conn = nil

local function Update()
    if not EnableToggle.Value then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if not VisualizerToggle.Value then return end
    
    Hue = (Hue + 0.001 * VisSpeedSlider.Value) % 1
    local t = tick() * VisSpeedSlider.Value
    local loudness = Sound.PlaybackLoudness or 0
    local radius = VisRadiusSlider.Value
    local intensity = VisIntensity.Value
    local basePos = hrp.Position
    local style = VisStyle.Value
    
    if CurrentVisualizer and CurrentVisualizer.Update then
        CurrentVisualizer.Update(t, loudness, radius, intensity, basePos, Hue)
    end
end

-- Events
Sound.Ended:Connect(function()
    if AutoNextToggle.Value and not Sound.Looped then
        task.wait(0.5)
        PlayNext()
    end
end)

EnableToggle:OnChanged(function()
    if EnableToggle.Value then
        LoadSongs()
        if VisualizerToggle.Value then CreateVisualizer() end
        if not conn then
            conn = RunService.Heartbeat:Connect(Update)
            api:add_connection(conn)
        end
    else
        Sound:Stop()
        DestroyVisualizer()
    end
end)

VisualizerToggle:OnChanged(function()
    if EnableToggle.Value then
        if VisualizerToggle.Value then CreateVisualizer() else DestroyVisualizer() end
    end
end)

api:on_event("unload", function()
    Sound:Stop()
    Sound:Destroy()
    DestroyVisualizer()
end)

api:notify("Music Player v2.0 Loaded!", 3)
