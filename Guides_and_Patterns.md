# Unnamed Reference
> [!NOTE]
> This is a **living document**. As you analyze more scripts and learn new patterns, continue to add them here to build a comprehensive knowledge base.

## Utility
| Function | Description | Usage |
| :--- | :--- | :--- |
| `api:notify(message: string, lifetime: number?): nil` | Sends a notification. `lifetime` is optional. | `api:notify("hello", 10)` |
| `api:on_event(name: string, callback: ()->nil): RBXScriptConnection?` | Registers an event listener. | `api:on_event("unload", function() ... end)` |
| `api:get_ui_object(flag: string): table?` | Gets a UI object by flag. | `api:get_ui_object("silent_toggle"):SetValue(true)` |
| `api:add_connection(connection: RBXScriptConnection \| table): RBXScriptConnection` | Registers a connection to be cleaned up on unload. Accepts any object with a `:Disconnect()` method. | `api:add_connection({ Disconnect = function() ... end })` |
| `api:set_lua_name(name: string): nil` | Sets the script name for config storage. | `api:set_lua_name("my script")` |
| `api:get_lua_name(): string` | Gets the script name. | `print(api:get_lua_name())` |
| `api:override_key_state(key: string \| table, override: boolean): nil` | Forces a keybind state. | `api:override_key_state("silent_keybind", true)` |

## Events
| Event Name | Arguments | Description |
| :--- | :--- | :--- |
| `unload` | `()` | Triggered when script is unloading. |
| `localplayer_spawned` | `(character)` | Triggered when the local player's character spawns. |
| `localplayer_hit_player` | `(target, part, dmg, weapon, origin, pos)` | Triggered when you hit another player. |

## Ragebot
| Function | Description | Usage |
| :--- | :--- | :--- |
| `api:is_ragebot(): boolean` | Returns true if currently ragebotting. | `if api:is_ragebot() then ... end` |
| `api:set_ragebot(enabled: boolean)` | Forces ragebot enabled/disabled (override). | `api:set_ragebot(true)` |
| `api:get_ragebot_status(): (string, any?)` | Returns status and data (e.g., getting target, buying). | `status, data = api:get_ragebot_status()` |
| `api:ragebot_strafe_override(callback: ...): nil` | Overrides strafe position. callback(pos, unsafe, part). | `api:ragebot_strafe_override(function(pos, unsafe, part) return CFrame.new(...) end)` |

**Ragebot Statuses:** `inactive`, `buying` (item name), `hiding` (player), `stomping` (target torso), `killing` (target part), `reloading`, `no target`.

## Advanced Ragebot & Prediction Mechanics

### Strafe Override System (`rage bot stuff`, `newtest`)
Override the default ragebot strafing behavior with custom patterns.
```lua
api:ragebot_strafe_override(function(position, unsafe, part)
    if unsafe or not position then return end
    local angle = tick() * Speed
    local offset = Vector3.new(math.cos(angle) * Radius, 0, math.sin(angle) * Radius)
    return CFrame.new(position + offset, position) -- orbit around target
end)
```
**Strafe Patterns:** Orbit, Square, Triangle, Pentagon, Hexagon, Star, Spiral, ZigZag, Lemniscate, Rose, Butterfly, Clover, Cyclone, PingPong, Fidget, Wave, Cardioid, Superellipse, Diamond, Heart, Infinity, Random.

### Velocity Prediction (`anti-fakepos`, `newtest`)
Calculate target velocity from position history to predict future location.
```lua
local function calculateVelocity(history)
    if #history < 2 then return Vector3.zero end
    local newest = history[#history]
    local oldest = history[#history - 1]
    local dt = newest.time - oldest.time
    return dt > 0.001 and (newest.pos - oldest.pos) / dt or Vector3.zero
end
local predictedPos = currentPos + velocity * predictionStrength
```

### Acceleration Tracking (`newtest`)
Track rate of velocity change for more accurate prediction on accelerating targets.
```lua
local function calculateAcceleration(history)
    if #history < 3 then return Vector3.zero end
    local v1 = (history[2].pos - history[1].pos) / (history[2].time - history[1].time)
    local v2 = (history[3].pos - history[2].pos) / (history[3].time - history[2].time)
    return (v2 - v1) / (history[3].time - history[1].time)
end
```

### Resolver Modes (`newtest`)
Different prediction aggressiveness levels:
| Mode | Description |
| :--- | :--- |
| `Basic` | Simple velocity * predStrength |
| `Adaptive` | Velocity + Acceleration, scaled by confidence |
| `Aggressive` | Higher multipliers (1.3x), ignores confidence |
| `Predictive` | Adds "jerk" estimation (acceleration of acceleration) |

```lua
if mode == "Adaptive" then
    prediction = (velocity * 0.05 + acceleration * 0.002) * confidence
elseif mode == "Aggressive" then
    prediction = (velocity * 0.08 + acceleration * 0.004) * 1.3
elseif mode == "Predictive" then
    local jerk = acceleration * 0.02
    prediction = (velocity * 0.06 + acceleration * 0.003 + jerk) * confidence
end
```

### Desync Detection (`newtest`, `anti-fakepos`)
Detect when a target's actual position differs from their predicted position (fakepos/desync user).
```lua
local predicted = lastPos + velocity * 0.05
local actual = currentPos
local diff = (actual - predicted).Magnitude
if diff > threshold then
    isDesync = true
    desyncOffset = actual - predicted
end
-- Compensate by subtracting offset
prediction = prediction - desyncOffset * 0.5
```

### Spline Prediction (Catmull-Rom) (`anti-fakepos`)
Advanced smoothing using multiple data points for organic movement prediction.
```lua
local function getSplinePrediction(history)
    local p0 = history[#history - 3].pos
    local p1 = history[#history - 1].pos
    local p2 = history[#history].pos
    local v1 = (p2 - p0) * 0.5
    local v2 = (p2 - p1)
    return p2 + (v2 + (v2 - v1) * 0.5) * leadTime
end
```

### Aim Detection (`aim_debug_unnamed`, `anti aim protection`)
Detect when another player is aiming at you using raycast and dot product.
```lua
local theirLook = enemy.Character.Head.CFrame.LookVector
local toMe = (myHRP.Position - enemy.Character.Head.Position).Unit
local dot = theirLook:Dot(toMe)
local aimLine = enemy.Character.Head.Position + theirLook * distance
local missDistance = (aimLine - myHRP.Position).Magnitude
if dot > 0.8 and missDistance < 5 then
    print(enemy.Name .. " is aiming at me!")
end
```

### MousePos Replication (`aim_debug_unnamed`)
Da Hood replicates player mouse position in BodyEffects for more accurate aim detection.
```lua
local bodyEffects = enemy.Character:FindFirstChild("BodyEffects")
if bodyEffects then
    local mousePos = bodyEffects:FindFirstChild("MousePos")
    if mousePos then
        local aimDirection = (mousePos.Value - enemy.Character.Head.Position).Unit
    end
end
```

### Hit/Miss Adaptive Multiplier (`newtest`)
Adjust prediction strength based on whether shots are landing.
```lua
api:on_event("localplayer_hit_player", function(player, part, damage)
    hitCount = hitCount + 1
    missCount = math.max(0, missCount - 1)
    local ratio = hitCount / math.max(1, hitCount + missCount)
    multiplier = lerp(multiplier, 0.8 + ratio * 0.4, 0.2) -- 0.8 to 1.2 range
end)
```

### FakePos Resolver (`anti-fakepos`)
Detect fakepos users via ClientBullet origin mismatch and force their HRP to the real position.
```lua
MainEvent.OnClientEvent:Connect(function(mode, shooter, _, forcedOrigin)
    if mode == "ClientBullet" then
        local hrp = shooter.HumanoidRootPart
        local distance = (hrp.Position - forcedOrigin).Magnitude
        if distance > 25 then -- Threshold
            Cache[shooter] = forcedOrigin -- Store real position
            print(shooter.Name .. " is in fakepos!")
        end
    end
end)
-- During ragebot, force target to cached real position
hrp.CFrame = CFrame.new(Cache[shooter])
```

## Drawing-Based ESP System (`china hat esp`)

### Drawing Object Pool Pattern
Create reusable Drawing objects to avoid garbage collection spikes.
```lua
local function ensureData(playerId, sides)
    if drawingCache[playerId] then return drawingCache[playerId] end
    local d = { segs = {}, glow = {}, trail = {} }
    for i = 1, sides do
        d.segs[i] = { Drawing.new("Line"), Drawing.new("Triangle") }
        d.segs[i][1].ZIndex = 2
        d.segs[i][2].Filled = true
    end
    drawingCache[playerId] = d
    return d
end
```

### Color Animation Patterns
Generate animated colors for ESP elements.
```lua
local function getCol(prog, t, speed, c1, c2, anim, preset)
    if preset == "rainbow" then return Color3.fromHSV((prog + t * speed) % 1, 1, 1) end
    if anim == "Pulse" then return lerpColor(c1, c2, (math.sin(t * speed * 5) + 1) * 0.5) end
    if anim == "Strobe" then return math.floor(t * speed * 10) % 2 == 0 and c1 or c2 end
    if anim == "Disco" then return Color3.fromHSV(math.random(), 1, 1) end
    -- Gradient default
    local s = (prog + t * speed) % 1
    if s < 0.25 then return lerpColor(c1, c2, s * 4) end
    -- ... continues for 4-color gradient
end
```

### 3D Shape Rendering (`cone`, `star`, `wings`, `spiral`)
Render 3D shapes as 2D triangles using WorldToViewportPoint.
```lua
for i = 1, sides do
    local angle1, angle2 = (i / sides) * math.pi * 2, ((i+1) / sides) * math.pi * 2
    local pt1 = basePos + Vector3.new(math.cos(angle1) * radius, 0, math.sin(angle1) * radius)
    local pt2 = basePos + Vector3.new(math.cos(angle2) * radius, 0, math.sin(angle2) * radius)
    local s1 = Camera:WorldToViewportPoint(pt1)
    local s2 = Camera:WorldToViewportPoint(pt2)
    local sTop = Camera:WorldToViewportPoint(topPos)
    triangle.PointA = Vector2.new(sTop.X, sTop.Y)
    triangle.PointB = Vector2.new(s1.X, s1.Y)
    triangle.PointC = Vector2.new(s2.X, s2.Y)
end
```

## Auto Kill/Stomp State Machine (`auto_kill_v2`, `auto_stomp_v2`)

### State Machine Pattern
Manage complex kill flow with discrete states.
```lua
local State = { Target = nil, Mode = "idle", LastBagAttempt = 0 }
-- Modes: idle, killing, stomping, bagging
local function RunLoop()
    if isKnocked(target) then
        State.Mode = Toggles.ak_autostomp.Value and "stomping" or "bagging"
    else
        State.Mode = "killing"
    end
    -- Apply mode-specific logic
    if State.Mode == "stomping" then MainEvent:FireServer("Stomp") end
end
```

### Aggressive Sticky Glue
Use hidden property to physically attach to target.
```lua
if Toggles.sticky.Value and sethiddenproperty then
    sethiddenproperty(myRoot, "PhysicsRepRootPart", targetRoot)
end
api:set_desync_cframe(CFrame.new(targetRoot.Position + Vector3.new(0, height, 0)))
-- Unglue on mode change
sethiddenproperty(myRoot, "PhysicsRepRootPart", nil)
```

## 3D Strafe Patterns ([whip.txt](file:///C:/Users/hayde/AppData/Local/seliware-workspace/unnamed/da%20hood/lua/scripts/whip.txt), [newtest.lua](file:///C:/Users/hayde/AppData/Local/seliware-workspace/unnamed/da%20hood/lua/scripts/newtest.lua))

### Helix3D Pattern
Corkscrew spiral with vertical oscillation.
```lua
local function pat_Helix3D(origin, targetPart, r, ang, height)
    local x = r * math.cos(ang)
    local z = r * math.sin(ang)
    local y = height + (30 * math.sin(ang * 0.5))
    return origin + Vector3.new(x, y, z)
end
```

### Sphere3D Pattern
Move on the surface of a sphere around target.
```lua
local function pat_Sphere3D(r, ang, height)
    local theta = ang -- Azimuthal
    local phi = math.sin(ang * 0.7) * math.pi * 0.6 -- Polar oscillates
    return Vector3.new(
        r * math.sin(phi) * math.cos(theta),
        height + r * math.cos(phi),
        r * math.sin(phi) * math.sin(theta)
    )
end
```

### DNA3D Pattern
Double helix with strand switching.
```lua
local strand = (math.floor(ang * 2) % 2 == 0) and 1 or -1
local offsetAng = strand == 1 and ang or (ang + math.pi)
local x = r * math.cos(offsetAng)
local z = r * math.sin(offsetAng)
local y = height + (25 * math.sin(ang * 0.8))
```

## Projectile Manipulation (`grenade teleport`, `snowball`, `rpg v2`)

### Desync Callback for Remote Grab
Use desync callback to grab items from a distance.
```lua
api:add_desync_callback(2, function()
    if isGrabbing then
        return snowballLocation -- CFrame to teleport server-side
    end
    return nil
end)
-- Then fire event
ReplicatedStorage.MainEvent:FireServer("PickSnow")
```

### Hidden Property Teleport (Grenades)
Teleport projectiles using sethiddenproperty.
```lua
local function TeleportGrenade(grenade)
    local handle = grenade:FindFirstChild("Handle")
    if sethiddenproperty then
        sethiddenproperty(handle, "CFrame", target.Character.HumanoidRootPart.CFrame)
        sethiddenproperty(handle, "Velocity", Vector3.zero)
        sethiddenproperty(handle, "RotVelocity", Vector3.zero)
    end
end
-- Monitor workspace for new grenades
Workspace.ChildAdded:Connect(function(child)
    if child.Name:lower():find("grenade") then TeleportGrenade(child) end
end)
```

## Fake Position Modular Architecture (`Fake Position.lua`)

### Connection Handler Pattern
Manage multiple connections with named keys and cleanup.
```lua
local Connections = {}
function AddConnection(name, connection)
    if Connections[name] then Connections[name]:Disconnect() end
    Connections[name] = connection
end
function Disconnect(names, silent)
    for _, name in pairs(names) do
        if Connections[name] then
            Connections[name]:Disconnect()
            Connections[name] = nil
        end
    end
end
```

### Mod Detection System
Check player group membership and kick if moderator detected.
```lua
local function Check(player)
    local staffGroups = {10604500, 17215700, 8068202}
    for _, groupId in pairs(staffGroups) do
        local inGroup, role = pcall(player.GetRoleInGroup, player, groupId)
        if inGroup and role:lower():find("admin") then
            LocalPlayer:Kick("Mod detected: " .. player.Name)
        end
    end
end
Players.PlayerAdded:Connect(Check)
```

### Auto Bounty Poster Targeting
Read bounty poster to auto-target player.
```lua
local PosterTexts = workspace.MAP.BountyPosters.Poster.Texts
local PlayerPoster = PosterTexts.PlayerName.SurfaceGui.TextLabel
if PlayerPoster.Text ~= "" and PlayerPoster.Text ~= LocalPlayer.Name then
    local target = Players:FindFirstChild(PlayerPoster.Text)
    Options["ragebot_targets"]:SetValue(target.Name)
end
```

## Chat Command Bot System ([bot.txt](file:///C:/Users/hayde/AppData/Local/seliware-workspace/unnamed/da%20hood/lua/scripts/bot.txt))

### Chat Message Parser
Listen for chat commands from an owner player.
```lua
local function ParseArgs(message, prefix)
    local command = message:match("^" .. prefix .. "(%S+)")
    local argString = message:match("^" .. prefix .. "%S+%s+(.+)") or ""
    local args = {}
    for arg in argString:gmatch("[^,%s]+") do
        table.insert(args, arg)
    end
    return command, args
end
-- Listen to TextChatService or legacy chat
TextChatService.MessageReceived:Connect(function(msg)
    if msg.TextSource.UserId == OwnerUserId then
        local cmd, args = ParseArgs(msg.Text, ".")
        ExecuteCommand(cmd, args)
    end
end)
```

### Fuzzy Player Name Matching (Levenshtein)
Find players by partial or misspelled names.
```lua
local function levenshtein(s1, s2)
    local matrix = {}
    for i = 0, #s1 do matrix[i] = {[0] = i} end
    for j = 0, #s2 do matrix[0][j] = j end
    for i = 1, #s1 do
        for j = 1, #s2 do
            local cost = (s1:sub(i,i) == s2:sub(j,j)) and 0 or 1
            matrix[i][j] = math.min(matrix[i-1][j]+1, matrix[i][j-1]+1, matrix[i-1][j-1]+cost)
        end
    end
    return matrix[#s1][#s2]
end
-- Use: if distance <= 3, consider it a match
```

### Location Teleport Map
Store named locations for quick teleport commands.
```lua
local SaveLocations = {
    bank = Vector3.new(-440, 38, -289),
    military = Vector3.new(37, 25, -892),
    aug = Vector3.new(-265, 52, -223),
    -- ... 20+ locations
}
local function TeleportToLocation(name)
    local pos = SaveLocations[name:lower()]
    if pos then api:teleport(CFrame.new(pos)) end
end
```

## Custom HUD System (`custom ui.lua`)

### Draggable UI Frame
Make any frame draggable with mouse.
```lua
local function MakeDraggable(frame)
    local dragging, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                        startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
```

### Live HUD Bar Update
Update health/armor/energy bars from character data.
```lua
RunService.RenderStepped:Connect(function()
    local hum = char:FindFirstChild("Humanoid")
    local be = char:FindFirstChild("BodyEffects")
    if hum then
        healthBar.Fill.Size = UDim2.new(math.clamp(hum.Health/hum.MaxHealth, 0, 1), 0, 1, 0)
    end
    if be and be:FindFirstChild("Armor") then
        armorBar.Fill.Size = UDim2.new(math.clamp(be.Armor.Value/100, 0, 1), 0, 1, 0)
    end
end)
```

## Velocity Fling ([flingtool.lua](file:///C:/Users/hayde/AppData/Local/seliware-workspace/unnamed/da%20hood/lua/scripts/flingtool.lua))

### Unanchored Part Physics Control
Find and manipulate unanchored map parts for flinging.
```lua
for _, part in ipairs(workspace.MAP:GetChildren()) do
    if part:IsA("Part") and not part.Anchored then
        UnanchoredPart = part
        break
    end
end
-- Control with BodyPosition + BodyThrust
local bp = Instance.new("BodyPosition", UnanchoredPart)
bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
bp.Position = targetPos
local bt = Instance.new("BodyThrust", UnanchoredPart)
bt.Force = Vector3.new(-10000, -10000, -10000)
```

### Simulation Radius Override
Extend physics simulation range.
```lua
pcall(function()
    sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
    part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
end)
```

## Camera Lock System (`face camera lock.lua`)

### Camera Direction Modes
Lock camera to head direction or fixed angles.
```lua
local function getCameraPosition()
    local headLook = head.CFrame.LookVector
    local mode = CamMode.Value
    if mode == "Head Direction" then
        return CFrame.new(head.Position - headLook * dist + Vector3.new(0, yOffset, 0),
                          head.Position + headLook * 100)
    elseif mode == "Behind" then
        return CFrame.new(head.Position - hrp.CFrame.LookVector * dist, head.Position)
    end
end
Camera.CFrame = Camera.CFrame:Lerp(targetCF, smoothSpeed * 0.016)
```

## Fake Kick Screen (`fake kick.lua`)

### Custom Disconnect Screen Replacement
Replace Roblox error screen with custom image.
```lua
RunService.RenderStepped:Connect(function()
    local prompt = CoreGui:FindFirstChild("RobloxPromptGui")
    if prompt and prompt:FindFirstChild("promptOverlay") then
        local errPrompt = prompt.promptOverlay:FindFirstChild("ErrorPrompt")
        if errPrompt and prompt.Enabled then
            prompt.Enabled = false -- Hide Roblox screen
            ShowCustomScreen() -- Show our custom image
        end
    end
end)
```

## 3D Pyramid Hat (`3d china hat.lua`)

### Procedural WedgePart Generation
Generate solid pyramid with variable sides using WedgeParts.
```lua
for i = 1, sides do
    local angle1 = ((i-1) / sides) * math.pi * 2 + rotAngle
    local angle2 = (i / sides) * math.pi * 2 + rotAngle
    local p1 = baseCenter + Vector3.new(math.cos(angle1) * radius, 0, math.sin(angle1) * radius)
    local p2 = baseCenter + Vector3.new(math.cos(angle2) * radius, 0, math.sin(angle2) * radius)
    local midChord = (p1 + p2) / 2
    local distToCenter = (midChord - baseCenter).Magnitude
    wedge.Size = Vector3.new((p1 - p2).Magnitude, height, distToCenter)
    wedge.CFrame = CFrame.lookAt(baseCenter + Vector3.new(0, height/2, 0) + (midChord - baseCenter).Unit * distToCenter/2,
                                  midChord)
end
```

## Auto Bag System (`auto bag.lua`)

### Christmas_Sock Detection
Detect when target is successfully bagged.
```lua
local function is_target_bagged(target)
    local model = workspace.Players.Model:FindFirstChild(target.Name)
    return model and model:FindFirstChild("Christmas_Sock") ~= nil
end
```

### Void Entry/Exit via UI Objects
Control void protection through API objects.
```lua
local function enter_void()
    local voidIn = api:get_ui_object("character_prot_void_in")
    if voidIn then voidIn:SetValue(true) end
end
local function exit_void()
    local voidOut = api:get_ui_object("character_prot_void_out")
    if voidOut then voidOut:SetValue(true) end
end
```

## Math VFX System ([MathVFX_Addon_AllTargets.lua](file:///C:/Users/hayde/AppData/Local/seliware-workspace/unnamed/da%20hood/lua/scripts/MathVFX_Addon_AllTargets.lua))

### Billboard Symbol Spawning
Create floating text symbols around targets.
```lua
local function spawnSymbol()
    local pos = targetPos + Vector3.new(math.cos(angle) * radius, math.sin(elev) * radius, math.sin(angle) * radius)
    local part = Instance.new("Part")
    part.Anchored, part.CanCollide, part.Transparency = true, false, 1
    part.Position = pos
    local billboard = Instance.new("BillboardGui", part)
    billboard.AlwaysOnTop = true
    local label = Instance.new("TextLabel", billboard)
    label.Text = mathSymbols[math.random(#mathSymbols)] -- "π", "√", "∫", etc.
    label.TextColor3 = Color3.fromHSV(tick() % 1, 1, 1)
    part.Parent = workspace.VFXFolder
end
```

### Target Position Fallback
Get target from ragebot → aimbot → silent → last known.
```lua
local function getTargetPosition()
    for _, mode in {"ragebot", "aimbot", "silent"} do
        local target = api:get_target(mode)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            lastTargetPos = target.Character.HumanoidRootPart.Position
            return lastTargetPos
        end
    end
    return lastTargetPos -- Fallback
end
```

## Glue System ([glue.txt](file:///C:/Users/hayde/AppData/Local/seliware-workspace/unnamed/da%20hood/lua/scripts/glue.txt))

### Position + Rotation Presets
Store common glue configurations.
```lua
local Presets = {
    Above = Vector3.new(0, 5, 0),
    Below = Vector3.new(0, -5, 0),
    Front = Vector3.new(0, 0, -5),
    Behind = Vector3.new(0, 0, 5),
}
Options['preset_positions']:OnChanged(function(val)
    GlueOffset = Presets[val] or GlueOffset
end)
```

### Euler Angle CFrame Construction
Build rotation from pitch/yaw/roll sliders.
```lua
GlueAngle = CFrame.Angles(math.rad(pitch), math.rad(yaw), math.rad(roll))
local desyncCFrame = CFrame.new(TargetPart.Position + GlueOffset) * GlueAngle
api:set_desync_cframe(desyncCFrame)
```

## Unanchored Part Scanner ([check_unanchored.lua](file:///C:/Users/hayde/AppData/Local/seliware-workspace/unnamed/da%20hood/lua/scripts/check_unanchored.lua))

### Workspace Part Discovery
Find and highlight all unanchored parts (excluding players).
```lua
for _, desc in ipairs(workspace:GetDescendants()) do
    if desc:IsA("BasePart") and not desc.Anchored then
        if not Players:GetPlayerFromCharacter(desc:FindFirstAncestorOfClass("Model")) then
            local box = Instance.new("SelectionBox")
            box.Adornee = desc
            box.Color3 = desc:IsA("Seat") and Color3.new(0,1,0) or Color3.new(1,0,0)
            box.Parent = VisualsFolder
        end
    end
end
```

### Seat Claiming via Sit
Teleport, sit, move seat, then exit.
```lua
local function BringSeats()
    for _, seat in ipairs(seats) do
        hrp.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
        seat:Sit(humanoid)
        task.wait(0.15)
        pcall(function() seat:SetNetworkOwner(LocalPlayer) end)
        seat.CFrame = originalCFrame + Vector3.new(0, 5, 0)
        humanoid.Sit = false
    end
end
```

## Currency Tracker (`ammo logger.txt`)

### Silent Target Money Watcher
Monitor target's currency and copy position when it decreases.
```lua
local prevCurrency = {}
RunService.Heartbeat:Connect(function()
    local target = api:get_target("silent")
    if target then
        local cash = api:get_data_cache(target).Currency
        if prevCurrency[target] and cash < prevCurrency[target] then
            copyToClipboard(string.format("CFrame.new(%f, %f, %f)", pos.X, pos.Y, pos.Z))
        end
        prevCurrency[target] = cash
    end
end)
```

## World Texture Changer (`Texture Buy Pad Customizer.txt`)

### Global Material Override
Change all world parts to a specific material.
```lua
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") and not isPlayerPart(obj) then
        changedWorldParts[obj] = obj.Material
        obj.Material = Enum.Material.Neon
    end
end
```

### Buy Pad Effects (Rainbow + Glow)
Apply effects to shop pads.
```lua
local function applyPadEffects()
    for _, pad in pairs(getAllBuyPads()) do
        local head = pad:FindFirstChild("Head")
        head.Material = Enum.Material[padsMaterial]
        head.Color = padsRainbow and Color3.fromHSV(hue, 1, 1) or padsColor
        local light = Instance.new("PointLight", head)
        light.Brightness, light.Range = 2, 20
    end
end
```



## China Hat V2 ([china_hat_v2.lua](file:///C:/Users/hayde/AppData/Local/seliware-workspace/unnamed/da%20hood/lua/scripts/china_hat_v2.lua))

### Drawing Object Pool with Side Scaling
Dynamically adjust polygon sides based on distance (LOD).
```lua
local dist = (Camera.CFrame.Position - head.Position).Magnitude
local renderSides = Sides.Value
if dist > 100 then renderSides = math.floor(renderSides / 2) end
if dist > 300 then renderSides = 4 end
local drawings = GetDrawings(plr, renderSides)
```

### Health-Based Color Mapping
Color ESP based on player health.
```lua
if HealthColor.Value then
    local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
    local hpColor = Color3.fromHSV(hp * 0.33, 1, 1) -- Green→Red
    c1, c2 = hpColor, hpColor
end
```

## Anti-Fakepos Resolver ([anti-fakepos.lua](file:///C:/Users/hayde/AppData/Local/seliware-workspace/unnamed/da%20hood/lua/scripts/anti-fakepos.lua))

### ClientBullet Origin Detection
Detect fakepos by comparing bullet origin to shooter position.
```lua
MainEvent.OnClientEvent:Connect(function(mode, shooter, _, forcedOrigin)
    if mode == "ClientBullet" then
        local hrp = shooter:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - forcedOrigin).Magnitude > threshold then
            -- Shooter is in fakepos, cache real position
            upsertEntryForModel(shooter, forcedOrigin)
        end
    end
end)
```

### Position History with Prediction
Store position history for velocity prediction.
```lua
entry.history = {}
table.insert(entry.history, { t = tick(), p = forcedOrigin })
if #entry.history > 20 then table.remove(entry.history, 1) end
-- Apply prediction mode: "none", "last-2", "averaged", "extrapolated-spline"
```

## Auto Bounty Stomper ([auto_bounty_stomp.lua](file:///C:/Users/hayde/AppData/Local/seliware-workspace/unnamed/da%20hood/lua/scripts/auto_bounty_stomp.lua))

### Bounty Poster Reader
Extract target names from in-world posters.
```lua
local function RefreshTargets()
    for _, poster in ipairs(workspace.MAP.BountyPosters:GetChildren()) do
        local name = poster.Texts.PlayerName.SurfaceGui.TextLabel.Text
        if name ~= "" and name ~= LocalPlayer.Name then
            BountyTargets[name] = true
        end
    end
end
```

### Glue Stomp Loop
Continuously stomp while target is knocked.
```lua
while tick() - stompTime < MAX_STOMP_DURATION do
    local ko = targetChar.BodyEffects["K.O"]
    if not ko or not ko.Value then break end
    sethiddenproperty(root, "PhysicsRepRootPart", targetRoot)
    api:set_desync_cframe(CFrame.new(targetRoot.Position + Vector3.new(0, stompHeight, 0)))
    ReplicatedStorage.MainEvent:FireServer("Stomp")
    RunService.Heartbeat:Wait()
end
sethiddenproperty(root, "PhysicsRepRootPart", nil) -- Clean up
```

## Auto Loader (`auto loader.lua`)

### Game ID Detection
Check if running in correct game before loading scripts.
```lua
local TargetGameId = 2788229376 -- Da Hood
if game.PlaceId == TargetGameId then
    -- Load game-specific scripts
    loadstring(game:HttpGet("https://example.com/loader.lua"))()
end
```

### Interactive Notification Prompt
Use BindableFunction for Yes/No notifications.
```lua
local bindable = Instance.new("BindableFunction")
bindable.OnInvoke = function(buttonName)
    if buttonName == "Yes" then
        loadstring(game:HttpGet(scriptUrl))()
    end
end
StarterGui:SetCore("SendNotification", {
    Title = "Load Script?",
    Text = "Do you want to load?",
    Duration = 9e9, -- Persist until clicked
    Callback = bindable,
    Button1 = "Yes",
    Button2 = "No"
})
```

### ForceField Wait
Wait for spawn protection before starting.
```lua
local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
if char:FindFirstChildOfClass("ForceField") then
    repeat task.wait(1) until not char:FindFirstChildOfClass("ForceField")
end
```

## Damage Logger ([damage_logger_debug.lua](file:///C:/Users/hayde/AppData/Local/seliware-workspace/unnamed/da%20hood/lua/scripts/damage_logger_debug.lua))

### Health Change Monitoring
Track damage via HealthChanged signal.
```lua
humanoid.HealthChanged:Connect(function(newHealth)
    local damage = oldHealth - newHealth
    if damage > 0.1 then
        local creator = humanoid:FindFirstChild("creator")
        local attacker = creator and creator.Value
        logDamage(player.Name, attacker.Name, damage, weaponType)
    end
    oldHealth = newHealth
end)
```

### Nearby Attacker Detection
Find melee attackers by proximity.
```lua
local function findNearbyAttacker(victimChar)
    local victimPos = victimChar.HumanoidRootPart.Position
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local dist = (p.Character.HumanoidRootPart.Position - victimPos).Magnitude
            if dist < meleeRange then
                return p, getWeaponType(p.Character:FindFirstChildWhichIsA("Tool"))
            end
        end
    end
end
```

### Weapon Type Classification
Classify tools as melee or gun.
```lua
local MELEE_WEAPONS = {"knife", "bat", "whip", "taser"}
local GUN_WEAPONS = {"glock", "revolver", "smg", "ak47", "aug"}
local function getWeaponType(tool)
    local name = tool.Name:lower()
    for _, w in ipairs(MELEE_WEAPONS) do
        if name:find(w) then return "Melee" end
    end
    for _, w in ipairs(GUN_WEAPONS) do
        if name:find(w) then return "Gun" end
    end
    return "Unknown"
end
```

## Skin Changer ([dahood_skin_changer.lua](file:///C:/Users/hayde/.gemini/antigravity/scratch/dahood_skin_changer.lua))

### Dynamic Skin Discovery
Scan ReplicatedStorage for all available skins.
```lua
local MeshesFolder = ReplicatedStorage.SkinModules.Meshes
local AllSkins = {}
for _, skinFolder in ipairs(MeshesFolder:GetChildren()) do
    if skinFolder:IsA("Folder") then
        table.insert(AllSkins, skinFolder.Name)
        SkinData[skinFolder.Name] = {}
        for _, mesh in ipairs(skinFolder:GetChildren()) do
            SkinData[skinFolder.Name][mesh.Name] = mesh
        end
    end
end
```

### Weapon Skin Application
Apply skin textures to weapon Default parts.
```lua
local function ApplySkinToWeapon(weapon, skinName)
    local skinMeshes = SkinData[skinName]
    for meshName, meshTemplate in pairs(skinMeshes) do
        if WeaponMapping[meshName] == weapon.Name then
            local defaultPart = weapon:FindFirstChild("Default") or weapon:FindFirstChild("Handle")
            if defaultPart and meshTemplate:IsA("MeshPart") then
                defaultPart.TextureID = meshTemplate.TextureID
                defaultPart.MeshId = meshTemplate.MeshId
            end
        end
    end
end
```

### Original Texture Restoration
Cache and restore original textures.
```lua
local OriginalTextures = {}
if not OriginalTextures[weaponName] then
    OriginalTextures[weaponName] = {
        MeshId = defaultPart.MeshId,
        TextureID = defaultPart.TextureID
    }
end
-- Restore
for weaponName, original in pairs(OriginalTextures) do
    local weapon = char:FindFirstChild(weaponName)
    if weapon then
        weapon.Handle.MeshId = original.MeshId
        weapon.Handle.TextureID = original.TextureID
    end
end
```

## Grip Desync (`a test.lua`, `ggrip pos.txt`)

### Tool Grip Modification
Modify tool grip to offset weapon position.
```lua
local originalGrips = {}
if not originalGrips[tool] then
    originalGrips[tool] = tool.Grip
end
local worldOffset = targetPos - myPos
local gripPosOffset = Vector3.new(x, y, z)
local gripRotOffset = CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))
tool.Grip = originalGrips[tool] * CFrame.new(worldOffset + gripPosOffset) * gripRotOffset
```

### Silent Target Lock
Lock server position above silent aim target.
```lua
local function getSilentRootCF()
    local plr = api:get_target_cache("silent").player
    local charCache = api:get_character_cache(plr)
    local rootCF = charCache.HumanoidRootPart.CFrame
    return rootCF * CFrame.new(sidewaysOffset, heightOffset, forwardOffset)
end
if lockEnabled then
    api:set_desync_cframe(getSilentRootCF())
end
```



### Custom Draggable GUI with syn.protect_gui
Protect UI from detection and make draggable.
```lua
local ScreenGui = Instance.new("ScreenGui")
if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
elseif gethui then
    ScreenGui.Parent = gethui()
end
MainFrame.Active = true
MainFrame.Draggable = true
```

---

# 🎯 RAGEBOT DEEP DIVE: Advanced Combat Mechanics

---

## Core Strafe Override System

### The `ragebot_strafe_override` Function
The core API for overriding ragebot positioning. Returns a CFrame for your desync position.
```lua
api:ragebot_strafe_override(function(position, unsafe, part)
    -- position: Vector3 - default target position
    -- unsafe: boolean - true if hitting this position would be risky
    -- part: BasePart - target's body part (usually HumanoidRootPart)
    
    if unsafe then return nil end -- Let ragebot handle it
    
    local newPos = calculateNewPosition(position)
    local shootPos = part.Position
    local facingCFrame = face(shootPos, newPos)
    
    return facingCFrame, shootPos -- Return CFrame and aim point
end)
```

### CFrame Facing Helper
Calculate a CFrame that faces toward a target position.
```lua
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
```

---

## 🔄 Orbit & Strafe Patterns

### Basic Circular Orbit
Classic orbit around target position.
```lua
local function pattern_orbit(r, ang)
    return Vector3.new(r * math.cos(ang), 0, r * math.sin(ang))
end
```

### Polygon Patterns (Triangle, Pentagon, Hexagon)
Edge-following polygonal paths.
```lua
local function pattern_polygon(r, ang, sides)
    local p = (ang % (2 * math.pi)) / (2 * math.pi)
    local seg = math.floor(p * sides)
    local t = (p * sides) % 1
    local a1 = seg * (2 * math.pi / sides) - math.pi/2
    local a2 = (seg + 1) * (2 * math.pi / sides) - math.pi/2
    local p1 = Vector3.new(r * math.cos(a1), 0, r * math.sin(a1))
    local p2 = Vector3.new(r * math.cos(a2), 0, r * math.sin(a2))
    return p1:Lerp(p2, t)
end
```

### Star Pattern (Pentagram)
Skip-vertex star shape for unpredictable movement.
```lua
local function pattern_star(r, ang)
    local N = 5
    local p = (ang % (2 * math.pi)) / (2 * math.pi)
    local idx = math.floor(p * N)
    local t = (p * N) % 1
    local i1 = idx
    local i2 = (idx + 2) % N -- Skip one vertex
    local a1 = i1 * (2 * math.pi / N) - math.pi/2
    local a2 = i2 * (2 * math.pi / N) - math.pi/2
    local p1 = Vector3.new(r * math.cos(a1), 0, r * math.sin(a1))
    local p2 = Vector3.new(r * math.cos(a2), 0, r * math.sin(a2))
    return p1:Lerp(p2, t)
end
```

### Lemniscate (Figure-8 / Infinity)
Smooth infinity loop pattern.
```lua
local function pattern_lemniscate(r, ang)
    local a = r * 0.75
    local c = math.cos(2 * ang)
    local rho = (c > 0) and math.sqrt(2) * a * math.sqrt(c) or r * 0.1
    return Vector3.new(rho * math.cos(ang), 0, rho * math.sin(ang))
end
```

### Rose Pattern (Multi-Petal Flower)
Complex petal pattern for maximum evasion.
```lua
local function pattern_rose(r, ang)
    local petals = 5
    local rho = r * math.max(0.1, math.abs(math.cos(petals * ang)))
    return Vector3.new(rho * math.cos(ang), 0, rho * math.sin(ang))
end
```

### Butterfly Curve
Exotic mathematical curve.
```lua
local function pattern_butterfly(r, t)
    local rr = math.exp(math.sin(t)) - 2 * math.cos(4 * t) + (math.sin((2*t - math.pi) / 24))^5
    local s = r * 0.35
    return Vector3.new(s * rr * math.cos(t), 0, s * rr * math.sin(t))
end
```

### Heart Pattern
Heart-shaped movement.
```lua
local function pattern_heart(r, t)
    local scale = r * 0.055
    local x = 16 * math.sin(t)^3
    local z = 13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t)
    return Vector3.new(x * scale, 0, -z * scale)
end
```

---

## 🌀 3D Strafe Patterns

### Helix3D (Corkscrew)
Vertical oscillation with horizontal orbit.
```lua
local function pat_Helix3D(origin, targetPart, r, ang, height)
    local shoot_pos = targetPart.Position
    local x = r * math.cos(ang)
    local z = r * math.sin(ang)
    local y = height + (30 * math.sin(ang * 0.5))
    return shoot_pos + Vector3.new(x, y, z), shoot_pos
end
```

### Sphere3D (Spherical Surface)
Movement across a spherical shell.
```lua
local function pat_Sphere3D(origin, targetPart, r, ang, height)
    local shoot_pos = targetPart.Position
    local theta = ang
    local phi = math.sin(ang * 0.7) * math.pi * 0.6
    local sphere_r = r * 1.2
    local x = sphere_r * math.sin(phi) * math.cos(theta)
    local y = height + sphere_r * math.cos(phi)
    local z = sphere_r * math.sin(phi) * math.sin(theta)
    return shoot_pos + Vector3.new(x, y, z), shoot_pos
end
```

### Tornado3D (Ascending Spiral)
Spiraling upward with decreasing radius.
```lua
local function pat_Tornado3D(origin, targetPart, r, ang, height)
    local shoot_pos = targetPart.Position
    local cycles = 3
    local progress = (ang / (2 * math.pi * cycles)) % 1
    local current_r = r * (1 - progress * 0.6)
    local x = current_r * math.cos(ang * cycles)
    local z = current_r * math.sin(ang * cycles)
    local y = height + (50 * progress)
    return shoot_pos + Vector3.new(x, y, z), shoot_pos
end
```

### DNA3D (Double Helix)
Two-strand DNA pattern with cross-linking.
```lua
local function pat_DNA3D(origin, targetPart, r, ang, height)
    local shoot_pos = targetPart.Position
    local strand = (math.floor(ang * 2) % 2 == 0) and 1 or -1
    local offset_ang = strand == 1 and ang or (ang + math.pi)
    local x = r * math.cos(offset_ang)
    local z = r * math.sin(offset_ang)
    local y = height + (25 * math.sin(ang * 0.8))
    -- Cross-linking between strands
    local link_factor = math.abs(math.sin(ang * 2))
    if link_factor > 0.9 then x, z = x * 0.5, z * 0.5 end
    return shoot_pos + Vector3.new(x, y, z), shoot_pos
end
```

---

## ⬇️ Void Strafe System

### Void Mode Types
```lua
local VOID_MODES = {"Bait", "Spam", "Dynamic", "Jitter", "Adaptive"}
```

### Bait Mode (Classic)
Alternates between deep void and bait height.
```lua
if mode == "Bait" then
    local cycleTime = inTime + outTime
    state.void_timer = state.void_timer + dt
    local cyclePos = state.void_timer % cycleTime
    if cyclePos < inTime then
        yOffset = -depth  -- In void
    else
        yOffset = baitHeight  -- Bait above ground
    end
end
```

### Spam Mode
Rapid switching between void and surface.
```lua
if mode == "Spam" then
    local switchTime = (inTime + outTime) / 2
    if now - state.void_last_switch >= switchTime then
        state.void_in = not state.void_in
        state.void_last_switch = now
    end
    yOffset = state.void_in and -depth or baitHeight
end
```

### Dynamic Mode (Sine Wave)
Smooth transition between void and surface.
```lua
if mode == "Dynamic" then
    state.void_timer = state.void_timer + dt
    local cycleTime = inTime + outTime
    local progress = (state.void_timer % cycleTime) / cycleTime
    local sine = math.sin(progress * math.pi * 2)
    yOffset = baitHeight + (sine * 0.5 - 0.5) * (depth + baitHeight)
end
```

### Jitter Mode
Random unpredictable void switching.
```lua
if mode == "Jitter" then
    if math.random() > 0.65 then
        yOffset = -depth + (math.random() - 0.5) * depth * 0.3
    else
        yOffset = baitHeight + (math.random() - 0.5) * baitHeight * 0.5
    end
end
```

### Target Grounded Check
Only activate void when target is on ground.
```lua
local function isTargetGrounded(part, threshold)
    local pos = part.Position
    local gy = groundYAt(pos, part.Parent)
    if not gy then return true end
    return math.abs(pos.Y - gy) < threshold
end

if voidGroundedOnly and not isTargetGrounded(part, groundThreshold) then
    return false -- Don't activate void
end
```

---

## 🎲 Chaos & Randomization

### Chaos Distortion
Add unpredictable distortion to strafe paths.
```lua
local function applyChaos(offset, r, t)
    local amount = chaosAmount  -- 0-1
    local dx, dz = offset.X, offset.Z
    local m = math.sqrt(dx * dx + dz * dz)
    local tx, tz = dx / m, dz / m  -- Tangent
    local nx, nz = -tz, tx         -- Normal
    
    local offN = amount * 0.35 * r * math.sin(6 * t + phase * math.pi)
    local offT = amount * 0.25 * r * math.sin(4 * t + phase * 2.5)
    local radMult = 1.0 + 0.25 * amount * math.sin(7 * t + phase * 1.5)
    
    local px = (dx * radMult) + nx * offN + tx * offT
    local pz = (dz * radMult) + nz * offN + tz * offT
    return Vector3.new(px, offset.Y, pz)
end
```

### XZ Jitter
Add small random noise to position.
```lua
local function applyJitter(offset, voidActive)
    if jitterXZ > 0 then
        local angle = math.random() * math.pi * 2
        local jx = math.cos(angle) * jitterXZ
        local jz = math.sin(angle) * jitterXZ
        offset = offset + Vector3.new(jx, 0, jz)
    end
    return offset
end
```

### Burst Teleport
Random chance to teleport a distance.
```lua
local function applyBurst(offset)
    if math.random(0, 1000) >= burstChance * 10 then return offset end
    local angle = math.random() * math.pi * 2
    local bx = math.cos(angle) * burstDistance
    local bz = math.sin(angle) * burstDistance
    return offset + Vector3.new(bx, 0, bz)
end
```

---

## 🎯 Auto Resolver System

### Position History Tracking
Store recent positions for velocity calculation.
```lua
local function updateResolverHistory(pos, now)
    table.insert(state.resolver_history, { pos = pos, time = now })
    while #state.resolver_history > maxSamples do
        table.remove(state.resolver_history, 1)
    end
end
```

### Velocity Calculation
Calculate velocity from position history.
```lua
local function calculateVelocity()
    local history = state.resolver_history
    if #history < 2 then return Vector3.zero end
    local newest = history[#history]
    local oldest = history[1]
    local dt = newest.time - oldest.time
    if dt < 0.001 then return Vector3.zero end
    return (newest.pos - oldest.pos) / dt
end
```

### Acceleration Tracking
Calculate acceleration from velocity changes.
```lua
local function calculateAcceleration()
    local history = state.resolver_history
    if #history < 3 then return Vector3.zero end
    local mid = math.floor(#history / 2)
    local v1 = (history[mid].pos - history[1].pos) / (history[mid].time - history[1].time)
    local v2 = (history[#history].pos - history[mid].pos) / (history[#history].time - history[mid].time)
    return (v2 - v1) / (history[#history].time - history[1].time)
end
```

### Desync Detection
Detect when target is desyncing.
```lua
local function detectDesync(part, currentPos)
    local predicted = history[#history].pos + velocity * 0.05
    local diff = (currentPos - predicted).Magnitude
    if diff > threshold then
        return true, currentPos - predicted
    end
    return false, Vector3.zero
end
```

### Resolver Modes
```lua
-- Basic: Simple velocity prediction
prediction = velocity * predStrength * 0.05

-- Adaptive: Velocity + acceleration scaled by confidence
prediction = (velPred + accelPred) * confidence

-- Aggressive: Stronger prediction multipliers
prediction = (velPred + accelPred) * 1.3

-- Predictive: Includes jerk estimation
prediction = velPred + accelPred + jerkEstimate
```

### Adaptive Multiplier (Hit/Miss Learning)
```lua
api:on_event("localplayer_hit_player", function()
    state.resolver_hit_count = state.resolver_hit_count + 1
    local ratio = hitCount / (hitCount + missCount)
    state.resolver_multiplier = lerp(multiplier, 0.8 + ratio * 0.4, 0.2)
end)
```

---

## ❄️ Stutter & Freeze Systems

### Stutter Modes
```lua
local STUTTER_MODES = {"Freeze", "Micro", "Teleport", "Shake", "Reverse", "Skip"}
```

### Micro Stutter
Small random movements.
```lua
if mode == "Micro" then
    local angle = math.random() * math.pi * 2
    offset = Vector3.new(math.cos(angle) * intensity * 3, 0, math.sin(angle) * intensity * 3)
end
```

### Shake Effect
Sinusoidal shaking motion.
```lua
if mode == "Shake" then
    local phase = (now * 50) % (math.pi * 2)
    offset = Vector3.new(
        math.sin(phase * 3) * intensity * 5,
        math.sin(phase * 4) * intensity * 2,
        math.cos(phase * 3) * intensity * 5
    )
end
```

### Freeze System
Periodically freeze position.
```lua
if not state.freeze_active and now >= state.freeze_next then
    state.freeze_active = true
    state.freeze_end = now + duration
    state.freeze_pos = pos
    state.freeze_next = now + interval
end
if state.freeze_active then
    return state.freeze_pos  -- Return frozen position
end
```

---

## 💣 Grenade Orbit System

### Grenade Teleportation
Teleport grenades to target.
```lua
local function teleport_grenade(handle, target)
    local targetPos = target.Character.HumanoidRootPart.Position
    if PredictionEnabled then
        local vel = target.Character.HumanoidRootPart.Velocity
        local predict = math.clamp(vel.Magnitude / 50, 0.18, 0.25) * 1.10
        targetPos = targetPos + (vel * predict)
    end
    handle.Position = targetPos + Vector3.new(0, 1, 0)
end
```

### Grenade Orbit Mode
Orbit grenades around target.
```lua
if OrbitMode then
    orbitAngle = orbitAngle + (orbitSpeed * 0.1)
    local offset_x = math.cos(math.rad(orbitAngle)) * orbitRadius
    local offset_z = math.sin(math.rad(orbitAngle)) * orbitRadius
    targetPos = targetPos + Vector3.new(offset_x, grenadeHeight, offset_z)
end
handle.Position = targetPos
```

### Shield Mode (Grenades Orbit You)
Disable explosion and orbit around player.
```lua
local function disable_grenade_explosion(handle)
    if handle:FindFirstChild("TouchInterest") then handle.TouchInterest:Destroy() end
    handle.CanCollide = false
    if handle:FindFirstChild("BodyVelocity") then handle.BodyVelocity:Destroy() end
    handle.Anchored = true
end

if ShieldModeEnabled then
    disable_grenade_explosion(handle)
    local shieldAngle = orbitAngle + grenadeOffsets[handle]
    local offset_x = math.cos(math.rad(shieldAngle)) * shieldRadius
    local offset_z = math.sin(math.rad(shieldAngle)) * shieldRadius
    handle.CFrame = CFrame.new(playerPos + Vector3.new(offset_x, shieldHeight, offset_z))
end
```

### Auto Bomb Mode
Orbit grenades then release to target.
```lua
local elapsed = tick() - grenadeTimers[handle]
if elapsed >= orbitTime then
    -- Time's up, send to target!
    handle.Anchored = false
    handle.Position = targetPos + Vector3.new(0, 1, 0)
else
    -- Still orbiting around player
    local orbitPos = playerPos + Vector3.new(offset_x, grenadeHeight, offset_z)
    handle.Position = orbitPos
end
```

### Grenade Patterns (Pentagram, Hexagram, etc.)
```lua
local function get_pattern_position(pattern, index, radius, target_pos)
    if pattern == "Pentagram" then
        local angle = (index * (360 / 5)) - 90
        local inner = radius * 0.382
        local r = (index % 2 == 0) and radius or inner
        return target_pos + Vector3.new(
            math.cos(math.rad(angle)) * r,
            3,
            math.sin(math.rad(angle)) * r
        )
    elseif pattern == "666" then
        local ring = math.floor(index / 6)
        local angle = (index % 6) * 60
        local r = math.max(3, radius - (ring * 4))
        return target_pos + Vector3.new(
            math.cos(math.rad(angle)) * r, 3,
            math.sin(math.rad(angle)) * r
        )
    end
end
```

---

## 🛠️ Utility Functions

### Ground Y Detection
Find ground level at position.
```lua
local function groundYAt(pos, ignore)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, ignore}
    local result = Workspace:Raycast(pos + Vector3.new(0, 200, 0), Vector3.new(0, -1200, 0), params)
    return result and result.Position.Y or nil
end
```

### Obstacle Avoidance
Prevent strafing into walls.
```lua
local function adjustForObstacles(origin, target, ignoreInst)
    local dir = target - origin
    local dist = dir.Magnitude
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, ignoreInst}
    local result = Workspace:Raycast(origin, dir.Unit * dist, params)
    if result and result.Distance < dist then
        return origin + dir.Unit * math.max(result.Distance - 2, 1.5)
    end
    return target
end
```

### Pattern Cycling
Auto-switch between strafe patterns.
```lua
if autoCycle and now >= state.cycle_next then
    state.cycle_idx = (state.cycle_idx % #patternList) + 1
    local nextPattern = patternList[state.cycle_idx]
    strafe_pattern:SetValue(nextPattern)
    state.cycle_next = now + cycleTime
end
```

---

## Desync
| Function | Description | Usage |
| :--- | :--- | :--- |
| `api:set_fake(override: boolean, cframe: CFrame?, refresh: boolean?): nil` | Sets fake position. | `api:set_fake(true, CFrame.new(0,1000,0), true)` |
| `api:can_desync(): boolean` | Checks if script can desync (not busy). | `if api:can_desync() then ... end` |
| `api:get_client_cframe(): CFrame` | Gets client CFrame (where you seem to be locally). | `cf = api:get_client_cframe()` |
| `api:set_desync_cframe(point: CFrame): nil` | Sets desync position for one frame. | `api:set_desync_cframe(CFrame.new(0,1000,0))` |
| `api:get_desync_cframe(): CFrame` | Gets server CFrame (where you actually are). | `cf = api:get_desync_cframe()` |
| `api:add_desync_callback(priority: number, callback: ()->CFrame?): nil` | Adds desync logic. Priority 1 (force) or 2. | `api:add_desync_callback(2, function() return ... end)` |

## Cache
| Function | Description | Usage |
| :--- | :--- | :--- |
| `api:get_tool_cache(): table` | Info about local tool (ammo, gun, etc.). | `cache = api:get_tool_cache()` |
| `api:get_data_cache(player: Player): table?` | Info like Crew, Wanted, Currency. | `cache = api:get_data_cache(player)` |
| `api:get_status_cache(player: Player): table?` | Status like K.O, Dead, Armor, Grabbed. | `cache = api:get_status_cache(player)` |
| `api:get_target_cache(type: string): table` | Info on targets (ragebot, aimbot, silent). | `cache = api:get_target_cache("ragebot")` |
| `api:get_character_cache(player: Player): table?` | Optimized way to get character parts. | `cache = api:get_character_cache(player)` |

**Target Cache Fields:** `player`, `part`.

## Local
| Function | Description | Usage |
| :--- | :--- | :--- |
| `api:get_current_vehicle(): Instance?` | Returns current vehicle. | `veh = api:get_current_vehicle()` |
| `api:buy_vehicle(cframe: CFrame?): nil` | Buys/finds vehicle, optionally teleports. | `api:buy_vehicle(CFrame.new(...))` |
| `api:force_shoot(handle, part, origin, pos, vis): nil` | Forces a shot from tool. | `api:force_shoot(tool.Handle, target, ...)` |
| `api:buy_item(item: string, ammo: bool, equipped: bool): nil` | Buys item/ammo. | `api:buy_item("[LMG", true)` |
| `api:teleport(cframe: CFrame): nil` | Teleports player/vehicle. Yields. | `api:teleport(CFrame.new(0,10,0))` |
| `api:chat(message: string): nil` | Sends chat message. | `api:chat("hello")` |

## Player
| Function | Description | Usage |
| :--- | :--- | :--- |
| `api:is_crew(player: Player, target: Player): boolean` | Checks if players are teammates/crew. | `api:is_crew(p1, p2)` |

## Misc
| Function | Description | Usage |
| :--- | :--- | :--- |
| `api:on_command(command: string, callback: function): nil` | Chat command listener. | `api:on_command("!cmd", function(plr, args) ... end)` |
| `api:redeem_codes(): nil` | Redeems all available codes. | `api:redeem_codes()` |

```

### Avatar Morphing & Mesh Swaps (`avatar cloner`)
Apply any user's appearance or special bundles (Headless/Korblox).
```lua
local function Morph(userId)
    local appearance = Players:GetCharacterAppearanceAsync(userId)
    for _, child in pairs(appearance:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Clothing") then
            child.Parent = LocalPlayer.Character
        end
    end
end
-- Korblox / Leg Swap
leg:ClearAllChildren() -- Remove old meshes
local mesh = Instance.new("SpecialMesh", leg)
mesh.MeshId = "rbxassetid://902942093" -- Korblox Mesh ID
```

### Steal / Bring Logic (`steal stuff`)
Teleport knocked players by spamming the `Grabbing` event.
```lua
while api:get_status_cache(target)["K.O"] do
    MainEvent:FireServer("Grabbing")
    api:set_server_cframe(target.Character.UpperTorso.CFrame) 
    task.wait(0.3)
end
```

### Custom Armor / Item Binding (`retrieve_hidden_items`)
Fake "wearing" items by creating Anchored clones and locking their CFrame to limbs each frame.
```lua
RunService.RenderStepped:Connect(function()
    if armorPart and limb then
        armorPart.CFrame = limb.CFrame
    end
end)
```

```

### Audio Visualization (`music player`)
React to sound using `PlaybackLoudness`.
```lua
local Sound = Instance.new("Sound", game.SoundService)
RunService.RenderStepped:Connect(function()
    local loudness = Sound.PlaybackLoudness
    local height = 1 + (loudness / 100)
    VisualizerPart.Size = Vector3.new(1, height, 1)
end)
```

### Camera Locking (`face camera lock`)
Force the camera to follow the character's head direction.
```lua
RunService.RenderStepped:Connect(function()
    local head = LocalPlayer.Character.Head
    local targetCF = CFrame.new(head.Position - head.CFrame.LookVector * 10, head.Position)
    workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(targetCF, 0.5)
end)
```

### HUD Manipulation (`hud hider`)
Aggressively hide all UI elements, including CoreGui.
```lua
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
for _, child in pairs(game.CoreGui:GetChildren()) do
    if child:IsA("ScreenGui") and child.Name == "RobloxGui" then
        child.Enabled = false
    end
end
```

### Vehicle Attribute Tuning (`car speed changger`)
Da Hood vehicles often use custom `Attributes` on a "Skin" object rather than standard VehicleSeat properties.
```lua
local skin = vehicle:FindFirstChild("Skin")
if skin then
    skin:SetAttribute("Speed", 300)
    skin:SetAttribute("Torque", 200)
end
```

### Attribute Enforcement (Anti-Reset)
Protect values from being reset by the game using `GetAttributeChangedSignal`.
```lua
local function ProtectAttribute(obj, attr, value)
    obj:GetAttributeChangedSignal(attr):Connect(function()
        if obj:GetAttribute(attr) ~= value then
            task.wait() -- yield to avoid stack overflow or race
            obj:SetAttribute(attr, value)
        end
    end)
end
```

### Fake Welding (Armor Attachment)
Attach external models to character limbs without physical constraints using `RenderStepped`.
```lua
RunService.RenderStepped:Connect(function()
    local limb = character:FindFirstChild("LeftLowerArm")
    local armorPart = ArmorModel:FindFirstChild("LeftGauntlet")
    if limb and armorPart then
        armorPart.CFrame = limb.CFrame * CFrame.new(0, -0.2, 0)
    end
end)
```

### Real-time Offset Tuning
Create in-game sliders to adjust attachment offsets dynamically.
```lua
-- Slider logic updating a config table
slider.MouseButton1Down:Connect(function() dragging = true end)
RunService.RenderStepped:Connect(function()
    if dragging then
         local val = CalculateSliderValue()
         Offsets["LeftGauntlet"].Y = val
    end
end)
```

### Behavioral Detection (`script detector`)
Identify exploiters by tracking their movement through specific CFrame sequences (e.g., auto-farming paths).
```lua
local Path = { CFrame.new(x1,y1,z1), CFrame.new(x2,y2,z2) }
local Visited = {}
RunService.Heartbeat:Connect(function()
    for i, point in ipairs(Path) do
        if (root.Position - point.Position).Magnitude < 15 then
            Visited[i] = true
        end
    end
    if #Visited == #Path then FlagPlayer() end
end)
```

### Geometric Aim Detection (`anti aim protection`)
Use Dot Product and Point-Line Distance to detect if a player is aiming at you with high precision.
```lua
local toMe = (MyHead.Position - TheirHead.Position)
local look = TheirHead.CFrame.LookVector
local dot = look:Dot(toMe.Unit) -- > 0.9 means looking generally at you
-- Calculate miss distance (distance from their aim ray to your head)
local aimPoint = TheirHead.Position + look * toMe.Magnitude
local missDist = (aimPoint - MyHead.Position).Magnitude
if dot > 0.9 and missDist < 2 then IsAiming = true end
```

```

### Sound ID Stealing (`boombox`)
Extract `SoundId` from other players' characters (Boomboxes or Phones).
```lua
local torso = target.Character:FindFirstChild("LowerTorso")
local sound = torso:FindFirstChild("BOOMBOXSOUND")
if sound then
    setclipboard(sound.SoundId)
end
```

### Vehicle Physics Override (`cart.lua`)
Completely replace a vehicle's physics with custom `BodyMovers` for precise control (WASD).
```lua
local Seat = Vehicle.Seat
-- 1. Create movers
local BV = Instance.new("BodyVelocity", Seat)
local BG = Instance.new("BodyGyro", Seat)
-- 2. Bind to controls
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then
        BV.Velocity = Seat.CFrame.LookVector * 50
    end
end)
```

```

### Unanchored Part Visualization (`check_unanchored`)
Highlight unanchored parts using `SelectionBox` in `CoreGui` to find exploitable objects.
```lua
local Folder = Instance.new("Folder", game.CoreGui)
for _, part in pairs(workspace:GetDescendants()) do
    if part:IsA("BasePart") and not part.Anchored then
        local box = Instance.new("SelectionBox", Folder)
        box.Adornee = part
        box.Color3 = Color3.new(1,0,0)
    end
end
```

### Seat Bringing (`check_unanchored`)
Exploit unanchored seats to teleport them to you or others.
```lua
-- 1. Teleport to seat and Sit
Char.HumanoidRootPart.CFrame = Seat.CFrame
Seat:Sit(Char.Humanoid)
-- 2. Wait for ownership
task.wait(0.1)
-- 3. Teleport seat (and you) to destination
Seat.CFrame = DestinationCFrame
-- 4. Jump out
Char.Humanoid.Sit = false
```

```

### Selective Core Hiding (`custom ui`)
Hide specific default UI elements (like Health/Money bars) instead of disabling all CoreGui.
```lua
local MainGui = PlayerGui:FindFirstChild("MainScreenGui")
if MainGui then
    for _, child in pairs(MainGui:GetChildren()) do
        if child.Name:match("Bar") or child.Name:match("Money") then
            child.Visible = false
        end
    end
end
```

### Draggable UI Element
Simple reusable drag logic for custom UI frames.
```lua
local function MakeDraggable(frame)
    local dragging, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end
```

```

### Procedural 3D Geometry (`3d china hat`)
Generate complex 3D shapes (pyramids, cones) using math and standard parts.
```lua
-- Create a pryamid side using a WedgePart
local chordLength = (p1 - p2).Magnitude
local distToCenter = (midChord - baseCenter).Magnitude
wedge.Size = Vector3.new(chordLength, height, distToCenter)
wedge.CFrame = CFrame.lookAt(wedgePos, wedgePos + dir)
```

### No-Asset UI Design (`Exodus_GUI`)
Create complex UI icons (logos, wallets) using only Frame primitives and rotations, removing the need for external image assets.
```lua
-- Draw a Hexagon using Frames
local function createHexagon(size, color)
    local container = Instance.new("Frame")
    -- Use specific geometric overlaps or rotated squares to simulate complex shapes
    local box = Instance.new("Frame", container) 
    -- ... complex masking logic ...
end
```

### Modular Remote Loading (`Fake Position`)
Load large codebases by fetching modules from the web.
```lua
local Handler = loadstring(game:HttpGet("https://raw.githubusercontent.com/Repo/Handler"))()
local ModTable = loadstring(game:HttpGet("https://raw.githubusercontent.com/Repo/Contents"))()
-- Use cloned refs for security
local Workspace = Handler:CloneRef("Workspace")
```

```

### TouchInterest Automation (`afk_farm_gui`)
Simulate touching parts without moving the character using `firetouchinterest`.
```lua
-- 0 = Touch Start, 1 = Touch End
firetouchinterest(TargetPart, LocalPlayer.Character.HumanoidRootPart, 0)
task.wait()
firetouchinterest(TargetPart, LocalPlayer.Character.HumanoidRootPart, 1)
```

### Bounty Poster Monitoring (`auto bounty`)
Detect when a player gets a bounty by watching the SurfaceGui on the map posters.
```lua
local PosterText = workspace.MAP.BountyPosters.Poster.Texts.PlayerName.SurfaceGui.TextLabel
PosterText:GetPropertyChangedSignal("Text"):Connect(function()
    local targetName = PosterText.Text
    if targetName ~= "" then
        print("New bounty:", targetName)
    end
end)
```

### Loop Bring (`AutoRebirth_RunWay`)
Continuously teleport all players to your position (requires server-sided exploits or specific game vulnerabilities).
```lua
for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer and plr.Character then
        -- Teleport 3 studs in front of you
        plr.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-3)
    end
end
```

```

### Inventory JSON Parsing (`skin viewer`)
Read player inventory data stored as JSON in ValueObjects.
```lua
local DataFolder = Player:FindFirstChild("DataFolder")
local SkinsValue = DataFolder:FindFirstChild("Skins")
if SkinsValue then
    local data = HttpService:JSONDecode(SkinsValue.Value)
    if data["[Knife]"]["Galaxy"] then
        print("Player has Galaxy Knife")
    end
end
```

### Fuzzy Search Algorithm (`skin viewer`)
Use Levenshtein distance to find the closest player name match from a partial or misspelled input.
```lua
local function LevenshteinDistance(s1, s2)
    -- ... matrix calculation ...
    return distance
end
-- Usage: Find player with lowest distance to input string
```

### Recursive Asset Dumping (`asset_id_dumper`)
Recursively scan directories to extract all Asset IDs (Mesh, Texture, Sound) into a table.
```lua
local function scan_folder(folder)
    for _, child in pairs(folder:GetChildren()) do
        if child:IsA("MeshPart") then
            table.insert(Assets, {Mesh=child.MeshId, Tex=child.TextureID})
        elseif child:IsA("Folder") then
            scan_folder(child)
        end
    end
end
```

```

### Projectile Teleportation (`grenade teleport`)
Teleport projectiles (grenades, rpgs) directly to the target using hidden properties.
```lua
sethiddenproperty(GrenadeHandle, "CFrame", Target.Character.HumanoidRootPart.CFrame)
sethiddenproperty(GrenadeHandle, "Velocity", Vector3.new(0,0,0))
sethiddenproperty(GrenadeHandle, "RotVelocity", Vector3.new(0,0,0))
```

### Desync Callbacks (`snowball`)
Register a callback to tell the server you are at a different location than your client render.
```lua
api:add_desync_callback(2, function()
    if is_farming then
        return FarmLocationCFrame -- Server sees you here
    end
    return nil -- Default behavior
end)
```

### Parametric Strafe Patterns (`whip`)
Override ragebot movement with complex math curves (Orbit, Star, DNA, etc).
```lua
api:ragebot_strafe_override(function(pos, unsafe, part)
    local ang = os.clock() * Speed
    local x = Radius * math.cos(ang)
    local z = Radius * math.sin(ang)
    -- Parametric equations for complex shapes
    return CFrame.lookAt(Origin, NewPos)
end)
```

```

### Chat Command Listener (`bot`)
Create a "slave" bot that obeys commands from a specific "owner" user.
```lua
TextChatService.MessageReceived:Connect(function(msg)
    if msg.TextSource.Name == OWNER_NAME and msg.Text:sub(1,1) == PREFIX then
        local cmd = msg.Text:sub(2):split(" ")
        if cmd[1] == "kill" then Kill(cmd[2]) end
    end
end)
```

### Reliable Bring State Machine (`bot`)
A robust sequence to forcefully bring a player:
1. Teleport to Target + Offset
2. Spam "Grabbing" remote until Constraint found
3. Teleport to Owner
4. Wait for replication
5. Drop Target
```lua
-- Simplified logic
repeat
    TeleportTo(Target)
    Fire("Grabbing")
    task.wait(0.1)
until Target:FindFirstChild("GRABBING_CONSTRAINT")
TeleportTo(Owner)
Fire("Grabbing") -- Release
```

### Defensive Event Hooks (`bunch of stuf`)
Instantly react to being shot or entering danger.
```lua
api:on_event("localplayer_got_shot", function()
    -- Enable Void Protection instantly
    SetVoid(true) 
    task.delay(3, function() SetVoid(false) end)
end)
```

### Entity Sanitization / Anti-Fling (`bunch of stuf`)
Prevent other players from flinging you by stripping their physical properties locally.
```lua
RunService.Heartbeat:Connect(function()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            for _, part in pairs(plr.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    part.Velocity = Vector3.zero -- Stop momentum
                    part.RotVelocity = Vector3.zero
                end
            end
        end
    end
end)
```

```

### Resolver Logic (`newtest`)
Predict target position using velocity and acceleration history to counter anti-aim.
```lua
local history = {} -- Store {pos, time}
-- Calculate Acceleration
local v1 = (mid.pos - old.pos) / dt1
local v2 = (new.pos - mid.pos) / dt2
local accel = (v2 - v1) / totalDt
local predicted = currentPos + velocity * coeff + accel * 0.5 * coeff^2
```

### Chaos Movement (`newtest`)
Intentionally erratic movement to confuse enemy aim.
```lua
if ChaosEnabled then
    local jitter = Vector3.new(math.random()-0.5, 0, math.random()-0.5) * Intensity
    TargetPosition = TargetPosition + jitter
end
```

### Adaptive Positioning Strategies (`auto bag`)
Cycle through different CFrame offsets if an action fails repeatedly.
```lua
local Strategies = {
    function(root) return root.CFrame * CFrame.new(0, 0, 2) end, -- Behind
    function(root) return root.CFrame * CFrame.new(0, -2, 0) end, -- Below
}
local currentStrategy = Strategies[FailCount % #Strategies + 1]
```

### Physics Mirroring / Glue (`auto bag`)
Force the game engine to treat your root part's physics as identical to the target's.
```lua
sethiddenproperty(LocalRoot, "PhysicsRepRootPart", TargetRoot)
```

```

### Body Color Identification (`reslover`)
Identify specific player roles or teams based on their character's body colors (useful when standard Teams are not used).
```lua
local function IsEnemy(char)
    local colors = char:FindFirstChild("BodyColors")
    if colors and colors.HeadColor3 == Color3.fromRGB(255, 0, 0) then
        return true
    end
    return false
end
```

### Da Hood Aim Replication (`aim_debug`)
Accurately get where a player is aiming by reading the specific Da Hood value.
```lua
local function GetAimPos(plr)
    local be = plr.Character and plr.Character:FindFirstChild("BodyEffects")
    local mouse = be and be:FindFirstChild("MousePos")
    if mouse then return mouse.Value end
    return plr.Character.Head.CFrame.LookVector * 100 -- Fallback
end
```

### Visual Beam Caching (`aim_debug`)
Efficiently draw debug rays by pooling parts instead of creating/destroying them every frame.
```lua
local BeamCache = {}
-- Update loop
for id, beam in pairs(BeamCache) do beam.Active = false end
-- Draw
if not BeamCache[id] then BeamCache[id] = CreateBeamPart() end
BeamCache[id].Part.CFrame = NewCFrame
BeamCache[id].Active = true
-- Cleanup inactive
for id, beam in pairs(BeamCache) do if not beam.Active then beam.Part:Destroy() end end
```

```

### Physics Representation Override (`glue`)
Force the game engine to treat your root part's physics as identical to the target's, effectively "gluing" to them at a physics level.
```lua
sethiddenproperty(LocalRoot, "PhysicsRepRootPart", TargetRoot)
```

### Grip Desync / Silent Root (`ggrip pos`)
Manipulate tool grip offsets to align the visual gun model with a desynced server position, allowing shooting from "invisible" locations.
```lua
-- 1. Server sees you here
api:set_desync_cframe(TargetRoot.CFrame * Offset)
-- 2. Client moves gun to match
local worldOffset = TargetRoot.Position - Char.PrimaryPart.Position
Tool.Grip = CFrame.new(worldOffset) * Rotation
```

### Matrix Rotation Presets (`glue`)
Standard CFrame rotations for specific orientations relative to a target.
```lua
local Presets = {
    FaceDown = CFrame.Angles(-math.pi/2, 0, 0),
    FaceUp   = CFrame.Angles(math.pi/2, 0, 0),
    FaceBack = CFrame.Angles(0, math.pi, 0)
}
```

```

### Web Asset Loading (`hud`)
Load external images (like avatars) dynamically using Roblox web APIs.
```lua
Thumbnail.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. UserId .. "&width=150&height=150&format=png"
```

### UI Method Hooking / Spoofing (`hider`)
Wrap UI library functions to display fake values (for streaming/recording).
```lua
local OldDisplay = Option.Display
Option.Display = function(self)
    if HideMode then
        self.TextLabel.Text = "Fake Value" -- Spoof
    else
        OldDisplay(self) -- Normal
    end
end
```

### Data Cache Usage (`ammo logger`)
Access player data (Money, Ammo) efficiently via the API's internal cache instead of scraping GUI/Leaderstats.
```lua
local data = api:get_data_cache(Player)
if data and data.Currency < LastCurrency then
    print("Player spent money!")
end
```

```

### Webhook Logging (`auto loader`)
Send script execution data (User, Game, JobID) to a Discord webhook.
```lua
request({
    Url = "https://discord.com/api/webhooks/...",
    Method = "POST",
    Headers = {["Content-Type"] = "application/json"},
    Body = HttpService:JSONEncode({
        content = "",
        embeds = {{ title = "Script Executed", description = LocalPlayer.Name }}
    })
})
```

### Environment-Aware Loading (`auto loader`)
Load different scripts based on the Game/Place ID to support multi-game hubs.
```lua
if game.PlaceId == 2788229376 then
    loadstring(game:HttpGet("DaHoodScript.lua"))()
else
    loadstring(game:HttpGet("UniversalScript.lua"))()
end
```

### World Scraping / Bounty Posters (`auto bounty`)
Read text from physical in-game models (like wanted posters) to find targets.
```lua
for _, poster in pairs(Workspace.MAP.BountyPosters:GetChildren()) do
    local name = poster.Texts.PlayerName.SurfaceGui.TextLabel.Text
    if name ~= "Text" then
        Targets[name] = true
    end
end
```

```

### Client-Side Asset Swapping (`korblox and headless`)
Mimic expensive items by locally swapping MeshIDs and Textures.
```lua
local function ApplyKorblox(char)
    local Leg = char:FindFirstChild("RightLowerLeg")
    if Leg then
        Leg.MeshId = "http://www.roblox.com/asset/?id=902942093"
        Leg.Transparency = 1 -- Hide original part if needed
    end
end
```

### Continuous Appearance Enforcement (`korblox and headless`)
fight against game scripts that reset appearance by reapplying changes every frame.
```lua
RunService.Heartbeat:Connect(function()
    if ToggleVal then
        ApplyCosmetics(LocalPlayer.Character)
    end
end)
```

```

### External UI Automation (`stomp offset randomizer`)
Script B controlling Script A's settings by manipulating its UI objects directly.
```lua
local slider = api:get_ui_object("ragebot_stomp_offset")
RunService.Heartbeat:Connect(function()
    local val = math.sin(os.clock()) * 5 + 5
    slider:SetValue(val)
end)
```

### Combat Logging Logic (`winnerwinner...`)
Detect when a target rage-quits by checking if the player leaving was your active target.
```lua
Players.PlayerRemoving:Connect(function(plr)
    if api:get_target("ragebot") == plr then
        print(plr.Name .. " logged to avoid death!")
    end
end)
```

```

### Drawing Library Optimization (`china hat`)
Pre-allocate "Drawing" objects (Lines, Triangles) and effectively pool them to avoid lag during 2D render loops.
```lua
-- Pre-create 20 lines
local Lines = {}
for i=1, 20 do Lines[i] = Drawing.new("Line") end

RenderStepped:Connect(function()
    for i, line in pairs(Lines) do
        -- Update properties instead of creating new objects
        line.Visible = true 
    end
end)
```

### Parametric Shape Generation (`china hat`)
Use math functions (sin/cos) to generate complex 3D shapes (Hearts, Stars, Spirals) for ESP.
```lua
local angle = (i / totalPoints) * math.pi * 2
local r = Radius * (1 - 0.3 * math.abs(math.sin(angle))) -- Heart shape math
local pos = Center + Vector3.new(math.cos(angle)*r, 0, math.sin(angle)*r)
```

### Render Frame Skipping (`china hat`)
Optimize heavy render tasks by only updating every N frames.
```lua
local frame = 0
RunService.RenderStepped:Connect(function()
    frame = frame + 1
    if frame % 3 ~= 0 then return end -- Skip 2/3 frames
    -- Expensive render logic here
end)
```

### Physics Ownership Hacks (`part fling`)
To gain control of unanchored parts (like accessories dropped on the ground), you can manipulate simulation radius and accessory state.
```lua
-- 1. Maximize Simulation Radius
pcall(function()
    sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
end)

-- 2. Force Network Update via Accessory State (Hack)
local function force_network_owner(part)
    pcall(function()
        sethiddenproperty(part, "BackendAccoutrementState", 4)
        task.wait(0.4)
        sethiddenproperty(part, "BackendAccoutrementState", 0) -- Reset
    end)
end
```

```

### Seat Ownership Claiming (`seat_fling_improved`)
Gain physics ownership of a seat by briefly sitting in it, enabling reliable flinging.
```lua
function ClaimSeat(seat)
    local oldCF = HRP.CFrame
    seat:Sit(Humanoid)
    task.wait(0.2)
    seat:SetNetworkOwner(LocalPlayer)
    Humanoid.Sit = false
    HRP.CFrame = oldCF
end
```

### Aim Vector Analysis (`anti aim protection`)
Detect if a player is aiming at you by comparing their look vector to your position.
```lua
local toMe = (MyPos - TheirPos).Unit
local dot = TheirHead.CFrame.LookVector:Dot(toMe)
if dot > 0.9 then -- 0.9 means they are looking almost directly at you
    print("Player is aiming at you!")
end
```

### Bullet Trace Validation (`anti-fakepos`)
Detect "Fake Lag" or "Desync" by comparing bullet origins to actual player positions.
```lua
MainEvent.OnClientEvent:Connect(function(mode, shooter, origin)
    if mode == "ClientBullet" then
        if (shooter.HumanoidRootPart.Position - origin).Magnitude > 25 then
             print("Fake Position Detected from " .. shooter.Name)
        end
    end
end)
```

### Spline Prediction (`anti-fakepos`)
Predict real positions of lagging players using velocity extrapolation.
```lua
local function Predict(entry)
    local velocity = (entry.pos - entry.lastPos) / entry.dt
    return entry.pos + velocity * (Ping + 0.1)
end
```

### Animation State Replacement (`animations`)
Hot-swap animation IDs by cloning the default `Animate` script and modifying its values.
```lua
local Animate = Char.Animate:Clone()
Animate.walk.WalkAnim.AnimationId = "rbxassetid://..."
Char.Animate:Destroy()
Animate.Parent = Char -- Restart script with new IDs
```

### Appearance Cloning (`avatar cloner`)
Copy another player's look using Roblox API and manual accessory application.
```lua
local appearance = Players:GetCharacterAppearanceAsync(TargetUserId)
for _, item in pairs(appearance:GetChildren()) do
    if item:IsA("Accessory") or item:IsA("Clothing") then
        item.Parent = LocalPlayer.Character
    end
end
```

### Rig Attachment Mapping (`wear_full_iron_man_suit`)
Attach complex external models to the character by mapping suit parts to character limbs.
```lua
local Map = { ["SuitArm"] = "LeftLowerArm", ["SuitHead"] = "Head" }
RunService.RenderStepped:Connect(function()
    for suitPart, limbName in pairs(Map) do
        local limb = Char[limbName]
        Suit[suitPart].CFrame = limb.CFrame * Offsets[suitPart]
    end
end)
```

```

### Attribute Protection Hook (`car speed changger`)
Listen for changes to attributes and immediately revert them to prevent game scripts from resetting values.
```lua
Instance:GetAttributeChangedSignal("Speed"):Connect(function()
    if Instance:GetAttribute("Speed") ~= DesiredSpeed then
        Instance:SetAttribute("Speed", DesiredSpeed)
    end
end)
```

### Physics Override Movement (`cart`)
Force an object to move by attaching high-power BodyMovers, overriding default physics.
```lua
local BV = Instance.new("BodyVelocity", Part)
BV.MaxForce = Vector3.new(math.huge, 0, math.huge)
BV.Velocity = Camera.CFrame.LookVector * Speed
local BG = Instance.new("BodyGyro", Part) -- Stabilizer
BG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
```

```

### Audio Asset Stealing (`boombox`)
Find and extract audio IDs from other players' characters (e.g., Boombox or Phone).
```lua
local Sound = Char.LowerTorso:FindFirstChild("BOOMBOXSOUND")
if Sound then
    local id = Sound.SoundId:split("//")[2]
    setclipboard(id)
end
```

### Audio Visualization (`music player`)
Create visual effects that react to sound volume (Loudness) in real-time.
```lua
RunService.RenderStepped:Connect(function()
    local Loudness = Sound.PlaybackLoudness
    for i, part in pairs(VisualizerParts) do
        part.Size = Vector3.new(1, Loudness / 100, 1)
        part.Color = Color3.fromHSV(Loudness / 500, 1, 1)
    end
end)
```

### Remote Audio Triggering (`ringtone stuff`)
Exploit game remotes to play specific sound IDs to the server.
```lua
MainEvent:FireServer("RingTone", SoundID)
```

```

### Physics Projectile Control (`part fling`)
Turn unanchored parts into guided missiles using BodyThrust and BodyPosition.
```lua
local BP = Instance.new("BodyPosition", Part)
local BT = Instance.new("BodyThrust", Part)
BP.Position = Target.Position + PredictionVector
BT.Force = Vector3.new(-10000, -10000, -10000) -- High negative force for chaos/damage
```

### Desync Bagging (`sticky cum`)
Bag players safely by spoofing your physical representation and using desync to reach them.
```lua
sethiddenproperty(Root, "PhysicsRepRootPart", TargetHRP)
api:set_desync_cframe(CFrame.new(TargetPos))
BagTool:Activate()
```

### Position History Analysis (`script detector`)
Detect if a player is using a specific script by tracking if they visit a known sequence of coordinates.
```lua
if (Pos - KnownLoc1).Magnitude < 15 then MarkVisit(Player, 1) end
if (Pos - KnownLoc2).Magnitude < 15 then MarkVisit(Player, 2) end
if HasVisitedAll(Player) then print("Player is using Script X") end
```

```

### Grenade Sticky Teleport (`rpg v2`)
Teleport grenades to a target and make them "stick" using physics manipulation.
```lua
local function StickGrenade(grenade, target)
    local bp = Instance.new("BodyPosition", grenade)
    bp.Position = target.Position
    -- Advanced sticky: spoof physics rep
    sethiddenproperty(grenade, "PhysicsRepRootPart", target)
end
```

### Tool Skin Swapping (`gun changer`)
Replace a tool's visual appearance by welding a new model to the handle and hiding the original.
```lua
Tool.ChildAdded:Connect(function(child)
    if child.Name == "Handle" then
        child.Transparency = 1
        local Skin = ReplicatedStorage.Skins.MySkin:Clone()
        local Weld = Instance.new("WeldConstraint", Skin.PrimaryPart)
        Weld.Part0 = child
        Weld.Part1 = Skin.PrimaryPart
    end
end)
```

### Local Mesh Replacement (`morph`)
Hide the local character and weld a custom rbxasset model to the RootPart for a client-side morph.
```lua
local Model = game:GetObjects("rbxassetid://123456")[1]
for _, part in pairs(Char:GetChildren()) do
    if part:IsA("BasePart") then part.Transparency = 1 end
end
Model.Parent = workspace
Model:PivotTo(Char.HumanoidRootPart.CFrame)
local Weld = Instance.new("WeldConstraint")
Weld.Part0 = Char.HumanoidRootPart
Weld.Part1 = Model.PrimaryPart
```

```

### External Data Parsing (`inventory_val_calc`)
Fetch and parse raw text data from external sources (like GitHub) to use in-game.
```lua
local Data = game:HttpGet("https://raw.githubusercontent.com/user/repo/main/values.txt")
local Values = {}
for line in Data:gmatch("[^\r\n]+") do
    local Name, Value = line:match("(.+):%s*(.+)")
    Values[Name] = tonumber(Value)
end
```

### Recursive UI Scraper (`ui asset dumper`)
Traverse a UI hierarchy to extract asset IDs and properties for cloning or analysis.
```lua
for _, obj in pairs(Gui:GetDescendants()) do
    if obj:IsA("ImageLabel") and obj.Image ~= "" then
        print("Found Asset: " .. obj.Image .. " at " .. tostring(obj.AbsolutePosition))
    end
end
```

### DataFolder Scraping (`robux donated`)
Read exposed `DataFolder` values from other players to gather stats.
```lua
for _, Plr in pairs(Players:GetPlayers()) do
    local Data = Plr:FindFirstChild("DataFolder")
    if Data then
        print(Plr.Name .. " has donated: " .. Data.RobuxDonated.Value)
    end
end
```

```

### Map Modification / Secret Access (`retrieve_hidden_items`)
Delete fake walls or client-side barriers to access secret areas.
```lua
if Workspace.MAP:FindFirstChild("FakeBlueBrick") then
    Workspace.MAP.FakeBlueBrick:Destroy()
end
```

### Custom Tool Creation (`retrieve_hidden_items`)
Convert standard Models or Parts into equipping Tools effectively.
```lua
local Tool = Instance.new("Tool", Backpack)
local Handle = Part:Clone()
Handle.Name = "Handle"
Handle.Parent = Tool
Tool.Equipped:Connect(function()
    local Hand = Char:FindFirstChild("RightHand")
    Handle.CFrame = Hand.CFrame
    local Weld = Instance.new("WeldConstraint", Handle)
    Weld.Part0 = Hand
    Weld.Part1 = Handle
end)
```

### Combat Logging / Bullet Tracing (`damage_logger`)
Hook the `ClientBullet` event to log who shot whom.
```lua
MainEvent.OnClientEvent:Connect(function(Mode, Shooter, HitPart)
    if Mode == "ClientBullet" and Shooter ~= LocalPlayer then
        print(Shooter.Name .. " shot " .. HitPart.Parent.Name)
    end
end)
```

### UI Deception & Error Hooking (`fake kick`)
Detect native Roblox error prompts and replace them with custom UIs.
```lua
RunService.RenderStepped:Connect(function()
    local prompt = CoreGui:FindFirstChild("RobloxPromptGui")
    if prompt then
        local errorFrame = prompt:FindFirstChild("promptOverlay")
        if errorFrame and errorFrame.Visible then
            prompt.Enabled = false -- Hide real error
            MyCustomScreen.Visible = true -- Show fake screen
        end
    end
end)
```

## Attacker Detection & Damage Logging
Robustly detecting who damaged a player, handling guns (Creator tag) and melee (Proximity).
```lua
local function get_attacker(victim, victim_char)
    local hum = victim_char:FindFirstChild("Humanoid")
    -- 1. Check Creator Tag (Guns impact)
    if hum and hum:FindFirstChild("creator") then
        return hum.creator.Value
    end
    -- 2. Proximity Check (Melee/Fists fallback)
    local closest, dist = nil, 12
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= victim and p.Character then
            local d = (p.Character.HumanoidRootPart.Position - victim_char.HumanoidRootPart.Position).Magnitude
            if d < dist then closest, dist = p, d end
        end
    end
    return closest
end

-- Hooking Gun Shots
api:add_connection(ReplicatedStorage.MainEvent.OnClientEvent:Connect(function(mode, ...)
    if mode == "ClientBullet" then
        local shooter, hit_part = ...
        -- Log shot logic here
    end
end))
```

### Automated Action State Machine
Managing complex sequences (Kill -> Stomp -> Bag) using a state variable.
```lua
local State = { Mode = "idle" } -- idle, killing, stomping, bagging

RunService.Heartbeat:Connect(function()
    if IsBagged(target) then
        State.Mode = "idle"
    elseif IsKnocked(target) then
        State.Mode = "bagging"
    else
        State.Mode = "killing"
        api:set_ragebot(true)
    end
    
    -- Physics Loop: Glue to target only when interacting
    if State.Mode == "bagging" or State.Mode == "stomping" then
        sethiddenproperty(my_root, "PhysicsRepRootPart", target_root)
    end
end)
```

### Projectile Manipulation
Teleport server-sided projectiles (like Grenades) to targets using BodyPosition and Sticky Glue.
```lua
workspace.ChildAdded:Connect(function(child)
    if child.Name == "[Grenade]" then
        local bp = Instance.new("BodyPosition", child.Handle)
        bp.Position = target.Character.HumanoidRootPart.Position
        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        
        -- Sticky logic for projectiles
        sethiddenproperty(child.Handle, "PhysicsRepRootPart", target.Character.HumanoidRootPart)
    end
end)
```

### Advanced Visuals & LOD
Using `Drawing` library with Level-of-Detail (LOD) optimization for 3D visuals.
```lua
local dist = (Camera.CFrame.Position - head.Position).Magnitude
local sides = 20
if dist > 100 then sides = 10 end -- LOD Optimization

for i = 1, sides do
    -- Math to project 3D circle points to 2D screen
    local screenPoint = Camera:WorldToViewportPoint(worldPoint)
    -- Drawing logic...
end
```

### Aim Detection (Raycast)
Detect if players are aiming at you or others.
```lua
local function is_aiming_at(player, victim_char)
    local origin = player.Character.Head.Position
    local dir = player.Character.Head.CFrame.LookVector * 100
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {player.Character}
    
    local result = workspace:Raycast(origin, dir, params)
    return result and result.Instance and result.Instance:IsDescendantOf(victim_char)
end
```

## UI Library Reference
Based on script usage (LinoriaLib compatible):

### Creation
- `api:AddTab(name: string): Tab`
- `Tab:AddLeftGroupbox(name: string): Groupbox`
- `Tab:AddRightGroupbox(name: string): Groupbox`

### Groupbox Methods
- **Toggle**: `Groupbox:AddToggle(idx, { Text = "...", Default = bool, Callback = func })`
- **Button**: `Groupbox:AddButton({ Text = "...", Func = func })` or `Groupbox:AddButton("Text", func)`
- **Dropdown**: `Groupbox:AddDropdown(idx, { Values = {}, Default = val, Multi = bool, Text = "...", Callback = func })`
- **Label**: `Groupbox:AddLabel("Text")`
- **Divider**: `Groupbox:AddDivider()`

## Practical Examples & Patterns

### Custom Cleanup logic
`api:add_connection` supports custom tables with a `Disconnect` method, allowing you to clean up non-connection resources (like RenderStepped bindings) when the script unloads.
```lua
local connection = RunService:BindToRenderStep("MyLoop", 0, function() ... end)
api:add_connection({
    Disconnect = function()
        RunService:UnbindFromRenderStep("MyLoop")
    end
})
```

### Dynamic Skin Changer Logic (from `dahood_skin_changer.lua`)
Iterating over weapon textures and applying them safely:
```lua
local skinData = { ["[AK47]"] = "rbxassetid://12345" }
for _, tool in ipairs(character:GetChildren()) do
    if skinData[tool.Name] then
        tool.Default.TextureID = skinData[tool.Name]
    end
end
```

## Advanced Examples & Patterns

### Inter-Script Communication (IPC)
Based on `alt_control` scripts, you can use file IO to communicate between multiple accounts (e.g. Host and Alts).

**Host Script:**
```lua
local function send_command(cmd, target)
    local data = { cmd = cmd, target = target, time = tick() }
    writefile("alt_commands.txt", HttpService:JSONEncode(data))
end
```

**Alt Script:**
```lua
local lastTime = 0
while true do
    if isfile("alt_commands.txt") then
        local data = HttpService:JSONDecode(readfile("alt_commands.txt"))
        if data.time > lastTime then
            lastTime = data.time
            -- execute command
        end
    end
    task.wait(0.1)
end
```

### Animation Replacement (`animations`)
To change animations without valid IDs, you can clone and replace the `Animate` script in the character.
```lua
local function replace_anim(char, anims)
    local animate = char:FindFirstChild("Animate")
    if animate then
        animate.Archivable = true
        local newAnim = animate:Clone()
        animate:Destroy()
        -- ... set new AnimationIds in newAnim values ...
        newAnim.Parent = char
    end
end
api:on_event("localplayer_spawned", function(char)
    replace_anim(char, myAnims)
end)
```

### Physics & Seat Claiming (`seat_fling_improved`)
Gain network ownership of unanchored parts by sitting in them (if seats) or using `sethiddenproperty`.
```lua
-- Simulation Radius Trick for Physics Control
sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)

-- Seat Claiming Logic
seat:Sit(humanoid)
task.wait(0.2)
seat:SetNetworkOwner(LocalPlayer)
humanoid.Sit = false
```

### Bullet Trace Listener (`anti-fakepos`)
Listen to `MainEvent` "ClientBullet" to detect where bullets are actually going vs where players look like they are.
```lua
api:add_connection(ReplicatedStorage.MainEvent.OnClientEvent:Connect(function(mode, ...)
    if mode == "ClientBullet" then
        local shooter, _, forcedorigin = ...
        -- Calculate distance between shooter HRP and forcedorigin to detect desync/fakepos
    end
end))
```

### Da Hood Specific Patterns

### Stomping Logic (`auto_stomp_v2`)
Standard stomp with "sticky" physics to stay on target.
```lua
local MainEvent = ReplicatedStorage:WaitForChild("MainEvent")
-- ...
if status["K.O"] or status.SDeath then
    -- Sticky Glue (Aggressive)
    sethiddenproperty(my_root, "PhysicsRepRootPart", target_root)
    -- Action
    MainEvent:FireServer("Stomp")
end
```

### Bagging Logic (`auto_bag_v2`)
Bagging logic involves buying the item if missing, equipping it, and activating it on a knocked target.
```lua
-- Buy if missing
if not LocalPlayer.Backpack:FindFirstChild("[BrownBag]") then
    api:buy_item("brownbag")
end

-- Check success (Christmas_Sock appears in target character)
if target.Character:FindFirstChild("Christmas_Sock") then
    -- Success!
end

-- Action
bag:Activate()
```

### Protection / Anti-Aim (`anti aim protection`)
Detecting if a player is aiming at you using Raycasts.
```lua
local lookDir = theirHead.CFrame.LookVector
local toMe = (myHRP.Position - theirHead.Position).Unit
local dot = lookDir:Dot(toMe)

if dot > 0.8 and hasGun(theirPlayer) then
    -- They are aiming at you!
    api:add_ragebot_target(theirPlayer)
end
```

### Formation Math (Reusable Snippets)
Common math patterns found in `alt.lua` for positioning objects/characters.

**Circle/Orbit:**
```lua
local angle = (slot / total) * math.pi * 2
local x = math.cos(angle) * radius
local z = math.sin(angle) * radius
local pos = center + Vector3.new(x, 0, z)
```

**V-Shape:**
```lua
local side = slot % 2 == 0 and 1 or -1
local depth = math.floor(slot / 2) * 4
local width = math.floor(slot / 2) * 3 * side
local pos = center + Vector3.new(width, 0, depth)
```

### Reusable UI Components
From `custom_ui.lua`, here is a robust pattern for a custom Color Picker using `UIGradient`:

**Color Picker Strip Logic:**
```lua
local function AddColorBar(pos, gradient, cb)
    local Bar = Instance.new("ImageButton")
    -- ... setup properties ...
    local G = Instance.new("UIGradient")
    G.Color = gradient
    G.Parent = Bar
    
    -- Input Handling
    local function Update(input)
        local x = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        cb(x)
    end
    -- Bind InputBegan, InputEnded, InputChanged to Update
end

-- Usage for Hue:
AddColorBar(UDim2.new(0, 12, 0, 5), ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromHSV(0,1,1)),
    -- ... other keypoints ...
    ColorSequenceKeypoint.new(1, Color3.fromHSV(1,1,1))
}, function(val)
    h = val
    UpdateColor()
end)
```

---

# 📦 Legion Library Utilities

---

## Service Helper
Safe service getter with cloneref.
```lua
local function service(name)
    return cloneref(game:GetService(name))
end
local Players = service("Players")
local ReplicatedStorage = service("ReplicatedStorage")
local MainEvent = ReplicatedStorage:WaitForChild("MainEvent")
```

## Connection Manager
Track and disconnect connections by name.
```lua
local Connections = {}

function Library:AddConnection(name, connection)
    assert(typeof(connection) == "RBXScriptConnection")
    Connections[name] = connection
end

function Library:RemoveConnection(name)
    if Connections[name] then
        Connections[name]:Disconnect()
        Connections[name] = nil
    end
end
```

## Quick Instance Creator
Create instances with properties in one call.
```lua
function Library:Create(type, properties)
    local inst = Instance.new(type)
    for k, v in pairs(properties) do
        inst[k] = v
    end
    return inst
end

-- Usage:
local part = Library:Create("Part", {
    Size = Vector3.new(5, 5, 5),
    Position = Vector3.new(0, 10, 0),
    Anchored = true,
    Parent = workspace
})
```

---

## Animation System

### Create Animation Object
```lua
function Library:CreateAnimation(id)
    local Animation = Instance.new("Animation")
    Animation.AnimationId = "rbxassetid://" .. id
    return Animation
end
```

### Play Animation with Options
```lua
function Library:PlayAnimation(character, id, speed, time, smoothing)
    -- Stop if already playing
    for _, anim in pairs(character.Humanoid:GetPlayingAnimationTracks()) do
        if anim.Animation.AnimationId:match(tostring(id)) then
            anim:Stop()
        end
    end
    
    local Animation = Instance.new("Animation")
    Animation.AnimationId = "rbxassetid://" .. tostring(id)
    local LoadedAnim = character.Humanoid:LoadAnimation(Animation)
    LoadedAnim.Priority = Enum.AnimationPriority.Action4
    
    if smoothing then LoadedAnim:Play(tonumber(smoothing))
    else LoadedAnim:Play() end
    
    if speed then LoadedAnim:AdjustSpeed(tonumber(speed)) end
    if time then LoadedAnim.TimePosition = tonumber(time) end
    
    Animation:Destroy()
end
```

### Stop Animation by ID
```lua
function Library:StopAnimation(character, id)
    for _, anim in pairs(character.Humanoid:GetPlayingAnimationTracks()) do
        if anim.Animation.AnimationId:match("rbxassetid://" .. tostring(id)) then
            anim:Stop()
        end
    end
end
```

### Check Animation Playing
```lua
function Library:IsAnimPlaying(character, id)
    for _, anim in pairs(character.Humanoid:GetPlayingAnimationTracks()) do
        if anim.Animation.AnimationId:match("rbxassetid://" .. tostring(id)) then
            return true
        end
    end
    return false
end
```

---

## Audio System

### Play Boombox Audio
```lua
function Library:PlayAudio(id)
    local Boombox = LocalPlayer.Backpack:FindFirstChild("[Boombox]")
    if Boombox then
        Boombox.Parent = LocalPlayer.Character
        MainEvent:FireServer("Boombox", tonumber(id))
        Boombox.RequiresHandle = false
        Boombox.Parent = LocalPlayer.Backpack
        LocalPlayer.PlayerGui.MainScreenGui.BoomboxFrame.Visible = false
        
        -- Wait for sound to finish
        local sound = LocalPlayer.Character.LowerTorso:WaitForChild("BOOMBOXSOUND")
        task.wait(sound.TimeLength)
        Library:StopAudio()
    else
        -- Fallback: play locally
        local FakeSound = Instance.new("Sound", workspace)
        FakeSound.SoundId = "rbxassetid://" .. tostring(id)
        FakeSound:Play()
        task.wait(FakeSound.TimeLength)
        FakeSound:Destroy()
    end
end
```

### Stop Boombox
```lua
function Library:StopAudio()
    MainEvent:FireServer("BoomboxStop")
end
```

---

## Character Manipulation

### Zero All Velocity
```lua
function Library:NoVelocity(character)
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
            part.Velocity = Vector3.zero
        end
    end
end
```

### Remove Limbs (Send to Void)
```lua
function Library:Remove(character, part)
    if part == "all" then
        character.LeftUpperLeg.Position = Vector3.new(0, -1200, 0)
        character.RightUpperLeg.Position = Vector3.new(0, -1200, 0)
        character.LeftUpperArm.Position = Vector3.new(0, -1200, 0)
        character.RightUpperArm.Position = Vector3.new(0, -1200, 0)
    else
        character[part].Position = Vector3.new(0, -1200, 0)
    end
end
```

### Set CanCollide on All Parts
```lua
function Library:CanCollide(character, value)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = value
        end
    end
end
```

### Void Fling (BodyVelocity Down)
```lua
function Library:Void(character, part, drop)
    local BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    BodyVelocity.Velocity = Vector3.new(0, -9e9, 0)
    BodyVelocity.Parent = character[part or "UpperTorso"]
    
    if not drop then
        MainEvent:FireServer("Grabbing", false)
    end
end
```

---

## Utility Functions

### Spectate Player
```lua
function Library:View(target)
    if workspace.Players:FindFirstChild(target) then
        workspace.Camera.CameraSubject = workspace.Players[target].Humanoid
    end
end
```

### Get Player's Vehicle
```lua
function Library:GetCar()
    local Vehicles = workspace:FindFirstChild("Vehicles")
    return Vehicles and Vehicles:FindFirstChild(LocalPlayer.Name)
end
```

### Send Chat Message
```lua
function Library:Chat(message)
    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
end
```

### Quick Tween
```lua
function Library:Tween(part, duration, properties)
    local Tween = game:GetService("TweenService"):Create(
        part,
        TweenInfo.new(duration),
        properties
    )
    Tween:Play()
end

-- Usage:
Library:Tween(part, 1, { CFrame = CFrame.new(0, 10, 0) })
```

---

## Asset Management

### Download Assets to Folder
```lua
function Library:Initialize()
    if not isfolder("MyAssets") then
        makefolder("MyAssets")
    end
    for _, image in pairs(Images) do
        writefile(`MyAssets/{image}.png`, game:HttpGet(`{BaseUrl}/{image}.png`))
    end
end
```

### Get Custom Asset
```lua
function Library:getAsset(name)
    local path = `MyAssets/{name}.png`
    if isfile(path) then
        return getcustomasset(path)
    end
end
```

---

## Preset Animation IDs (Da Hood Compatible)
```lua
local Animations = {
    Grab = 3135389157,
    Roll = 2791328524,
    Angry = 2788838708,
    Punch = 3354696735,
    Elevate = 11394033602,
    Double_Handle = 4784557631,
    GetOverHere = 16768625968,
    
    -- Iron Man
    IM_Freefall = 13850654420,
    IM_Land = 13850663836,
    IM_Rizzler = 13850680182,
    
    -- JoJo
    Ora1 = 8254787838,
    Ora2 = 8254794168,
    PunchBack = 17360699557,
    TimeStopCharging = 10714177846,
}
```

## Preset Sound IDs (Da Hood Compatible)
```lua
local Sounds = {
    Rip = 429400881,
    Ora = 6889746326,
    Kick = 6899466638,
    Punch = 3280066384,
    Lightning = 6955233353,
    LoudPunch = 2319521125,
    ZaWarudo = 8981087259,
    
    -- JoJo Barrages
    Dora = 6995347277,  -- Josuke
    OraBarrage = 6678126154,  -- Jotaro
    ShortMuda = 6564057272,  -- Diego AU
    
    -- Time Stop
    TimeStop = 5455437798,
    TimeResume = 3084539117,
    MudaMuda = 6889746326,
    
    -- Voicelines
    YareYare = 8657023668,
    TheGreatestHigh = 6177204732,
    StarPlatinum = 5059176420,
}
```

---

# 🎮 Additional Script Patterns

---

## Grenade Teleport (`grenade teleport.lua`)

### Grenade Detection via ChildAdded
Monitor workspace for new grenades.
```lua
workspace.ChildAdded:Connect(function(child)
    local name = child.Name:lower()
    if name:find("grenade") or name:find("flashbang") or name:find("rpg") then
        task.wait(0.05)
        TeleportGrenade(child)
    end
end)
```

### Hidden Property Teleport
Use sethiddenproperty for projectile control.
```lua
local function TeleportGrenade(grenade)
    local handle = grenade:FindFirstChild("Handle") or grenade:FindFirstChild("Head")
    local targetPart = target.Character.HumanoidRootPart
    
    sethiddenproperty(handle, "CFrame", targetPart.CFrame)
    sethiddenproperty(handle, "Velocity", Vector3.zero)
    sethiddenproperty(handle, "RotVelocity", Vector3.zero)
end
```

### Loop Teleport (Sticky Grenade)
Keep grenade attached to target.
```lua
if LoopTP.Value then
    task.spawn(function()
        local startTime = tick()
        while handle and handle.Parent and (tick() - startTime < 3) do
            if target.Character and target.Character.HumanoidRootPart then
                sethiddenproperty(handle, "CFrame", target.Character.HumanoidRootPart.CFrame)
            end
            task.wait()
        end
    end)
end
```

### Closest Player to Mouse Fallback
Find target based on screen proximity.
```lua
local function GetClosestToMouse()
    local closest, maxDist = nil, 500
    local mouse = LocalPlayer:GetMouse()
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if onScreen then
                local dist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                if dist < maxDist then
                    maxDist, closest = dist, p
                end
            end
        end
    end
    return closest
end
```

---

## Gun Skin Changer (`gun changer.txt`)

### Dynamic Skin Discovery from SkinModules
```lua
local function GetAvailableSkins()
    local skinList = {}
    local gunModels = ReplicatedStorage.SkinModules.GunModels
    for _, model in pairs(gunModels:GetChildren()) do
        table.insert(skinList, model.Name)
    end
    table.sort(skinList)
    return skinList
end
```

### Skin Overlay via WeldConstraint
Clone and weld skin model to weapon.
```lua
local function ApplySkin(tool, skinName)
    local handle = tool:FindFirstChild("Handle")
    local skinModel = GetSkinModel(skinName)
    
    local clonedModel = skinModel:Clone()
    local modelHandle = clonedModel:FindFirstChild("Handle")
    modelHandle.CanCollide = false
    
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = modelHandle
    weld.Parent = modelHandle
    
    clonedModel.Parent = tool
    handle.Transparency = 1  -- Hide original
    OverlayModel = clonedModel
end
```

### Auto-Apply on Equip
```lua
char.ChildAdded:Connect(function(child)
    if child:IsA("Tool") and child.Name == "Rifle" then
        task.wait(0.05)
        ApplySkin(child, CurrentSkin)
    end
end)
```

---

## Anti-Aim Protection (`anti aim protection.lua`)

### Aim Detection via Dot Product
Calculate if player is aiming at you.
```lua
local function isAimingAtMe(p)
    local theirHead = p.Character.Head
    local myHRP = LocalPlayer.Character.HumanoidRootPart
    
    -- Distance check
    local dist = (myHRP.Position - theirHead.Position).Magnitude
    if dist > detectionRange then return false end
    
    -- Direction check
    local lookDir = theirHead.CFrame.LookVector
    local toMe = (myHRP.Position - theirHead.Position).Unit
    local dot = lookDir:Dot(toMe)
    
    -- Calculate miss distance
    local aimPoint = theirHead.Position + lookDir * dist
    local missDistance = (aimPoint - myHRP.Position).Magnitude
    
    return dot > 0.8 and missDistance < aimThreshold
end
```

### Gun Detection
```lua
local function hasGun(p)
    local tool = p.Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    
    local gunNames = {"glock", "revolver", "ak", "ar", "shotgun", "smg", "rifle", "deagle"}
    local name = tool.Name:lower()
    for _, g in ipairs(gunNames) do
        if name:find(g) then return true end
    end
    return false
end
```

### K.O. Status Check (Multiple Methods)
```lua
local function isKnocked(p)
    -- API method
    local status = api:get_status_cache(p)
    if status and status["K.O"] then return true end
    
    -- Humanoid health
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return true end
    
    -- BodyEffects K.O value
    local be = p.Character:FindFirstChild("BodyEffects")
    local ko = be and be:FindFirstChild("KO")
    if ko and ko.Value then return true end
    
    return false
end
```

### Crew Check via DataFolder
```lua
local function isInCrew(p)
    local myData = LocalPlayer:FindFirstChild("DataFolder")
    local theirData = p:FindFirstChild("DataFolder")
    if myData and theirData then
        local myCrew = myData.Information.Crew.Value
        local theirCrew = theirData.Information.Crew.Value
        if myCrew ~= "" and myCrew == theirCrew then
            return true
        end
    end
    return false
end
```

---

## Target Logger (`alt control.lua`)

### Webhook Logging
```lua
local function send_to_webhook(title, desc)
    local data = {
        embeds = {{
            title = title,
            description = desc,
            color = 16711680,
        }}
    }
    syn.request({
        Url = webhookUrl,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(data)
    })
end
```

### Target Changed Event
```lua
api:on_event("targetchanged", function(target)
    if not target or not target.Parent then return end
    local plr = Players:GetPlayerFromCharacter(target.Parent)
    if plr and plr ~= LocalPlayer then
        send_to_webhook("Silent aim target", plr.Name .. " | Part: " .. target.Name)
    end
end)
```

### Ragebot Status Polling
```lua
RunService.Heartbeat:Connect(function()
    if not api:is_ragebot() then return end
    
    local status, data = api:get_ragebot_status()
    if status == "killing" and data and data.Parent then
        local plr = Players:GetPlayerFromCharacter(data.Parent)
        if plr then
            send_to_webhook("Ragebot target", plr.Name)
        end
    end
end)
```

---

## Face Camera Lock (`face camera lock.lua`)

### Camera Position by Mode
```lua
local function getCameraPosition()
    local head = char:FindFirstChild("Head")
    local headLook = head.CFrame.LookVector
    local headRight = head.CFrame.RightVector
    
    if mode == "Head Direction" then
        camPos = head.Position - headLook * distance + Vector3.new(0, yOffset, 0)
        lookAt = head.Position + headLook * 100
    elseif mode == "Front" then
        camPos = head.Position + headLook * distance + Vector3.new(0, yOffset, 0)
        lookAt = head.Position
    elseif mode == "Behind" then
        camPos = head.Position - hrp.CFrame.LookVector * distance + Vector3.new(0, yOffset, 0)
        lookAt = head.Position
    elseif mode == "Left" then
        camPos = head.Position - headRight * distance + Vector3.new(0, yOffset, 0)
        lookAt = head.Position
    elseif mode == "Right" then
        camPos = head.Position + headRight * distance + Vector3.new(0, yOffset, 0)
        lookAt = head.Position
    end
    
    return CFrame.new(camPos, lookAt)
end
```

### Smooth Camera Interpolation
```lua
if SmoothToggle.Value then
    local current = Camera.CFrame
    local alpha = math.clamp(SmoothSpeed.Value * 0.016, 0, 1)
    Camera.CFrame = current:Lerp(targetCF, alpha)
else
    Camera.CFrame = targetCF
end
```

---

## Fake Kick Screen (`fake kick.lua`)

### Custom Disconnect Screen
```lua
local function ShowCustomScreen()
    local path = ImagePath.Value
    if not isfile(path) then return end
    
    RemoveBlur()  -- Remove Roblox blur effects
    
    local screen = Instance.new("ScreenGui")
    screen.Name = "CustomDisconnect"
    screen.IgnoreGuiInset = true
    screen.DisplayOrder = 100001  -- Higher than Roblox
    screen.Parent = CoreGui
    
    local img = Instance.new("ImageLabel", screen)
    img.Size = UDim2.new(1, 0, 1, 0)
    img.BackgroundColor3 = Color3.new(0, 0, 0)
    img.Image = getcustomasset(path)
    img.ScaleType = Enum.ScaleType.Stretch
end
```

### Remove Blur Effects
```lua
local function RemoveBlur()
    local lighting = game:GetService("Lighting")
    for _, v in pairs(lighting:GetChildren()) do
        if v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = false
        end
    end
end
```

### Error Prompt Detection
```lua
RunService.RenderStepped:Connect(function()
    local prompt = CoreGui:FindFirstChild("RobloxPromptGui")
    if prompt then
        local overlay = prompt:FindFirstChild("promptOverlay")
        if overlay and overlay:FindFirstChild("ErrorPrompt") and overlay.Visible then
            prompt.Enabled = false  -- Hide Roblox UI
            ShowCustomScreen()      -- Show custom
        end
    end
    
    local errMsg = GuiService:GetErrorMessage()
    if errMsg and errMsg ~= "" then
        ShowCustomScreen()
    end
end)
```

---

## Random Teleport Loop (`Leaked private rivals lua.lua`)

### Continuous Random Teleport
```lua
local function teleportOnce()
    local currentPos = hrp.Position
    local randomAngle = math.random() * math.pi * 2
    local randomDist = math.random(MIN_DISTANCE, MAX_DISTANCE)
    
    local newX = currentPos.X + math.cos(randomAngle) * randomDist
    local newZ = currentPos.Z + math.sin(randomAngle) * randomDist
    local newY = currentPos.Y + 100
    
    hrp.CFrame = CFrame.new(newX, newY, newZ)
end

-- Toggle with keybind
local teleportLoop = RunService.Heartbeat:Connect(function()
    teleportOnce()
    wait(TELEPORT_DELAY)
end)
```

---

## Boombox/Ringtone Stealer (`boombox.lua`)

### Get Sound ID from Player's Torso
```lua
local function get_sound_id(player, sound_name)
    local torso = player.Character:FindFirstChild("LowerTorso")
    if not torso then return end
    
    local sound = torso:FindFirstChild(sound_name)
    if not sound or not sound:IsA("Sound") then return end
    
    local str = tostring(sound.SoundId)
    local split = string.split(str, "//")
    return split[2]  -- Returns just the ID number
end

-- Usage:
local boomboxId = get_sound_id(targetPlayer, "BOOMBOXSOUND")
local ringtoneId = get_sound_id(targetPlayer, "PhoneRing")
setclipboard(boomboxId)
```

### Unified Target Resolver
Get target from multiple sources.
```lua
local function get_target_player()
    -- Priority: Ragebot > Aimbot > Silent > Dropdown
    local rageTarget = api:get_target("ragebot")
    if rageTarget then return rageTarget end
    
    local aimbotTarget = api:get_target("aimbot")
    if aimbotTarget then return aimbotTarget end
    
    local silentTarget = api:get_target("silent")
    if silentTarget then return silentTarget end
    
    -- Fallback to UI dropdown
    local selectedName = api:get_flag("target_dropdown")
    if selectedName then
        return Players:FindFirstChild(selectedName)
    end
end
```

### Dynamic Player Dropdown Refresh
```lua
local function refresh_dropdown()
    local values = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(values, plr.Name)
        end
    end
    targetDropdown:SetValues(values)
end

RunService.Heartbeat:Connect(refresh_dropdown)
```

---

## Avatar Cloner / Morph System (`avatar cloner.lua`)

### Get Character Appearance
```lua
local function Morph(UserId)
    local appearance = Players:GetCharacterAppearanceAsync(UserId)
    if not appearance then return end
    
    local char = LocalPlayer.Character
    
    -- Clear existing appearance
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") 
           or v:IsA("CharacterMesh") or v:IsA("BodyColors") then
            v:Destroy()
        end
    end
    if char.Head:FindFirstChild("face") then
        char.Head.face:Destroy()
    end
    
    -- Apply new appearance
    for _, v in pairs(appearance:GetChildren()) do
        if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
            v.Parent = char
        elseif v:IsA("Accessory") then
            char.Humanoid:AddAccessory(v)
        elseif v:IsA("CharacterMesh") then
            if char.Humanoid.RigType == Enum.HumanoidRigType.R6 then
                v.Parent = char
            end
        end
    end
    
    -- Apply face
    if appearance:FindFirstChild("face") then
        appearance.face.Parent = char.Head
    end
end
```

### Headless Effect
```lua
local function applyHeadless()
    local head = LocalPlayer.Character.Head
    local mesh = head:FindFirstChildOfClass("SpecialMesh")
    if mesh then
        mesh.Scale = Vector3.new(0, 0, 0)  -- Tiny head trick
    end
    head.Transparency = 1
    if head:FindFirstChild("face") then
        head.face.Transparency = 1
    end
end
```

### Korblox Leg Effect (R6)
```lua
local function applyKorblox()
    local char = LocalPlayer.Character
    local leg = char:FindFirstChild("Right Leg")
    if not leg then return end
    
    -- Remove existing meshes
    for _, v in pairs(leg:GetChildren()) do
        if v:IsA("DataModelMesh") then v:Destroy() end
    end
    
    -- Remove CharacterMesh overrides
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("CharacterMesh") and v.BodyPart == Enum.BodyPart.RightLeg then
            v:Destroy()
        end
    end
    
    -- Apply Korblox mesh
    local mesh = Instance.new("SpecialMesh", leg)
    mesh.Name = "KorbloxMesh"
    mesh.MeshId = "rbxassetid://902942093"
    mesh.TextureId = "rbxassetid://902843398"
    mesh.Scale = Vector3.new(1, 1, 1)
end
```

### Character Refresh
```lua
local function refreshCharacter()
    local char = LocalPlayer.Character
    local parent = char.Parent
    char.Parent = nil
    char.Parent = parent
end
```

---

## Vehicle Tuner (`car speed changger.lua`)

### Tune Vehicle Attributes
```lua
local function tune_skin(skin)
    if skin:GetAttribute("Speed") ~= nil then
        skin:SetAttribute("Speed", Config.Speed)
    end
    if skin:GetAttribute("Torque") ~= nil then
        skin:SetAttribute("Torque", Config.Torque)
    end
    if skin:GetAttribute("Jump") ~= nil then
        skin:SetAttribute("Jump", Config.Jump)
    end
end

local function tune_vehicle(model)
    local skin = model:FindFirstChild("Skin")
    if skin then
        tune_skin(skin)
    end
end
```

### Tune All Vehicles in Workspace
```lua
function tune_all_vehicles()
    for _, v in ipairs(workspace.Vehicles:GetChildren()) do
        if string.find(v.Name, Config.TargetVehicle) then
            tune_vehicle(v)
        end
    end
end
```

### Vehicle Presets
```lua
-- Legit Mode
Config.Speed = 80
Config.Torque = 50
Config.Jump = 0

-- Fast Mode
Config.Speed = 150
Config.Torque = 100
Config.Jump = 50

-- Max Speed
Config.Speed = 300
Config.Torque = 200
Config.Jump = 200
```

### Hook New Vehicles
```lua
workspace.Vehicles.ChildAdded:Connect(function(vehicle)
    task.wait(0.1)
    tune_vehicle(vehicle)
end)
```

---

## Cart Car Controller (`cart.lua`)

### Connection Handler Pattern
Track and manage named connections.
```lua
local Handler = {}
Handler.Connections = {}

function Handler:AddConnection(name, connection)
    if not self.Connections[name] then
        self.Connections[name] = {}
    end
    table.insert(self.Connections[name], api:add_connection(connection))
end

function Handler:Connected(names)
    for _, name in pairs(names) do
        if self.Connections[name] and #self.Connections[name] > 0 then
            return true
        end
    end
    return false
end

function Handler:Disconnect(names)
    for _, name in pairs(names) do
        if self.Connections[name] then
            for _, conn in pairs(self.Connections[name]) do
                if conn and conn.Disconnect then
                    conn:Disconnect()
                end
            end
            self.Connections[name] = {}
        end
    end
end
```

### Cart Physics Setup
Add BodyVelocity, BodyAngularVelocity, and BodyGyro for WASD control.
```lua
local function setupCartPhysics(Seat)
    local BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.Name = "Move"
    BodyVelocity.MaxForce = Vector3.new(99e99, 0, 99e99)
    BodyVelocity.Velocity = Vector3.zero
    BodyVelocity.Parent = Seat
    
    local BodyAngularVelocity = Instance.new("BodyAngularVelocity")
    BodyAngularVelocity.Name = "Rotate"
    BodyAngularVelocity.MaxTorque = Vector3.new(0, 99e99, 0)
    BodyAngularVelocity.AngularVelocity = Vector3.zero
    BodyAngularVelocity.Parent = Seat
    
    local BodyGyro = Instance.new("BodyGyro")
    BodyGyro.Name = "Stabilizer"
    BodyGyro.MaxTorque = Vector3.new(99e99, 0, 99e99)
    BodyGyro.P = 10000
    BodyGyro.D = 1000
    BodyGyro.CFrame = Seat.CFrame
    BodyGyro.Parent = Seat
    
    return BodyVelocity, BodyAngularVelocity, BodyGyro
end
```

### WASD Input Control
```lua
local W, S, A, D = false, false, false, false

UserInputService.InputBegan:Connect(function(Input, Locked)
    if Locked then return end
    if Input.KeyCode == Enum.KeyCode.W then W = true
    elseif Input.KeyCode == Enum.KeyCode.S then S = true
    elseif Input.KeyCode == Enum.KeyCode.A then A = true
    elseif Input.KeyCode == Enum.KeyCode.D then D = true end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.KeyCode == Enum.KeyCode.W then W = false
    elseif Input.KeyCode == Enum.KeyCode.S then S = false
    elseif Input.KeyCode == Enum.KeyCode.A then A = false
    elseif Input.KeyCode == Enum.KeyCode.D then D = false end
end)
```

### Cart Movement Loop
```lua
RunService.Heartbeat:Connect(function()
    local LookVector = Seat.CFrame.LookVector
    
    -- Reduce friction
    Seat.CustomPhysicalProperties = PhysicalProperties.new(0.1, 0.1, 0.1, 0.1, 0.1)
    
    -- Apply velocity based on input
    BodyVelocity.Velocity = (W and Vector3.new(LookVector.X, 0, LookVector.Z) * Speed) 
                         or (S and Vector3.new(-LookVector.X, 0, -LookVector.Z) * Speed) 
                         or Vector3.zero
    
    -- Apply rotation
    BodyAngularVelocity.AngularVelocity = (A and Vector3.new(0, RotateSpeed, 0)) 
                                        or (D and Vector3.new(0, -RotateSpeed, 0)) 
                                        or Vector3.zero
    
    -- Keep upright
    local Unit = Vector3.new(LookVector.X, 0, LookVector.Z).Unit
    BodyGyro.CFrame = CFrame.new(Seat.Position, Seat.Position + Unit)
end)
```

### Find Player's Cart
```lua
local function findPlayerCart()
    local success, Seat = pcall(function()
        return workspace.OldVehicles[LocalPlayer.Name .. "BIKE"]:FindFirstChild("Seat")
    end)
    return success and Seat or nil
end
```

---

## Animation Replacer (`animations.lua`)

### Animation Sets Database
Large collection of animation presets.
```lua
local AnimationSets = {
    ["Ninja"] = {
        idle1 = "http://www.roblox.com/asset/?id=656117400",
        idle2 = "http://www.roblox.com/asset/?id=656118341",
        walk = "http://www.roblox.com/asset/?id=656121766",
        run = "http://www.roblox.com/asset/?id=656118852",
        jump = "http://www.roblox.com/asset/?id=656117878",
        climb = "http://www.roblox.com/asset/?id=656114359",
        fall = "http://www.roblox.com/asset/?id=656115606"
    },
    ["Zombie"] = {
        idle1 = "http://www.roblox.com/asset/?id=616158929",
        -- ... more animations
    },
    -- More sets: Robot, Superhero, Mage, Cartoon, Werewolf, Astronaut, etc.
}
```

### Replace Animate Script
Clone and modify the Animate script with new animation IDs.
```lua
local function replace_animate_script(character, anims)
    local animate = character:FindFirstChild("Animate")
    if not animate then return end
    
    animate.Archivable = true
    local new_animate = animate:Clone()
    animate:Destroy()
    
    local function set_anim(path, id)
        if path and path:IsA("Animation") then
            path.AnimationId = id
        end
    end
    
    set_anim(new_animate.idle.Animation1, anims.idle1)
    set_anim(new_animate.idle.Animation2, anims.idle2)
    set_anim(new_animate.walk.WalkAnim, anims.walk)
    set_anim(new_animate.run.RunAnim, anims.run)
    set_anim(new_animate.jump.JumpAnim, anims.jump)
    set_anim(new_animate.climb.ClimbAnim, anims.climb)
    set_anim(new_animate.fall.FallAnim, anims.fall)
    
    new_animate.Parent = character
    new_animate.Disabled = true
    new_animate.Disabled = false  -- Restart script
end
```

### Custom Animation Input
```lua
local custom_anims = {
    idle1 = "", idle2 = "", walk = "", run = "", jump = "", climb = "", fall = ""
}

-- Input callback
custom_anims.walk = "http://www.roblox.com/asset/?id=" .. inputValue

-- Apply
replace_animate_script(LocalPlayer.Character, custom_anims)
```

### Re-apply on Respawn
```lua
api:on_event("localplayer_spawned", function(char)
    task.wait(0.5)  -- Wait for character to load
    local dropdown = api:get_ui_object("animation_style")
    if dropdown and dropdown.Value then
        try_apply_anim_set(dropdown.Value)
    end
end)
```

### Preset Animation IDs
```lua
-- Common Animation Packs
["Default"] = { idle1 = 180435571, walk = 180426354, jump = 125750702 }
["Ninja"] = { idle1 = 656117400, walk = 656121766, run = 656118852 }
["Robot"] = { idle1 = 616088211, walk = 616095330, run = 616091570 }
["Zombie"] = { idle1 = 616158929, walk = 616168032, run = 616163682 }
["Superhero"] = { idle1 = 616111295, walk = 616122287, run = 616117076 }
["Astronaut"] = { idle1 = 10921034824, walk = 10921046031 }
["Werewolf"] = { idle1 = 10921330408, walk = 10921342074 }
```

---

## AFK Farm (`afk_farm_gui.lua`)

### Touch Interest Farm Loop
Use `firetouchinterest` to simulate touching a part.
```lua
local isFarming = false
local farmSpeed = 0.1

local function getTargetPart()
    local plots = workspace.Main.Plots
    local plot = plots:FindFirstChild(plotName)
    return plot and plot:FindFirstChild("AFKPart")
end

task.spawn(function()
    while isFarming do
        local part = getTargetPart()
        local rootPart = LocalPlayer.Character.HumanoidRootPart
        
        if part and rootPart then
            firetouchinterest(part, rootPart, 0)  -- Touch
            task.wait()
            firetouchinterest(part, rootPart, 1)  -- Untouch
        end
        task.wait(farmSpeed)
    end
end)
```

---

## Auto Bag Target (`auto bag.lua`)

### Find Tool in Character or Backpack
```lua
local function find_bag_anywhere()
    local character = LocalPlayer.Character
    if character then
        local bag = character:FindFirstChild("[BrownBag]")
        if bag then return bag, character end
    end
    
    local backpack = LocalPlayer.Backpack
    if backpack then
        local bag = backpack:FindFirstChild("[BrownBag]")
        if bag then return bag, backpack end
    end
    
    return nil, nil
end
```

### Equip Tool from Backpack
```lua
local function get_bag_tool()
    local bag, parent = find_bag_anywhere()
    if not bag then return nil end
    
    -- Equip if not already equipped
    if parent ~= LocalPlayer.Character then
        bag.Parent = LocalPlayer.Character
    end
    return bag
end
```

### Check if Player is Bagged
Check for "Christmas_Sock" (bag marker).
```lua
local function is_target_bagged(target)
    local model_folder = workspace.Players.Model
    local char_folder = model_folder:FindFirstChild(target.Name)
    return char_folder and char_folder:FindFirstChild("Christmas_Sock") ~= nil
end
```

### Control Void via UI
```lua
local function enter_void()
    local void_in = api:get_ui_object("character_prot_void_in")
    if void_in then void_in:SetValue(true) end
end

local function exit_void()
    local void_out = api:get_ui_object("character_prot_void_out")
    if void_out then void_out:SetValue(true) end
end
```

### Buy Item via API
```lua
if api:can_desync() then
    api:buy_item("brownbag")
end
```

---

## Chat Command Bot (`bot.txt`)

### Save Locations Database
```lua
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
    -- ... many more locations
}
```

### Levenshtein Distance (Fuzzy Matching)
```lua
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
```

### Fuzzy Player Search
```lua
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
```

### Parse Chat Command Arguments
```lua
local function ParseArgs(message, prefix)
    local command = message:match("^" .. prefix .. "(%S+)")
    local argString = message:match("^" .. prefix .. "%S+%s+(.+)") or ""
    
    local args = {}
    for arg in argString:gmatch("[^,%s]+") do
        table.insert(args, arg)
    end
    return command, args, argString
end
```

### Whitelist Players in UI
```lua
local function WhitelistOwner()
    local owner = Players:FindFirstChild(OWNER_USERNAME)
    if owner then
        local whitelist = GetValue("ragebot_whitelist") or {}
        table.insert(whitelist, owner.Name)
        SetOption("ragebot_whitelist", whitelist)
    end
end
```

### K.O. / Dead Status Check
```lua
local function IsKO(player)
    local bodyEffects = player.Character:FindFirstChild("BodyEffects")
    if bodyEffects and bodyEffects:FindFirstChild("K.O") then
        return bodyEffects["K.O"].Value
    end
    return false
end

local function IsDead(player)
    local bodyEffects = player.Character:FindFirstChild("BodyEffects")
    if bodyEffects and bodyEffects:FindFirstChild("Dead") then
        return bodyEffects["Dead"].Value
    end
    return false
end
```

### Void Bot (Timed Void Protection)
```lua
local function VoidBot(duration)
    SetOption("character_prot_void", true)
    task.wait(duration)
    SetOption("character_prot_void", false)
end
```

### Find Who is Carrying a Player
```lua
local function GetCarrier(targetPlayer)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= targetPlayer and plr.Character then
            local grabConstraint = plr.Character:FindFirstChild("GRABBING_CONSTRAINT", true)
            if grabConstraint then
                local att0 = grabConstraint.Attachment0
                if att0 and att0.Parent:IsDescendantOf(targetPlayer.Character) then
                    return plr
                end
            end
        end
    end
    return nil
end
```

### Auto Heal Bot
```lua
local function AutoHealBot()
    local humanoid = LocalPlayer.Character.Humanoid
    if humanoid.Health >= humanoid.MaxHealth * 0.7 then return end
    
    repeat task.wait() until api:can_desync()
    api:buy_item("meat")
    task.wait(1)
    
    local meat = LocalPlayer.Backpack:FindFirstChild("meat")
    if meat then
        LocalPlayer.Character.Humanoid:EquipTool(meat)
        task.wait(0.3)
        meat:Activate()
        task.wait(0.5)
        VoidBot(2)
    end
end
```

### Knock Player with Callback
```lua
local function KnockPlayer(targetPlayer, callback)
    if IsKO(targetPlayer) then
        if callback then callback(true) end
        return true
    end
    
    CurrentTarget = targetPlayer
    SetOption("ragebot_targets", targetPlayer.Name)
    SetOption("ragebot_use_selected", true)
    api:get_ui_object("ragebot_keybind"):OverrideState(true)
    api:set_ragebot(true)
    
    local timeout = 0
    local conn = RunService.Heartbeat:Connect(function()
        timeout = timeout + (1/60)
        
        if IsKO(targetPlayer) or IsDead(targetPlayer) then
            SetOption("ragebot_targets", {})
            api:get_ui_object("ragebot_keybind"):OverrideState(false)
            api:set_ragebot(false)
            conn:Disconnect()
            if callback then callback(true) end
        elseif timeout >= 20 then
            -- Timeout
            conn:Disconnect()
            if callback then callback(false) end
        end
    end)
end
```

### Reliable Bring (Grab & Teleport)
```lua
local function ReliableBring(targetPlayer)
    if not IsKO(targetPlayer) then return end
    
    local stompOffset = 3.5
    
    -- Position above target
    local positionLoop = RunService.Heartbeat:Connect(function()
        api:set_desync_cframe(CFrame.new(targetPlayer.Character.UpperTorso.Position + Vector3.new(0, stompOffset, 0)))
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
        task.wait(0.2)
    end
    
    positionLoop:Disconnect()
    
    if grabbed then
        -- Teleport to owner
        local owner = Players:FindFirstChild(OWNER_USERNAME)
        local bringPos = owner.Character.PrimaryPart.CFrame * CFrame.new(5, 0, 5)
        api:set_desync_cframe(bringPos)
    end
end
```

---

# 🛠️ Handler Utility Module

A comprehensive utility module for Da Hood scripting.

---

## Service Helper with CloneRef
```lua
function Service(name)
    return cloneref(game:GetService(name))
end

local Players = Service("Players")
local Workspace = Service("Workspace")
local RunService = Service("RunService")
```

---

## Character Part Getters
```lua
function Handler:Humanoid(Player)
    if Player and Player.Character then
        return Player.Character:FindFirstChildOfClass("Humanoid")
    end
end

function Handler:UpperTorso(Player)
    if Player and Player.Character then
        return Player.Character:FindFirstChild("UpperTorso")
    end
end

function Handler:HumanoidRootPart(Player)
    if Player and Player.Character then
        return Player.Character:FindFirstChild("HumanoidRootPart")
    end
end

function Handler:ForceField(Player)
    if Player and Player.Character then
        return Player.Character:FindFirstChild("ForceField")
    end
end
```

---

## Status Checks
```lua
function Handler:Is_KO(Player)
    local bodyEffects = Player.Character:FindFirstChild("BodyEffects")
    if bodyEffects and bodyEffects:FindFirstChild("K.O") then
        return bodyEffects["K.O"]
    end
end

function Handler:Is_Dead(Player)
    local bodyEffects = Player.Character:FindFirstChild("BodyEffects")
    if bodyEffects and bodyEffects:FindFirstChild("SDeath") then
        return bodyEffects["SDeath"]
    end
end

function Handler:Is_Attacking(Player)
    local bodyEffects = Player.Character:FindFirstChild("BodyEffects")
    if bodyEffects and bodyEffects:FindFirstChild("Attacking") then
        return bodyEffects["Attacking"]
    end
end

function Handler:Is_Reloading()
    local bodyEffects = LocalPlayer.Character:FindFirstChild("BodyEffects")
    local reloading = bodyEffects and bodyEffects:FindFirstChild("Reload")
    return reloading and reloading.Value or false
end
```

---

## Crew Check
```lua
function Handler:Is_Crew(Player, Target)
    local playerData = Player:FindFirstChild("DataFolder")
    local targetData = Target:FindFirstChild("DataFolder")
    if playerData and targetData then
        local playerCrew = playerData.Information.Crew
        local targetCrew = targetData.Information.Crew
        if playerCrew.Value ~= "" and playerCrew.Value == targetCrew.Value then
            return true
        end
    end
    return false
end
```

---

## Tool Cache
Get detailed info about equipped tool.
```lua
function Handler:Cache_Tool()
    local Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if Tool then
        local Handle = Tool:FindFirstChild("Handle")
        if Handle then
            return {
                Instance = Tool,
                Handle = Handle,
                Offset = Vector3.new(0, 0, -Handle.Size.Z / 2),
                Ammo = Tool:FindFirstChild("Ammo") and Tool.Ammo.Value or 0,
                MaxAmmo = Tool:FindFirstChild("MaxAmmo") and Tool.MaxAmmo.Value or 0,
                Gun = Tool:FindFirstChild("GunClient") ~= nil,
                Shotgun = Tool:FindFirstChild("GunClientShotgun") ~= nil,
                Automatic = Tool:FindFirstChild("GunClientAutomatic") ~= nil,
                Client = not (Gun or Shotgun or Automatic)
            }
        end
    end
end
```

---

## Connection Manager
```lua
getgenv().Connections = {}
local Connections = getgenv().Connections

function Handler:AddConnection(Name, Connection)
    if typeof(Connection) ~= "RBXScriptConnection" then return end
    
    if typeof(Connections[Name]) == "RBXScriptConnection" and Connections[Name].Connected then
        Connections[Name]:Disconnect()
    end
    Connections[Name] = Connection
end

function Handler:Connected(Name)
    if typeof(Connections[Name]) == "RBXScriptConnection" then
        return Connections[Name].Connected
    elseif typeof(Connections[Name]) == "table" then
        for i = 1, #Connections[Name] do
            if Connections[Name][i].Connected then return true end
        end
    end
    return false
end

function Handler:Disconnect(Name, Nil)
    if typeof(Name) == "table" then
        for i = 1, #Name do self:Disconnect(Name[i], Nil) end
        return
    end
    
    if typeof(Connections[Name]) == "RBXScriptConnection" and Connections[Name].Connected then
        Connections[Name]:Disconnect()
    end
    
    if Nil then Connections[Name] = nil end
end

function Handler:Unload()
    for Name, Connection in pairs(Connections) do
        if typeof(Connection) == "RBXScriptConnection" and Connection.Connected then
            Connection:Disconnect()
        end
    end
    table.clear(Connections)
end
```

---

## Player Search
```lua
function Handler:Get_Player(Text)
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            if Player.Name:lower():sub(1, #Text) == Text:lower() then return Player end
            if Player.DisplayName:lower():sub(1, #Text) == Text:lower() then return Player end
        end
    end
    return nil
end

function Handler:Get_Mouse_Player()
    local Player, Shortest = nil, math.huge
    
    for _, Target in ipairs(Players:GetPlayers()) do
        if Target ~= LocalPlayer and Target.Character and Target.Character:FindFirstChild("Head") then
            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Target.Character.Head.Position)
            if OnScreen then
                local Distance = (Vector2.new(ScreenPos.X, ScreenPos.Y) - Vector2.new(LocalPlayer:GetMouse().X, LocalPlayer:GetMouse().Y)).Magnitude
                if Distance < Shortest then
                    Player, Shortest = Target, Distance
                end
            end
        end
    end
    return Player
end
```

---

## Instance Creator
```lua
function Handler:Create(Type, Properties)
    -- Destroy existing if same name
    if Properties.Name and (Properties.Parent or Workspace):FindFirstChild(Properties.Name) then
        (Properties.Parent or Workspace):FindFirstChild(Properties.Name):Destroy()
    end
    
    local NewInstance = Instance.new(Type)
    for Index, Property in pairs(Properties) do
        NewInstance[Index] = Property
    end
    return NewInstance
end
```

---

## Asset Loading
```lua
function Handler:GetAsset(Result)
    local Results, Asset = {}, {}
    
    for Name, AssetID in pairs(Result) do
        local Assets = game:GetObjects("rbxassetid://" .. AssetID)[1]
        Results[Name] = Assets:Clone()
        table.insert(Asset, Assets)
        
        for _, Object in pairs(Assets:GetDescendants()) do
            table.insert(Asset, Object)
        end
        
        -- Preload trick
        Assets.Parent = nil
        Assets:PivotTo(CFrame.new(1e6, 1e6, 1e6))
        Assets.Parent = workspace
        RunService.RenderStepped:Wait()
        Assets.Parent = nil
    end
    
    ContentProvider:PreloadAsync(Asset)
    return Results
end
```

---

## Animation System
```lua
function Handler:AnimPlay(ID, Speed, Time, Smoothing)
    local humanoid = Handler:Humanoid(LocalPlayer)
    if not humanoid then return end
    
    -- Stop if already playing
    for _, Track in pairs(humanoid:GetPlayingAnimationTracks()) do
        if Track.Animation.AnimationId:match("rbxassetid://" .. ID) then
            Track:Stop()
        end
    end
    
    local Animation = Instance.new("Animation", workspace)
    Animation.AnimationId = "rbxassetid://" .. ID
    local Playing = humanoid:LoadAnimation(Animation)
    Playing.Priority = 4
    
    Playing:Play(Smoothing or nil)
    Playing:AdjustSpeed(Speed or 1)
    if Time then Playing.TimePosition = Time end
    
    Animation:Destroy()
end

function Handler:AnimStop(ID, Speed)
    local humanoid = Handler:Humanoid(LocalPlayer)
    for _, Track in pairs(humanoid:GetPlayingAnimationTracks()) do
        if Track.Animation.AnimationId:match("rbxassetid://" .. ID) then
            Track:Stop(Speed or nil)
        end
    end
end

function Handler:IsAnimPlaying(ID)
    local humanoid = Handler:Humanoid(LocalPlayer)
    for _, Track in pairs(humanoid:GetPlayingAnimationTracks()) do
        if Track.Animation.AnimationId:match("rbxassetid://" .. ID) and Track.IsPlaying then
            return true
        end
    end
    return false
end
```

---

## Sound System
```lua
function Handler:PlaySound(ID, Vol)
    local Sound = Handler:Create("Sound", {
        SoundId = "rbxassetid://" .. ID,
        Volume = Vol,
        Parent = workspace
    })
    Sound:Play()
    Sound.Ended:Connect(function() Sound:Destroy() end)
    return Sound
end

function Handler:StopSound(Sound)
    if Sound and Sound.IsPlaying then
        Sound:Stop()
        Sound:Destroy()
    end
end
```

---

## Character Utilities
```lua
function Handler:Noclip(Character)
    for _, Part in pairs(Character:GetChildren()) do
        if Part:IsA("BasePart") and Part.CanCollide then
            Part.CanCollide = false
        end
    end
end

function Handler:ZeroVelocity(Character)
    for _, Part in pairs(Character:GetChildren()) do
        if Part:IsA("BasePart") then
            Part.Velocity = Vector3.zero
            Part.AssemblyLinearVelocity = Vector3.zero
            Part.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

function Handler:ChangeState(Number)
    pcall(function()
        Handler:Humanoid(LocalPlayer):ChangeState(Number)
    end)
end

function Handler:Equip(Tool)
    if LocalPlayer.Backpack:FindFirstChild(Tool) then
        LocalPlayer.Backpack[Tool].Parent = LocalPlayer.Character
    end
end

function Handler:RemoveAccessory(Character, Accessory)
    for _, Item in pairs(Character:GetChildren()) do
        if Item:IsA(Accessory) then Item:Destroy() end
    end
end
```

---

## Shop Item Finder
```lua
function Handler:Find_Item(Name, Type)
    for _, Shop in pairs(Workspace.Ignored.Shop:GetChildren()) do
        local Lower = Shop.Name:lower()
        if Type and Lower:find("ammo") and Lower:find(Name:lower()) then
            return Shop
        elseif not Type and not Lower:find("ammo") and Lower:find(Name:lower()) then
            return Shop
        end
    end
end
```

---

## Miscellaneous
```lua
function Handler:Tween(Part, Duration, Properties)
    TweenService:Create(Part, TweenInfo.new(Duration), Properties):Play()
end

function Handler:Chat(Message)
    TextChatService.TextChannels.RBXGeneral:SendAsync(Message)
end

function Handler:HttpGet(Url)
    local Success, Result = pcall(function()
        return loadstring(game:HttpGet(Url))
    end)
    if Success and typeof(Result) == "function" then
        return Result()
    end
    return nil
end

function Handler:SendWebhook(Url, Data)
    spawn(function()
        (http_request or request or syn.request)({
            Url = Url,
            Method = "POST",
            Headers = { ["content-type"] = "application/json" },
            Body = game:GetService("HttpService"):JSONEncode(Data),
        })
    end)
end
```

---

# 🔧 Force & Override Methods

Complete guide to programmatically controlling Unnamed API features.

---

## UI Object Access

### Get UI Object by Flag
```lua
local uiObject = api:get_ui_object("flag_name")

-- Common flags:
-- Ragebot: "ragebot_keybind", "ragebot_targets", "ragebot_whitelist", "ragebot_use_selected"
-- Void: "character_prot_void", "character_prot_voidkeybind", "character_prot_void_in", "character_prot_void_out"
-- Combat: "combat_whitelist", "silent_keybind"
```

### Get/Set Value
```lua
-- Get value
local value = api:get_ui_object("ragebot_targets").Value

-- Set value (Toggle, Slider, Input, Dropdown)
api:get_ui_object("ragebot_targets"):SetValue("PlayerName")
api:get_ui_object("character_prot_void"):SetValue(true)
api:get_ui_object("stomp_offset"):SetValue(3.5)

-- Set dropdown values dynamically
api:get_ui_object("player_dropdown"):SetValues({"Player1", "Player2", "Player3"})
```

### Safe Wrapper Functions
```lua
local function GetOption(flag)
    return api:get_ui_object(flag)
end

local function SetOption(flag, value)
    local obj = GetOption(flag)
    if obj then
        obj:SetValue(value)
        return true
    end
    return false
end

local function GetValue(flag)
    local obj = GetOption(flag)
    return obj and obj.Value or nil
end
```

---

## Keybind Override

### Force Keybind State
```lua
-- Force keybind ON (as if user pressed the key)
api:get_ui_object("ragebot_keybind"):OverrideState(true)

-- Force keybind OFF
api:get_ui_object("ragebot_keybind"):OverrideState(false)

-- Void keybind
api:get_ui_object("character_prot_voidkeybind"):OverrideState(true)
```

### Check if Keybind is Active
```lua
local keybind = api:get_ui_object("ragebot_keybind")
if keybind and keybind.Active then
    -- Keybind is currently pressed/active
end
```

### Alternative Method
```lua
api:override_key_state("ragebot_keybind", true)  -- Force on
api:override_key_state("ragebot_keybind", false) -- Force off
```

---

## Ragebot Control

### Enable/Disable Ragebot
```lua
api:set_ragebot(true)   -- Force enable
api:set_ragebot(false)  -- Force disable
api:set_ragebot(nil)    -- Reset to user setting
```

### Check Ragebot Status
```lua
if api:is_ragebot() then
    -- Ragebot is currently active
end

local status, data = api:get_ragebot_status()
-- status: "inactive", "buying", "hiding", "stomping", "killing", "reloading", "no target"
```

### Set Ragebot Target
```lua
-- Set specific target by name
api:get_ui_object("ragebot_targets"):SetValue("TargetPlayerName")

-- Or via Options table (if available)
Options["ragebot_targets"]:SetValue("PlayerName")

-- Clear target
api:get_ui_object("ragebot_targets"):SetValue("nil")
api:get_ui_object("ragebot_targets"):SetValue({})
```

### Use Selected Targets Only
```lua
-- Enable "use selected targets" mode
api:get_ui_object("ragebot_use_selected"):SetValue(true)

-- Disable (use auto-targeting)
api:get_ui_object("ragebot_use_selected"):SetValue(false)
```

---

## Whitelist Management

### Add to Ragebot Whitelist
```lua
local function AddToWhitelist(playerName)
    local whitelist = GetValue("ragebot_whitelist") or {}
    
    -- Check if already whitelisted
    for _, name in ipairs(whitelist) do
        if name == playerName then return end
    end
    
    table.insert(whitelist, playerName)
    SetOption("ragebot_whitelist", whitelist)
end
```

### Remove from Whitelist
```lua
local function RemoveFromWhitelist(playerName)
    local whitelist = GetValue("ragebot_whitelist") or {}
    
    for i, name in ipairs(whitelist) do
        if name == playerName then
            table.remove(whitelist, i)
            SetOption("ragebot_whitelist", whitelist)
            return
        end
    end
end
```

### Clear Whitelist
```lua
SetOption("ragebot_whitelist", {})
```

### Combat Whitelist (Separate)
```lua
local normalWhitelist = GetValue("combat_whitelist") or {}
table.insert(normalWhitelist, "PlayerName")
SetOption("combat_whitelist", normalWhitelist)
```

---

## Void Protection Control

### Enter Void
```lua
api:get_ui_object("character_prot_void_in"):SetValue(true)
-- or
api:get_ui_object("character_prot_voidkeybind"):OverrideState(true)
```

### Exit Void
```lua
api:get_ui_object("character_prot_void_out"):SetValue(true)
-- or
api:get_ui_object("character_prot_voidkeybind"):OverrideState(false)
```

### Toggle Void
```lua
local voidEnabled = GetValue("character_prot_void")
SetOption("character_prot_void", not voidEnabled)
```

### Timed Void
```lua
local function VoidBot(duration)
    SetOption("character_prot_void", true)
    task.wait(duration)
    SetOption("character_prot_void", false)
end
```

---

## Complete Ragebot Control Example

```lua
-- Full control example: Target a player, ragebot them, stop when knocked
local function RagebotPlayer(targetPlayer, callback)
    if not targetPlayer or not targetPlayer.Character then
        if callback then callback(false) end
        return false
    end
    
    -- Set target
    SetOption("ragebot_targets", targetPlayer.Name)
    SetOption("ragebot_use_selected", true)
    
    -- Force keybind on
    api:get_ui_object("ragebot_keybind"):OverrideState(true)
    
    -- Enable ragebot
    api:set_ragebot(true)
    
    -- Monitor for knockout
    local timeout = 0
    local conn = RunService.Heartbeat:Connect(function()
        timeout = timeout + (1/60)
        
        local ko = IsKO(targetPlayer)
        local dead = IsDead(targetPlayer)
        
        if ko or dead or timeout >= 20 then
            -- Stop everything
            SetOption("ragebot_targets", {})
            api:get_ui_object("ragebot_keybind"):OverrideState(false)
            api:set_ragebot(nil)
            conn:Disconnect()
            
            if callback then callback(ko or dead) end
        end
    end)
    
    return true
end
```

---

## Known UI Flags Reference

### Ragebot
| Flag | Type | Description |
|------|------|-------------|
| `ragebot_keybind` | Keybind | Main ragebot toggle keybind |
| `ragebot_targets` | MultiSelect/Input | Target player names |
| `ragebot_whitelist` | MultiSelect | Players to ignore |
| `ragebot_use_selected` | Toggle | Only target selected players |
| `ragebot_stomp_offset` | Slider | Stomp height offset |

### Character Protection
| Flag | Type | Description |
|------|------|-------------|
| `character_prot_void` | Toggle | Void protection toggle |
| `character_prot_voidkeybind` | Keybind | Void keybind |
| `character_prot_void_in` | Button | Enter void |
| `character_prot_void_out` | Button | Exit void |

### Combat
| Flag | Type | Description |
|------|------|-------------|
| `combat_whitelist` | MultiSelect | Combat whitelist |
| `silent_keybind` | Keybind | Silent aim keybind |
| `stomp_offset` | Slider | Stomp offset value |

---

## Tips & Best Practices

1. **Always check if UI object exists** before calling methods
2. **Use `nil` with `set_ragebot`** to restore user's original setting
3. **Use `OverrideState(false)`** to release keybind control
4. **Wrap in `pcall`** for safety when accessing UI objects
5. **Store references** to frequently-used UI objects for performance

```lua
-- Good practice: Cache UI references
local RagebotKeybind = api:get_ui_object("ragebot_keybind")
local RagebotTargets = api:get_ui_object("ragebot_targets")

-- Use cached references
if RagebotKeybind then
    RagebotKeybind:OverrideState(true)
end
```








## Kitten Saver Protector ([haydens kitten saver 900.lua](file:///C:/Users/hayde/AppData/Local/seliware-workspace/unnamed/da hood/lua/scripts/haydens%20kitten%20saver%20900.lua))

### Automated protection system that manages ragebot state based on threats.
```lua
local function refreshRagebot(stop_reason)
    safe_call(function()
        local rb_targets = api:get_ui_object("ragebot_targets")
        local rb_enabled = api:get_ui_object("ragebot_enabled")
        local rb_flame = api:get_ui_object("ragebot_flame")
        local rb_kill_nearby = api:get_ui_object("ragebot_kill_nearby")
        local use_flame = api:get_ui_object("protector_use_flame")
        local threats = {}
        local last_attacker = ""
        for name, _ in pairs(active_threats) do
            local p = Players:FindFirstChild(name)
            if p and p.Parent and p.Character then table.insert(threats, name) last_attacker = name
            else active_threats[name] = nil end
        end
        if #threats > 0 and not stomp_connection then
            saveState()
            if rb_targets then pcall(function() rb_targets:SetValue(threats) rb_targets:SetValue(last_attacker) end)
... (truncated)
```


## Protector Follow System ([haydens kitten saver 900.lua](file:///C:/Users/hayde/AppData/Local/seliware-workspace/unnamed/da hood/lua/scripts/haydens%20kitten%20saver%20900.lua))

### Follows the owner with a configurable offset using hidden properties.
```lua
follow_connection = RunService.Heartbeat:Connect(function()
    safe_call(function()
        local active_obj = api:get_ui_object("protector_active")
        local follow_obj = api:get_ui_object("protector_follow_owner")
        local targets_obj = api:get_ui_object("protector_targets")
        
        local should_follow = active_obj and active_obj.Value and follow_obj and follow_obj.Value
        
        -- Don't follow if we are fighting
        if next(active_threats) ~= nil or stomp_connection then should_follow = false end

        if not should_follow then
            if was_following then
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                     pcall(function() sethiddenproperty(LocalPlayer.Character.HumanoidRootPart, "PhysicsRepRootPart", nil) end)
... (truncated)
```


## Quantum Strafe Pattern ([hvh_helper.lua](file:///C:/Users/hayde/AppData/Local/seliware-workspace/unnamed/da hood/lua/scripts/hvh_helper.lua))

### Randomized micro-teleports for HvH.
```lua
local function pattern_quantum(r, ang)
    -- Random micro-teleports within radius
    local jitterX = (math.random() - 0.5) * r * 0.5
    local jitterZ = (math.random() - 0.5) * r * 0.5
    local baseX = r * math.cos(ang)
    local baseZ = r * math.sin(ang)
    return Vector3.new(baseX + jitterX, 0, baseZ + jitterZ)
end
```


## Resolver Prediction Logic ([hvh_helper.lua](file:///C:/Users/hayde/AppData/Local/seliware-workspace/unnamed/da hood/lua/scripts/hvh_helper.lua))

### Predicts target position using velocity, acceleration, and adaptive multipliers.
```lua
local function resolvePosition(part, origin, now, dt)
    if not V(resolver_enable, true) or not part then return origin end
```


## Whitelisting Systems (Verified)

### Programmatic Whitelist Control
To programmatically whitelist players for the Ragebot (preventing targeting), you must interact with the specific UI object `ragebot_whitelist`.

**Key Requirements:**
1.  **UI ID**: `"ragebot_whitelist"`
2.  **Value Format**: Dictionary with *Username* keys: `{ ["Username"] = true }`
3.  **Read-Only Protection**: You must **Deep Copy** the existing table before modifying it, or you will receive an "attempt to modify a readonly table" error.

### Implementation Pattern

```lua
local function whitelistPlayer(player)
    local whitelist_obj = api:get_ui_object("ragebot_whitelist")
    if not whitelist_obj then return end

    -- 1. DEEP COPY existing value to bypass Read-Only protection
    local current_val = {}
    if whitelist_obj.Value then
        for k, v in pairs(whitelist_obj.Value) do
            current_val[k] = v
        end
    end

    -- 2. Add Player using USERNAME as key
    -- Note: Do not use "Display (@Name)" format.
    current_val[player.Name] = true

    -- 3. Set Value back to UI
    whitelist_obj:SetValue(current_val)
    
    -- 4. Update Options (Dropdown List) if necessary
    if whitelist_obj.Options or whitelist_obj.Values then
        local current_opts = {}
        -- Clone options...
        -- Add player.Name to options...
        if whitelist_obj.SetValues then whitelist_obj:SetValues(current_opts) end
    end
end
```


## Advanced Combat Patterns (Verified)

### Manual Resolver Logic
Instead of relying solely on the API's default resolver, you can implement custom tracking logic to handle desync and prediction more accurately.

**Key Mechanics:**
1.  **History Tracking**: Store the last N positions and timestamps of a target.
2.  **Velocity/Acceleration Calculation**: Manually calculate derivatives using DeltaTime (`dt`).
3.  **Desync Detection**: Compare `CurrentPosition` vs `PredictedPosition`. If the error exceeds a threshold, apply a correction offset.

```lua
-- Example: Manual Velocity Calculation
local function calculateVelocity(history)
    if #history < 2 then return Vector3.zero end
    local new, old = history[#history], history[1]
    local dt = new.time - old.time
    if dt < 0.001 then return Vector3.zero end
    return (new.pos - old.pos) / dt
end
```

### Geometric Strafing
Generate complex movement patterns (Orbit, Square, Triangle) using trigonometric offsets relative to the target.

```lua
-- Example: Orbit Pattern
local function getOrbitPosition(targetPos, radius, angle)
    local x = math.cos(angle) * radius
    local z = math.sin(angle) * radius
    return targetPos + Vector3.new(x, 0, z)
end
```

## Physics Manipulation Patterns (Verified)

### Network Ownership "Glue"
To force an object to stick to a player with perfect synchronization, you can manipulate hidden properties to tie their physics updates together.

**Method:**
```lua
-- "Glue" an object's physics root to a target part
pcall(function()
    sethiddenproperty(object, "PhysicsRepRootPart", target_hrp)
end)
```
*Note: This is an advanced logical exploit and may be patched or risky.*

### Projectile Teleportation (Grenade TP)
To convert a physics-based projectile (like a Grenade) into a guided missile:

1.  **Claim Ownership**: `sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)`
2.  **Strip Physics**: Destroy `BodyMover`s and `Constraint`s. Set `CanCollide` and `CanTouch` to false.
3.  **Fix Mass**: Set `CustomPhysicalProperties` to low density (e.g., 0.01) to prevent sluggishness.
4.  **Guide**: Use a `BodyPosition` with extremely high `P` (Power) and `D` (Damping) to snap it to the target.

### Accessory State Manipulation
For "fling" or "attaching" behavior, you can manipulate the internal state of accessories.

```lua
-- Reset/Desync Accessory State
sethiddenproperty(accessoryPart, "BackendAccoutrementState", 4) -- Force state
```
