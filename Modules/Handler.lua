local Handler = {}

-- Service Helper
function Service(name)
    return cloneref(game:GetService(name))
end

local Players = Service("Players")
local Workspace = Service("Workspace")
local RunService = Service("RunService")
local TweenService = Service("TweenService")
local TextChatService = Service("TextChatService")
local ContentProvider = Service("ContentProvider")
local LocalPlayer = Players.LocalPlayer

-- Character Part Getters
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

-- Status Checks
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

-- Crew Check
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

-- Tool Cache
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

-- Connection Manager
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

-- Player Search
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

-- Instance Creator
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

-- Asset Loading
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

-- Animation System
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

-- Sound System
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

-- Character Utilities
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

-- Shop Item Finder
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

-- Miscellaneous
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

return Handler
