# Ragebot & Prediction Cookbook

## Advanced Ragebot Mechanics

### Strafe Override System
Override the default ragebot strafing behavior with custom patterns.
```lua
api:ragebot_strafe_override(function(position, unsafe, part)
    if unsafe or not position then return end
    local angle = tick() * Speed
    local offset = Vector3.new(math.cos(angle) * Radius, 0, math.sin(angle) * Radius)
    return CFrame.new(position + offset, position) -- orbit around target
end)
```

### Velocity Prediction
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

### Acceleration Tracking
Track rate of velocity change for more accurate prediction on accelerating targets.
```lua
local function calculateAcceleration(history)
    if #history < 3 then return Vector3.zero end
    local v1 = (history[2].pos - history[1].pos) / (history[2].time - history[1].time)
    local v2 = (history[3].pos - history[2].pos) / (history[3].time - history[2].time)
    return (v2 - v1) / (history[3].time - history[1].time)
end
```

### Resolver Modes
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

### Desync Detection
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

### Spline Prediction (Catmull-Rom)
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

### Aim Detection
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

### MousePos Replication
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

### Hit/Miss Adaptive Multiplier
Adjust prediction strength based on whether shots are landing.
```lua
api:on_event("localplayer_hit_player", function(player, part, damage)
    hitCount = hitCount + 1
    missCount = math.max(0, missCount - 1)
    local ratio = hitCount / math.max(1, hitCount + missCount)
    multiplier = lerp(multiplier, 0.8 + ratio * 0.4, 0.2) -- 0.8 to 1.2 range
end)
```
