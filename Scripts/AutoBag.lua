-- Auto Bag Script
local LocalPlayer = game:GetService("Players").LocalPlayer
local workspace = game:GetService("Workspace")

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

local function get_bag_tool()
    local bag, parent = find_bag_anywhere()
    if not bag then return nil end
    
    -- Equip if not already equipped
    if parent ~= LocalPlayer.Character then
        bag.Parent = LocalPlayer.Character
    end
    return bag
end

local function is_target_bagged(target)
    local model_folder = workspace.Players.Model
    local char_folder = model_folder:FindFirstChild(target.Name)
    return char_folder and char_folder:FindFirstChild("Christmas_Sock") ~= nil
end

local function enter_void()
    local void_in = api:get_ui_object("character_prot_void_in")
    if void_in then void_in:SetValue(true) end
end

local function exit_void()
    local void_out = api:get_ui_object("character_prot_void_out")
    if void_out then void_out:SetValue(true) end
end

-- Main Loop
task.spawn(function()
    while true do
        task.wait(1)
        
        -- Auto Buy Bag if we don't have one and can desync
        local bag = find_bag_anywhere()
        if not bag and api:can_desync() then
            api:buy_item("brownbag")
        end
        
        -- Logic to bag target could go here
        -- Use logic from target selection
    end
end)

api:notify("Auto Bag logic loaded", 3)
