# Visuals & ESP Cookbook

## Drawing-Based ESP System

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
end
```

### 3D Shape Rendering
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

## China Hat V2

### Adaptive LOD
Dynamically adjust polygon sides based on distance.
```lua
local dist = (Camera.CFrame.Position - head.Position).Magnitude
local renderSides = Sides.Value
if dist > 100 then renderSides = math.floor(renderSides / 2) end
if dist > 300 then renderSides = 4 end
local drawings = GetDrawings(plr, renderSides)
```

## Math VFX System

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
