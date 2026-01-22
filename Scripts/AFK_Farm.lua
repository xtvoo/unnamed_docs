-- AFK Farm Script
local LocalPlayer = game:GetService("Players").LocalPlayer
local plotName = "LandStore" -- Default plot, change as needed

local isFarming = true
local farmSpeed = 0.1

local function getTargetPart()
    local plots = workspace.Main.Plots
    local plot = plots:FindFirstChild(plotName)
    return plot and plot:FindFirstChild("AFKPart")
end

api:notify("AFK Farm Started", 3)

task.spawn(function()
    while isFarming do
        local part = getTargetPart()
        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if part and rootPart then
            firetouchinterest(part, rootPart, 0)  -- Touch
            task.wait()
            firetouchinterest(part, rootPart, 1)  -- Untouch
        end
        task.wait(farmSpeed)
    end
end)
