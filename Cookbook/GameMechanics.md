# Game Mechanics Cookbook

## Auto Kill/Stomp State Machine

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

## 3D Strafe Patterns

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

## Projectile Manipulation

### Desync Callback for Remote Grab
Use desync callback to grab items from a distance.
```lua
api:add_desync_callback(2, function()
    if isGrabbing then
        return snowballLocation -- CFrame to teleport server-side
    end
    return nil
end)
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
```

## Glue System

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
