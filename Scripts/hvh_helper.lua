--[[
    HvH Ragebot Helper v1.0
    Advanced strafe patterns, resolver, anti-aim protection, and combat automation
    Made for Unnamed API
]]

api:set_lua_name("HvH_Helper")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local MainEvent = ReplicatedStorage:WaitForChild("MainEvent")

-- State
local state = {
    angle = 0,
    t = os.clock(),
    patternIndex = 1,
    lastPatternSwitch = 0,
    resolverHistory = {},
    hitCount = 0,
    missCount = 0,
    lastKillTime = 0,
    voidActive = false,
    manualOffset = 0,
    blinkPos = nil,
    lastBlink = 0,
    distSpamState = "Strafe", -- "Strafe" or "Void"
    lastDistSpamSwitch = 0,
    whitelist = {}, -- UserIDs or Names
    killConfirmActive = false,
}


-- ==================== UI SETUP ====================
local tabs = {
    Main = api:GetTab("Main") or api:AddTab("Main"),
    Addons = api:GetTab("Addons") or api:AddTab("Addons")
}

-- Left: Main Configuration
local mainBox = tabs.Main:AddLeftGroupbox("Main")

local strafe_enable = mainBox:AddToggle("hvh_strafe_enable", { Text = "Enabled", Default = true })
local strafe_mode = mainBox:AddDropdown("hvh_pattern", {
    Text = "Strafe Mode",
    Default = "Cyclone",
    Values = {"Cyclone", "Spiral", "Helix3D", "Quantum", "Ghost", "Unpredictable", "Reversal", "Orbit", "Star", "Infinity", "Zigzag", "Diamond", "Heart", "Clover", "Butterfly", "Rose", "DNA3D", "Tornado", "Wave3D", "Blink", "Glitch", "TeleportFlank", "Vibrate", "NullZone"},
    Multi = false
})

local strafe_cycle = mainBox:AddToggle("hvh_cycle", { Text = "Auto Cycle Modes", Default = false })
local strafe_jitter = mainBox:AddToggle("hvh_jitter", { Text = "Random Jitter", Default = false })
local strafe_rot = mainBox:AddToggle("hvh_rot", { Text = "Random Rotation", Default = false })
local strafe_newpath = mainBox:AddToggle("hvh_newpath", { Text = "Find New Path", Default = false })

local strafe_radius = mainBox:AddSlider("hvh_radius", { Text = "Radius", Default = 40, Min = 5, Max = 100, Rounding = 0, Suffix = "studs" })
local strafe_speed = mainBox:AddSlider("hvh_speed", { Text = "Speed", Default = 8, Min = 1, Max = 50, Rounding = 1, Suffix = "x" })
local strafe_lead = mainBox:AddSlider("hvh_lead", { Text = "Lead", Default = 1, Min = 0, Max = 5, Rounding = 1, Suffix = "x" })

local safety_force_unsafe = mainBox:AddToggle("hvh_unsafe", { Text = "Force Unsafe", Default = false })
local safety_vis = mainBox:AddToggle("hvh_vis_ign", { Text = "Ignore Visibility Check", Default = false })
local safety_safe = mainBox:AddToggle("hvh_safe", { Text = "Safe Mode", Default = true })
local safety_anti_pred = mainBox:AddToggle("hvh_antipred", { Text = "Anti-Predictive Path", Default = false })


-- Right: Offsets & Distance Spam
local offsetBox = tabs.Main:AddRightGroupbox("Offset")

local offset_x = offsetBox:AddSlider("hvh_off_x", { Text = "X Shift", Default = 0, Min = -50, Max = 50, Rounding = 1, Suffix = "studs" })
local offset_y = offsetBox:AddSlider("hvh_off_y", { Text = "Y Shift", Default = 0, Min = -50, Max = 50, Rounding = 1, Suffix = "studs" })
local offset_z = offsetBox:AddSlider("hvh_off_z", { Text = "Z Shift", Default = 0, Min = -50, Max = 50, Rounding = 1, Suffix = "studs" })

local offset_local = offsetBox:AddToggle("hvh_off_local", { Text = "Local Movement Bias", Default = false })
local offset_opt = offsetBox:AddToggle("hvh_off_opt", { Text = "Optimal Position", Default = false })
local offset_adapt = offsetBox:AddToggle("hvh_off_adapt", { Text = "Adaptive Prediction", Default = false })

local distBox = tabs.Main:AddRightGroupbox("Distance Spam")
local dist_enable = distBox:AddToggle("hvh_dist_enable", { Text = "Enabled", Default = false })
local dist_strafe_time = distBox:AddSlider("hvh_dist_time_s", { Text = "Strafe Time", Default = 0.75, Min = 0.1, Max = 5, Rounding = 2, Suffix = "s" })
local dist_void_time = distBox:AddSlider("hvh_dist_time_v", { Text = "Void Time", Default = 0.75, Min = 0.1, Max = 5, Rounding = 2, Suffix = "s" })
local dist_range = distBox:AddSlider("hvh_dist_range", { Text = "Range", Default = 250, Min = 50, Max = 1000, Rounding = 0 })

-- fake pos
local fakeBox = tabs.Addons:AddRightGroupbox("Fake Pos Detector")
local fake_enable = fakeBox:AddToggle("hvh_fake_enable", { Text = "Enabled", Default = true })
local fake_chams = fakeBox:AddToggle("hvh_vis_chams", { Text = "Chams", Default = true }) -- Reusing var name for compatibility if needed, or map new one

-- Manual AA inputs reused
local manualBox = tabs.Addons:AddLeftGroupbox("Manual Anti-Aim")
local manual_enable = manualBox:AddToggle("hvh_manual", { Text = "Enable Manual AA", Default = true })
local manual_left = manualBox:AddLabel("Left: Z")
local manual_back = manualBox:AddLabel("Back: X")
local manual_right = manualBox:AddLabel("Right: C")

-- Stats reused
local debugBox = tabs.Addons:AddLeftGroupbox("Debug")
local debug_enable = debugBox:AddToggle("hvh_debug", { Text = "Enable Debug", Default = false })
local debug_strafe = debugBox:AddToggle("hvh_debug_strafe", { Text = "Show Strafe Path", Default = true })
local debug_resolver = debugBox:AddToggle("hvh_debug_resolver", { Text = "Show Resolver", Default = true })
local debug_aimers = debugBox:AddToggle("hvh_debug_aimers", { Text = "Show Aimers", Default = true })
local debug_stats = debugBox:AddToggle("hvh_debug_stats", { Text = "Show Stats HUD", Default = true })

-- MAPPING VARIABLES FOR COMPATIBILITY
local strafe_walls = safety_vis -- Inverse or mapped? Let's use new logic.
local strafe_pattern = strafe_mode
local strafe_ground = safety_safe -- Mapping safe mode to ground lock roughly
local resolver_enable = offset_adapt
local resolver_mode = nil -- Removed dropdown
local resolver_strength = strafe_lead -- Mapping lead to strength roughly
local resolver_desync = offset_opt
local resolver_overshoot = offset_opt
local resolver_anti_freestand = offset_opt
local antiaim_enable = manual_enable
local antiaim_range = dist_range
local antiaim_auto = manual_enable
local antiaim_crew = manual_enable

-- NEW FEATURES UI
-- Combat
local combatBox = tabs.Addons:AddLeftGroupbox("Combat")
local glue_stomp = combatBox:AddToggle("hvh_glue_stomp", { Text = "Glue Stomp", Default = false })
local glue_range = combatBox:AddSlider("hvh_glue_range", { Text = "Stomp Range", Default = 150, Min = 50, Max = 500, Rounding = 0 })

-- Audio
local audioBox = tabs.Addons:AddRightGroupbox("Audio")
local hit_sound_enable = audioBox:AddToggle("hvh_hitsound", { Text = "Hit Sound", Default = false })
local hit_sound_id = audioBox:AddInput("hvh_sound_id", { Default = "4815416295", Numeric = true, Finished = false, Text = "Sound ID" })
local hit_sound_vol = audioBox:AddSlider("hvh_sound_vol", { Text = "Volume", Default = 1, Min = 0.1, Max = 10, Rounding = 1 })

-- Ragebot Extras
local rageBox = tabs.Main:AddLeftGroupbox("Ragebot Extras")
local kill_confirm = rageBox:AddToggle("hvh_kill_confirm", { Text = "Kill Confirm", Default = false })
local silent_offset = rageBox:AddToggle("hvh_silent_offset", { Text = "Silent Offset", Default = false })
local silent_x = rageBox:AddSlider("hvh_silent_x", { Text = "Off X", Default = 0, Min = -10, Max = 10, Rounding = 1 })
local silent_y = rageBox:AddSlider("hvh_silent_y", { Text = "Off Y", Default = 0, Min = -10, Max = 10, Rounding = 1 })
local silent_z = rageBox:AddSlider("hvh_silent_z", { Text = "Off Z", Default = 0, Min = -10, Max = 10, Rounding = 1 })

-- Safety Extra
local desync_mode = mainBox:AddDropdown("hvh_desync", { Values = {"None", "Velocity", "CFrame", "Stop"}, Default = "Velocity", Multi = false, Text = "Desync Mode" })
local desync_power = mainBox:AddSlider("hvh_desync_power", { Text = "Desync Power", Default = 500, Min = 100, Max = 10000, Rounding = 0 })

-- VOID EXTRAS
local voidBox = tabs.Addons:AddLeftGroupbox("Void Config")
local void_height = voidBox:AddSlider("hvh_void_height", { Text = "Void Height", Default = 40, Min = 40, Max = 1000, Rounding = 0 })
local void_type = voidBox:AddDropdown("hvh_void_type", { Values = {"Normal", "Stutter", "Sky"}, Default = "Normal", Multi = false, Text = "Void Type" })

-- Mapped
local auto_stomp = glue_stomp
local auto_void = nil
local auto_void_dur = nil
local auto_confirm = nil
local vis_chams = fake_chams
local vis_tracers = nil
local anti_lock = nil -- Superseded by desync_mode


-- ==================== DEBUG DRAWING ====================
local Camera = Workspace.CurrentCamera
local debugDrawings = {}

local function createCircle(name, radius, color, thickness)
    if debugDrawings[name] then debugDrawings[name]:Remove() end
    local circle = Drawing.new("Circle")
    circle.Radius = radius or 5
    circle.Color = color or Color3.new(1, 0, 0)
    circle.Thickness = thickness or 2
    circle.Filled = false
    circle.Visible = false
    debugDrawings[name] = circle
    return circle
end

local function createLine(name, color, thickness)
    if debugDrawings[name] then debugDrawings[name]:Remove() end
    local line = Drawing.new("Line")
    line.Color = color or Color3.new(1, 1, 1)
    line.Thickness = thickness or 2
    line.Visible = false
    debugDrawings[name] = line
    return line
end

local function createText(name, size, color)
    if debugDrawings[name] then debugDrawings[name]:Remove() end
    local text = Drawing.new("Text")
    text.Size = size or 16
    text.Color = color or Color3.new(1, 1, 1)
    text.Center = false
    text.Outline = true
    text.Visible = false
    debugDrawings[name] = text
    return text
end

-- Skeleton Connections
local skeletonBones = {
    {"Head", "Neck"}, {"Neck", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}, {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}
}

-- Create debug drawings
local strafePath = {}
for i = 1, 32 do
    strafePath[i] = createLine("strafe_" .. i, Color3.fromRGB(0, 255, 255), 2)
end
local strafePos = createCircle("strafe_pos", 8, Color3.fromRGB(0, 255, 0), 3)
local resolverLine = createLine("resolver", Color3.fromRGB(255, 255, 0), 3)
local resolverPredicted = createCircle("resolver_predicted", 6, Color3.fromRGB(255, 165, 0), 2)
local targetCircle = createCircle("target", 10, Color3.fromRGB(255, 0, 0), 3)

-- Aimer indicators (up to 10)
local aimerCircles = {}
for i = 1, 10 do
    aimerCircles[i] = createCircle("aimer_" .. i, 15, Color3.fromRGB(255, 0, 255), 3)
end

-- Stats HUD
local statsText = createText("stats", 14, Color3.fromRGB(255, 255, 255))
statsText.Position = Vector2.new(10, 200)

local function worldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function hideAllDebug()
    for _, d in pairs(debugDrawings) do
        if d and d.Visible then d.Visible = false end
    end
end

local function cleanupDebug()
    for _, d in pairs(debugDrawings) do
        if d then pcall(function() d:Remove() end) end
    end
    debugDrawings = {}
end

-- Debug state
local debugState = {
    currentPos = Vector3.zero,
    targetPos = Vector3.zero,
    resolvedPos = Vector3.zero,
    aimers = {},
    lastUpdate = 0,
}

-- ==================== HELPER FUNCTIONS ====================

local function V(toggle, default)
    if toggle and toggle.Value ~= nil then return toggle.Value end
    return default
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerpV3(a, b, t)
    return Vector3.new(lerp(a.X, b.X, t), lerp(a.Y, b.Y, t), lerp(a.Z, b.Z, t))
end

local function face(origin, pos)
    local f = origin - pos
    local m = f.Magnitude
    if m < 1e-4 then return CFrame.new(pos) end
    f = f / m
    local up = Vector3.yAxis
    local right = f:Cross(up)
    if right.Magnitude < 1e-4 then
        right = Vector3.xAxis
    else
        right = right.Unit
    end
    up = right:Cross(f).Unit
    return CFrame.fromMatrix(pos, right, up)
end

local function groundYAt(pos, ignore)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore and {ignore} or {}
    local ray = Workspace:Raycast(pos + Vector3.new(0, 5, 0), Vector3.new(0, -50, 0), params)
    return ray and ray.Position.Y or pos.Y
end

local function adjustForObstacles(origin, target, ignore)
    local dir = (target - origin)
    if dir.Magnitude < 0.1 then return target end
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore and {ignore} or {}
    
    local ray = Workspace:Raycast(origin, dir.Unit * dir.Magnitude, params)
    if ray then
        return ray.Position - dir.Unit * 2
    end
    return target
end

local function isKnocked(p)
    if not p or not p.Character then return true end
    local be = p.Character:FindFirstChild("BodyEffects")
    if be and be:FindFirstChild("K.O") and be["K.O"].Value then return true end
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return true end
    return false
end

local function isDead(p)
    if not p or not p.Character then return true end
    local be = p.Character:FindFirstChild("BodyEffects")
    if be and be:FindFirstChild("Dead") and be["Dead"].Value then return true end
    return false
end

local function hasGun(p)
    if not p or not p.Character then return false end
    local tool = p.Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local gunNames = {"glock", "revolver", "ak", "ar", "shotgun", "smg", "rifle", "deagle", "uzi", "mac", "draco", "rpg", "tactical"}
    local name = tool.Name:lower()
    for _, g in ipairs(gunNames) do
        if name:find(g) then return true end
    end
    return false
end

local function isInCrew(p)
    if not V(antiaim_crew, true) then return false end
    local myData = LocalPlayer:FindFirstChild("DataFolder")
    local theirData = p:FindFirstChild("DataFolder")
    if myData and theirData then
        local myCrew = myData:FindFirstChild("Information") and myData.Information:FindFirstChild("Crew")
        local theirCrew = theirData:FindFirstChild("Information") and theirData.Information:FindFirstChild("Crew")
        if myCrew and theirCrew and myCrew.Value ~= "" and myCrew.Value == theirCrew.Value then
            return true
        end
    end
    return false
end

-- ==================== STRAFE PATTERNS ====================

local function pattern_quantum(r, ang)
    -- Random micro-teleports within radius
    local jitterX = (math.random() - 0.5) * r * 0.5
    local jitterZ = (math.random() - 0.5) * r * 0.5
    local baseX = r * math.cos(ang)
    local baseZ = r * math.sin(ang)
    return Vector3.new(baseX + jitterX, 0, baseZ + jitterZ)
end

local function pattern_pendulum(r, ang)
    -- Accelerating swing motion
    local swing = math.sin(ang * 2) * math.cos(ang * 0.5)
    return Vector3.new(r * swing, 0, r * math.cos(ang))
end

local function pattern_helix3d(r, ang)
    -- Corkscrew vertical movement
    local x = r * math.cos(ang)
    local z = r * math.sin(ang)
    local y = math.sin(ang * 0.5) * 8
    return Vector3.new(x, y, z)
end

local function pattern_ghost(r, ang)
    -- Brief void dips during strafe
    local x = r * math.cos(ang)
    local z = r * math.sin(ang)
    local voidDip = math.sin(ang * 3) > 0.8 and -15 or 0
    return Vector3.new(x, voidDip, z)
end

local function pattern_unpredictable(r, ang)
    -- Chaotic randomized movement
    local patterns = {
        function() return Vector3.new(r * math.cos(ang), 0, r * math.sin(ang)) end,
        function() return Vector3.new(r * math.sin(ang * 2), math.sin(ang) * 3, r * math.cos(ang)) end,
        function() return Vector3.new((math.random() - 0.5) * r * 2, 0, (math.random() - 0.5) * r * 2) end,
    }
    return patterns[math.random(1, #patterns)]()
end

local function pattern_reversal(r, ang)
    -- Sudden direction changes
    local reversePoint = math.floor(ang / math.pi) % 2 == 0
    local dir = reversePoint and 1 or -1
    return Vector3.new(r * math.cos(ang) * dir, 0, r * math.sin(ang))
end

local function pattern_orbit(r, ang)
    return Vector3.new(r * math.cos(ang), 0, r * math.sin(ang))
end

local function pattern_star(r, ang)
    local N = 5
    local p = (ang % (2 * math.pi)) / (2 * math.pi)
    local idx = math.floor(p * N)
    local t = (p * N) % 1
    local i1, i2 = idx, (idx + 2) % N
    local a1 = i1 * (2 * math.pi / N) - math.pi / 2
    local a2 = i2 * (2 * math.pi / N) - math.pi / 2
    local p1 = Vector3.new(r * math.cos(a1), 0, r * math.sin(a1))
    local p2 = Vector3.new(r * math.cos(a2), 0, r * math.sin(a2))
    return p1:Lerp(p2, t)
end

local function pattern_infinity(r, ang)
    local scale = 2 / (3 - math.cos(2 * ang))
    return Vector3.new(r * scale * math.cos(ang), 0, r * scale * math.sin(2 * ang) / 2)
end

-- NEW PATTERNS

local function pattern_spiral(r, ang)
    -- Expanding/contracting spiral
    local spiralR = r * (0.5 + 0.5 * math.sin(ang * 0.3))
    return Vector3.new(spiralR * math.cos(ang), math.sin(ang * 2) * 3, spiralR * math.sin(ang))
end

local function pattern_zigzag(r, ang)
    -- Sharp zigzag movement
    local seg = math.floor(ang / (math.pi / 4)) % 2
    local t = (ang % (math.pi / 4)) / (math.pi / 4)
    local x = seg == 0 and (t * r * 2 - r) or (r - t * r * 2)
    local z = r * math.cos(ang)
    return Vector3.new(x, 0, z)
end

local function pattern_diamond(r, ang)
    -- Diamond/square shape
    local t = (ang % (math.pi / 2)) / (math.pi / 2)
    local seg = math.floor(ang / (math.pi / 2)) % 4
    local corners = {
        Vector3.new(r, 0, 0),
        Vector3.new(0, 0, r),
        Vector3.new(-r, 0, 0),
        Vector3.new(0, 0, -r)
    }
    local c1 = corners[seg + 1]
    local c2 = corners[(seg % 4) + 1]
    return c1:Lerp(c2, t)
end

local function pattern_heart(r, ang)
    -- Heart shape
    local t = ang
    local x = r * 0.8 * (16 * math.sin(t)^3) / 16
    local z = r * 0.8 * (13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t)) / 16
    return Vector3.new(x, 0, z)
end

local function pattern_clover(r, ang)
    -- 4-leaf clover
    local cloverR = r * math.abs(math.sin(2 * ang))
    return Vector3.new(cloverR * math.cos(ang), 0, cloverR * math.sin(ang))
end

local function pattern_butterfly(r, ang)
    -- Butterfly curve
    local exp = math.exp(math.cos(ang)) - 2 * math.cos(4 * ang) - math.sin(ang / 12)^5
    local scale = r / 3
    return Vector3.new(scale * math.sin(ang) * exp, 0, scale * math.cos(ang) * exp)
end

local function pattern_rose(r, ang)
    -- Rose curve (k=5 petals)
    local k = 5
    local roseR = r * math.cos(k * ang)
    return Vector3.new(roseR * math.cos(ang), 0, roseR * math.sin(ang))
end

local function pattern_dna3d(r, ang)
    -- DNA double helix
    local strand = math.floor(ang / math.pi) % 2
    local offset = strand == 0 and 0 or math.pi
    local x = r * math.cos(ang + offset)
    local z = r * math.sin(ang + offset)
    local y = math.sin(ang * 0.5) * 6
    return Vector3.new(x, y, z)
end

local function pattern_tornado(r, ang)
    -- Tornado - starts small, expands up
    local progress = (ang % (2 * math.pi)) / (2 * math.pi)
    local tornadoR = r * (0.3 + progress * 0.7)
    local y = progress * 10
    return Vector3.new(tornadoR * math.cos(ang * 3), y, tornadoR * math.sin(ang * 3))
end

local function pattern_wave3d(r, ang)
    -- 3D wave motion
    local x = r * math.cos(ang)
    local z = r * math.sin(ang)
    local y = math.sin(ang * 2) * 4 + math.cos(ang * 3) * 2
    return Vector3.new(x, y, z)
end

local patternFuncs = {
    Quantum = pattern_quantum,
    Pendulum = pattern_pendulum,
    Helix3D = pattern_helix3d,
    Ghost = pattern_ghost,
    Unpredictable = pattern_unpredictable,
    Reversal = pattern_reversal,
    Orbit = pattern_orbit,
    Star = pattern_star,
    Infinity = pattern_infinity,
    -- New patterns
    Spiral = pattern_spiral,
    Zigzag = pattern_zigzag,
    Diamond = pattern_diamond,
    Heart = pattern_heart,
    Clover = pattern_clover,
    Butterfly = pattern_butterfly,
    Rose = pattern_rose,
    DNA3D = pattern_dna3d,
    Tornado = pattern_tornado,
    Wave3D = pattern_wave3d,
    
    Blink = function(r, ang)
        -- Teleports around randomly (Laggy visual)
        local now = os.clock()
        if now - state.lastBlink > 0.5 then
            state.blinkPos = Vector3.new(
                (math.random()-0.5) * r * 2,
                0,
                (math.random()-0.5) * r * 2
            )
            state.lastBlink = now
        end
        return state.blinkPos or Vector3.zero
    end,
    
    Glitch = function(r, ang)
        -- Extremely fast jitter
        return Vector3.new(
            (math.random()-0.5) * r * 3,
            (math.random()-0.5) * 5,
            (math.random()-0.5) * r * 3
        )
    end,

    TeleportFlank = function(r, ang)
        -- Instantly teleports behind target every second
        local now = os.clock()
        local phase = math.floor(now) % 2 == 0
        if phase then
            return Vector3.new(r, 0, r) -- Front Right
        else
            return Vector3.new(-r, 0, -r) -- Back Left
        end
    end,

    Vibrate = function(r, ang)
        -- High frequency micro-movement to break prediction
        local jit = math.sin(os.clock() * 50) * 2
        return Vector3.new(r * math.cos(ang) + jit, 0, r * math.sin(ang) + jit)
    end,

    NullZone = function(r, ang)
        -- Dips into the void (-40 Y) to avoid hitboxes
        local dip = (math.sin(ang * 5) > 0.5) and -40 or 0
        return Vector3.new(r * math.cos(ang), dip, r * math.sin(ang))
    end
}

-- ==================== RESOLVER ====================

local function updateResolverHistory(part)
    if not part then return end
    local now = os.clock()
    table.insert(state.resolverHistory, {pos = part.Position, t = now})
    while #state.resolverHistory > 10 do
        table.remove(state.resolverHistory, 1)
    end
end

local function calculateVelocity()
    local h = state.resolverHistory
    if #h < 2 then return Vector3.zero end
    local last, prev = h[#h], h[#h - 1]
    local dt = last.t - prev.t
    if dt < 0.001 then return Vector3.zero end
    return (last.pos - prev.pos) / dt
end

local function calculateAcceleration()
    local h = state.resolverHistory
    if #h < 3 then return Vector3.zero end
    local p1, p2, p3 = h[#h - 2], h[#h - 1], h[#h]
    local dt1 = p2.t - p1.t
    local dt2 = p3.t - p2.t
    if dt1 < 0.001 or dt2 < 0.001 then return Vector3.zero end
    local v1 = (p2.pos - p1.pos) / dt1
    local v2 = (p3.pos - p2.pos) / dt2
    return (v2 - v1) / ((dt1 + dt2) / 2)
end

local function detectDesync()
    local h = state.resolverHistory
    if #h < 3 then return false end
    local vel = calculateVelocity()
    return vel.Magnitude > 100
end

local function getAdaptiveMultiplier()
    local total = state.hitCount + state.missCount
    if total < 5 then return 1.0 end
    local hitRate = state.hitCount / total
    if hitRate > 0.7 then return 0.8 end
    if hitRate < 0.3 then return 1.3 end
    return 1.0
end

local function resolvePosition(part, origin, now, dt)
    if not V(resolver_enable, true) or not part then return origin end
    
    updateResolverHistory(part)
    
    local mode = V(resolver_mode, "Adaptive")
    local strength = V(resolver_strength, 1.0)
    local vel = calculateVelocity()
    local acc = calculateAcceleration()
    
    local predicted = origin
    local adaptiveMult = mode == "Adaptive" and getAdaptiveMultiplier() or 1.0
    
    if mode == "Basic" then
        predicted = origin + vel * dt * strength
    elseif mode == "Adaptive" then
        predicted = origin + vel * dt * strength * adaptiveMult
    elseif mode == "Aggressive" then
        predicted = origin + vel * dt * 1.5 + acc * dt * dt * 0.5
    elseif mode == "Predictive" then
        local jerk = acc * 0.1
        predicted = origin + vel * dt + acc * dt * dt * 0.5 + jerk * dt * dt * dt / 6
    end
    
    -- Anti-Freestanding Logic (Wall Detection)
    if V(resolver_anti_freestand, true) then
        local leftDir = (CFrame.new(origin, LocalPlayer.Character.HumanoidRootPart.Position) * CFrame.new(-5, 0, 0)).Position
        local rightDir = (CFrame.new(origin, LocalPlayer.Character.HumanoidRootPart.Position) * CFrame.new(5, 0, 0)).Position
        
        local leftWall = Workspace:Raycast(origin, leftDir - origin)
        local rightWall = Workspace:Raycast(origin, rightDir - origin)
        
        -- If wall on left, force right peek (and vice versa)
        if leftWall and not rightWall then
            predicted = predicted + (rightDir - origin).Unit * 2
        elseif rightWall and not leftWall then
            predicted = predicted + (leftDir - origin).Unit * 2
        end
    end
    
    if V(resolver_desync, true) and detectDesync() then
        -- Brute force if missing a lot
        if state.missCount > 2 then
            local angle = (state.missCount % 3 == 0) and 0 or ((state.missCount % 3 == 1) and 1.57 or -1.57)
            local offset = CFrame.Angles(0, angle, 0) * Vector3.new(0, 0, 5)
            predicted = origin + offset
        else
            predicted = lerpV3(predicted, origin, 0.5)
        end
    end
    
    if V(resolver_overshoot, true) then
        local maxDist = vel.Magnitude * dt * 2
        local delta = predicted - origin
        if delta.Magnitude > maxDist then
            predicted = origin + delta.Unit * maxDist
        end
    end
    
    return predicted
end

-- ==================== ANTI-AIM PROTECTION ====================

local function isWhitelisted(p)
    if not p then return false end
    if state.whitelist[p.Name] or state.whitelist[p.UserId] then return true end
    return false
end

local function isAimingAtMe(p)
     if isWhitelisted(p) then return false end
    if not V(antiaim_enable, true) then return false end
    if not p or not p.Character then return false end
    if p == LocalPlayer then return false end
    if isInCrew(p) then return false end
    if not hasGun(p) then return false end
    
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return false end
    
    local theirHead = p.Character:FindFirstChild("Head")
    local theirHRP = p.Character:FindFirstChild("HumanoidRootPart")
    if not theirHead or not theirHRP then return false end
    
    local dist = (myHRP.Position - theirHRP.Position).Magnitude
    if dist > V(antiaim_range, 150) then return false end
    
    local lookDir = theirHead.CFrame.LookVector
    local toMe = (myHRP.Position - theirHead.Position).Unit
    local dot = lookDir:Dot(toMe)
    
    return dot > 0.85
end

local function getClosestAimer()
    local closest, closestDist = nil, math.huge
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not isKnocked(p) and isAimingAtMe(p) then
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (myHRP.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closest, closestDist = p, dist
                end
            end
        end
    end
    return closest
end

-- ==================== COMBAT AUTOMATION ====================

local function autoStomp()
    if not V(auto_stomp, false) then return end
    
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isKnocked(p) and not isDead(p) then
            local torso = p.Character and p.Character:FindFirstChild("UpperTorso")
            if torso then
                local dist = (myHRP.Position - torso.Position).Magnitude
                if dist < V(glue_range, 150) then
                    -- GLUE STOMP LOGIC
                    local oldCF = myHRP.CFrame
                    
                    -- TP
                    myHRP.CFrame = torso.CFrame * CFrame.new(0, 3, 0)
                    -- Stomp
                    MainEvent:FireServer("Stomp")
                    
                    -- Return (Yield small amount to ensure server registration if needed, or instant)
                    -- For instant "Ghost" feel, we revert immediately
                    myHRP.CFrame = oldCF
                end
            end
        end
    end
end

local function autoVoid()
    if not V(auto_void, false) or state.voidActive then return end
    
    state.voidActive = true
    
    local voidIn = api:get_ui_object("character_prot_void_in")
    if voidIn then voidIn:SetValue(true) end
    
    task.delay(V(auto_void_dur, 2), function()
        local voidOut = api:get_ui_object("character_prot_void_out")
        if voidOut then voidOut:SetValue(true) end
        state.voidActive = false
    end)
end



-- ==================== RAGEBOT STRAFE OVERRIDE ====================

api:ragebot_strafe_override(function(position, unsafe, part)
    if not V(strafe_enable, false) then return nil end
    if unsafe then return nil end
    if not position or not part then return nil end
    
    local now = os.clock()
    local dt = math.clamp(now - state.t, 1/300, 0.15)
    state.t = now
    
    -- Distance Spam Logic
    if V(dist_enable, false) then
        local now = os.clock()
        local strafeT = V(dist_strafe_time, 0.75)
        local voidT = V(dist_void_time, 0.75)
        
        if state.distSpamState == "Strafe" and now - state.lastDistSpamSwitch > strafeT then
            state.distSpamState = "Void"
            state.lastDistSpamSwitch = now
        elseif state.distSpamState == "Void" and now - state.lastDistSpamSwitch > voidT then
            state.distSpamState = "Strafe"
            state.lastDistSpamSwitch = now
        end
        
        if state.distSpamState == "Void" then
            -- CUSTOM VOID LOGIC
            local height = V(void_height, 40)
            local vType = V(void_type, "Normal")
            local yOffset = -height
            
            if vType == "Sky" then
                yOffset = height -- Go UP instead
            elseif vType == "Stutter" then
                -- Flicker between Height and 0
                if math.random() > 0.5 then yOffset = 0 end
            end
            
            return CFrame.new(part.Position + Vector3.new(0, yOffset, 0)), part.Position + Vector3.new(0, yOffset, 0)
        end
    end

    -- Update angle
    local speed = V(strafe_speed, 8)
    state.angle = state.angle + speed * dt
    
    -- Auto cycle patterns
    if V(strafe_cycle, false) and now - state.lastPatternSwitch > 5 then
        local modes = {"Cyclone", "Spiral", "Helix3D", "Quantum"}
        local current = V(strafe_mode, "Cyclone")
        for i, m in ipairs(modes) do
            if m == current then
                local nextMode = modes[(i % #modes) + 1]
                strafe_mode:SetValue(nextMode)
                break
            end
        end
        state.lastPatternSwitch = now
    end
    
    -- Get pattern
    local patternName = V(strafe_mode, "Cyclone")
    local patternFunc = patternFuncs[patternName] or pattern_orbit
    local radius = V(strafe_radius, 40)
    
    -- Calculate offset
    local offset = patternFunc(radius, state.angle)
    
    -- Jitter / Rotation
    if V(strafe_jitter, false) then
        offset = offset + Vector3.new((math.random()-0.5)*5, 0, (math.random()-0.5)*5)
    end
    
    -- Resolve target position (using new variables)
    local origin = part.Position
    local resolvedOrigin = resolvePosition(part, origin, now, dt)
    
    -- Apply pattern offset
    local finalPos = resolvedOrigin + offset
    
    -- Apply Manual Shifts (Offset Tab)
    local shift = Vector3.new(V(offset_x, 0), V(offset_y, 0), V(offset_z, 0))
    finalPos = finalPos + shift
    
    -- Local Movement Bias
    if V(offset_local, false) then
        finalPos = finalPos + (LocalPlayer.Character.Humanoid.MoveDirection * 5)
    end

    -- Safety Checks
    if not V(safety_vis, false) then
         -- perform vis check logic here if needed, usually passed to ragebot internally
    end
    
    if V(safety_safe, true) then -- Ground lock
        local groundY = groundYAt(finalPos, LocalPlayer.Character)
        finalPos = Vector3.new(finalPos.X, groundY + 3, finalPos.Z)
    end
    
    -- Create facing CFrame
    local shootPos = resolvedOrigin
    
    -- Silent Aim Offset (Manipulate Origin)
    if V(silent_offset, false) then
        shootPos = shootPos + Vector3.new(V(silent_x, 0), V(silent_y, 0), V(silent_z, 0))
    end
    
    local result = face(shootPos, finalPos)
    
    -- Update debug state
    debugState.currentPos = finalPos
    debugState.targetPos = origin
    debugState.resolvedPos = resolvedOrigin
    
    return result, shootPos
end)

-- ==================== DEBUG RENDER LOOP ====================

local debugConn = RunService.RenderStepped:Connect(function()
    if not V(debug_enable, false) then
        hideAllDebug()
        return
    end
    
    local now = os.clock()
    
    -- Show strafe path preview
    if V(debug_strafe, true) and debugState.targetPos ~= Vector3.zero then
        local patternName = V(strafe_pattern, "Quantum")
        local patternFunc = patternFuncs[patternName] or pattern_orbit
        local radius = V(strafe_radius, 12)
        local origin = debugState.targetPos
        
        -- Draw path segments
        for i = 1, 32 do
            local ang1 = (i - 1) * (2 * math.pi / 32)
            local ang2 = i * (2 * math.pi / 32)
            local offset1 = patternFunc(radius, ang1)
            local offset2 = patternFunc(radius, ang2)
            local pos1 = origin + offset1
            local pos2 = origin + offset2
            
            local screen1, on1 = worldToScreen(pos1)
            local screen2, on2 = worldToScreen(pos2)
            
            if on1 and on2 then
                strafePath[i].From = screen1
                strafePath[i].To = screen2
                strafePath[i].Visible = true
            else
                strafePath[i].Visible = false
            end
        end
        
        -- Show current position
        local curScreen, curOn = worldToScreen(debugState.currentPos)
        if curOn then
            strafePos.Position = curScreen
            strafePos.Visible = true
        else
            strafePos.Visible = false
        end
    else
        for i = 1, 32 do strafePath[i].Visible = false end
        strafePos.Visible = false
    end
    
    -- Show resolver prediction
    if V(debug_resolver, true) and debugState.targetPos ~= Vector3.zero then
        local origScreen, origOn = worldToScreen(debugState.targetPos)
        local predScreen, predOn = worldToScreen(debugState.resolvedPos)
        
        if origOn and predOn then
            resolverLine.From = origScreen
            resolverLine.To = predScreen
            resolverLine.Visible = true
            
            resolverPredicted.Position = predScreen
            resolverPredicted.Visible = true
            
            targetCircle.Position = origScreen
            targetCircle.Visible = true
        else
            resolverLine.Visible = false
            resolverPredicted.Visible = false
            targetCircle.Visible = false
        end
    else
        resolverLine.Visible = false
        resolverPredicted.Visible = false
        targetCircle.Visible = false
    end
    
    -- Show aimers
    if V(debug_aimers, true) then
        local aimerIndex = 1
        for _, p in ipairs(Players:GetPlayers()) do
            if aimerIndex > 10 then break end
            if p ~= LocalPlayer and isAimingAtMe(p) then
                local head = p.Character and p.Character:FindFirstChild("Head")
                if head then
                    local screen, onScreen = worldToScreen(head.Position)
                    if onScreen then
                        local pulse = 12 + math.sin(now * 5) * 5
                        aimerCircles[aimerIndex].Position = screen
                        aimerCircles[aimerIndex].Radius = pulse
                        aimerCircles[aimerIndex].Color = Color3.fromRGB(255, 50, 50)
                        aimerCircles[aimerIndex].Visible = true
                        aimerIndex = aimerIndex + 1
                    end
                end
            end
        end
        -- Hide unused aimer circles
        for i = aimerIndex, 10 do
            aimerCircles[i].Visible = false
        end
    else
        for i = 1, 10 do aimerCircles[i].Visible = false end
    end
    
    -- Stats HUD
    if V(debug_stats, true) then
        local total = state.hitCount + state.missCount
        local hitRate = total > 0 and math.floor((state.hitCount / total) * 100) or 0
        local adaptiveMult = getAdaptiveMultiplier()
        local vel = calculateVelocity()
        local desyncStatus = detectDesync() and "⚠️ DESYNC" or "✓ Synced"
        
        local statsStr = string.format(
            "═══ HvH Debug ═══\n" ..
            "Pattern: %s\n" ..
            "Resolver: %s\n" ..
            "Hit Rate: %d%% (%d/%d)\n" ..
            "Adaptive Mult: %.2fx\n" ..
            "Target Vel: %.1f\n" ..
            "Status: %s\n" ..
            "Aimers: %d",
            V(strafe_pattern, "Quantum"),
            V(resolver_mode, "Adaptive"),
            hitRate, state.hitCount, total,
            adaptiveMult,
            vel.Magnitude,
            desyncStatus,
            #debugState.aimers
        )
        
        statsText.Text = statsStr
        statsText.Visible = true
    else
        statsText.Visible = false
    end
end)
api:add_connection(debugConn)

-- ==================== MAIN LOOPS ====================

-- Combat automation loop
local combatConn = RunService.Heartbeat:Connect(function()
    autoStomp()
    autoStomp()
    
    -- Update aimer list for debug
    if V(debug_enable, false) then
        debugState.aimers = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isAimingAtMe(p) then
                table.insert(debugState.aimers, p)
            end
        end
    end
end)
api:add_connection(combatConn)

-- Anti-aim auto-target loop
local antiAimConn = RunService.Heartbeat:Connect(function()
    if not V(antiaim_auto, true) then return end
    
    local aimer = getClosestAimer()
    if aimer then
        local hrp = aimer.Character and aimer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and api.set_target then
            pcall(function() api:set_target(hrp) end)
        end
    end
    
    -- KILL CONFIRM
    if V(kill_confirm, false) then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isKnocked(p) and not isDead(p) and not isWhitelisted(p) then
                local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                     pcall(function() api:set_target(hrp) end) -- Force aim at down
                     break -- Focus one at a time
                end
            end
        end
    end

    -- ADVANCED DESYNC LOGIC
    local dMode = V(desync_mode, "Velocity")
    if dMode ~= "None" then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local power = V(desync_power, 500)
            
            if dMode == "Velocity" then
                -- Random high velocity
                hrp.Velocity = Vector3.new(
                    math.random(-power, power),
                    math.random(-power, power),
                    math.random(-power, power)
                )
            elseif dMode == "Stop" then
                -- Force zero velocity (Freeze)
                hrp.Velocity = Vector3.zero
                -- Jitter CFrame slightly to prevent sleep
                hrp.CFrame = hrp.CFrame * CFrame.new(0, math.sin(os.clock()*10)*0.1, 0)
            elseif dMode == "CFrame" then
                -- Micro-Teleport Jitter
                hrp.CFrame = hrp.CFrame * CFrame.new(
                    (math.random()-0.5) * (power/100), 
                    (math.random()-0.5) * (power/100), 
                    (math.random()-0.5) * (power/100)
                )
            end
        end
    end
end)
api:add_connection(antiAimConn)

-- Hit/miss tracking for adaptive resolver
-- Hit/miss tracking & Sound
api:on_event("localplayer_hit_player", function(target, part, dmg, weapon, origin, pos)
    state.hitCount = state.hitCount + 1
    
    -- Hit Sound
    if V(hit_sound_enable, false) then
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. V(hit_sound_id, "4815416295")
        sound.Volume = V(hit_sound_vol, 1)
        sound.Parent = CoreGui
        sound:Play()
        task.delay(2, function() sound:Destroy() end)
    end
end)

-- Kill tracking for auto-void
api:on_event("player_died", function(player)
    if player ~= LocalPlayer then
        state.lastKillTime = os.clock()
        if V(auto_void, false) then
            autoVoid()
        end
    end
end)

-- Unload cleanup
api:on_event("unload", function()
    cleanupDebug()
    api:notify("HvH Helper Unloaded", 2)
end)

    api:notify("HvH Helper Unloaded", 2)
end)

-- Chat Commands
LocalPlayer.Chatted:Connect(function(msg)
    local args = msg:split(" ")
    local cmd = args[1]:lower()
    if cmd == ":w" and args[2] then
        -- Simple name match
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #args[2]) == args[2]:lower() then
                state.whitelist[p.Name] = true
                api:notify("Whitelisted: " .. p.Name, 2)
            end
        end
    elseif cmd == ":uw" and args[2] then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #args[2]) == args[2]:lower() then
                state.whitelist[p.Name] = nil
                api:notify("Removed: " .. p.Name, 2)
            end
        end
    elseif cmd == ":clearw" then
        state.whitelist = {}
        api:notify("Whitelist Cleared", 2)
    end
end)

api:notify("🔥 HvH Helper v1.2 Loaded! (Rage+)", 3)

