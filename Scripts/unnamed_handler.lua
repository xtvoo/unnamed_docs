getgenv().Connections = {}

local function Service(Service: string)
	return cloneref(game:GetService(Service))
end

local Players = Service("Players")
local Workspace = Service("Workspace")
local ReplicatedStorage = Service("ReplicatedStorage")
local TweenService = Service("TweenService")
local TextChatService = Service("TextChatService")
local ContentProvider = Service("ContentProvider")
local RunService = Service("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Handler = {}
local Connections = getgenv().Connections
local Playing = nil

function Handler:CloneRef(Service: string): Instance
    return cloneref(game:GetService(Service))
end

function Handler:GetChar(Player: Model)
    return LocalPlayer.Character:FindFirstChild(Player.Name)
end

function Handler:Is_KO(Player: Model)
    if Player and Player.Character and Player.Character:FindFirstChild("BodyEffects") then
        if Player.Character.BodyEffects:FindFirstChild("K.O") then
            return Player.Character.BodyEffects["K.O"]
        end
    end
end

function Handler:Is_Dead(Player: Model)
    if Player and Player.Character and Player.Character:FindFirstChild("BodyEffects") then
        if Player.Character.BodyEffects:FindFirstChild("SDeath") then
            return Player.Character.BodyEffects["SDeath"]
        end
    end
end

function Handler:Is_Attacking(Player: Model)
    if Player and Player.Character and Player.Character:FindFirstChild("BodyEffects") then
        if Player.Character.BodyEffects:FindFirstChild("Attacking") then
            return Player.Character.BodyEffects["Attacking"]
        end
    end
end

function Handler:Humanoid(Player: Model)
    if Player and Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
        return Player.Character:FindFirstChildOfClass("Humanoid")
    end
end

function Handler:UpperTorso(Player: Model)
    if Player and Player.Character and Player.Character:FindFirstChild("UpperTorso") then
        return Player.Character.UpperTorso
    end
end

function Handler:HumanoidRootPart(Player: Model)
    if Player and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        return Player.Character.HumanoidRootPart
    end
end

function Handler:ForceField(Player: Model)
    if Player and Player.Character and Player.Character:FindFirstChild("ForceField") then
        return Player.Character.ForceField
    end
end

function Handler:Is_Crew(Player: Player, Target: Player): boolean
	if Player and Target then
		local PlayerData = Player:FindFirstChild("DataFolder")
		local TargetData = Target:FindFirstChild("DataFolder")
		if PlayerData and TargetData then
			local PlayerInfo = PlayerData:FindFirstChild("Information")
			local TargetInfo = TargetData:FindFirstChild("Information")
			if PlayerInfo and TargetInfo then
				local PlayerCrew = PlayerInfo:FindFirstChild("Crew")
				local TargetCrew = TargetInfo:FindFirstChild("Crew")
				if PlayerCrew and TargetCrew and PlayerCrew.Value ~= "" and TargetCrew.Value ~= "" and PlayerCrew.Value == TargetCrew.Value then
					return true
				end
			end
		end
	end
	return false
end

function Handler:Cache_Tool()
    local Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if Tool then
        local Handle = Tool:FindFirstChild("Handle")
        if Handle then
            local Offset = Vector3.new(0, 0, -Handle.Size.Z / 2)
            local Ammo = Tool:FindFirstChild("Ammo") and Tool.Ammo.Value or 0
            local MaxAmmo = Tool:FindFirstChild("MaxAmmo") and Tool.MaxAmmo.Value or 0
            local Gun = Tool:FindFirstChild("GunClient") ~= nil
            local Shotgun = Tool:FindFirstChild("GunClientShotgun") ~= nil
            local Automatic = Tool:FindFirstChild("GunClientAutomatic") ~= nil
            local Client = not (Gun or Shotgun or Automatic)

            return {
                Instance = Tool,
                Handle = Handle,
                Offset = Offset,
                Ammo = Ammo,
                MaxAmmo = MaxAmmo,
                Gun = Gun,
                Shotgun = Shotgun,
                Automatic = Automatic,
                Client = Client
            }
        end
    end
end

function Handler:ChangeState(Number: number)
    pcall(function()
        Handler:Humanoid(LocalPlayer):ChangeState(Number)
    end)
end

function Handler:GetAsset(Result: {[string]: string}): {[string]: Instance}
    local Results, Asset = {}, {}

    for Name, AssetID in pairs(Result) do
        local Assets = game:GetObjects(`rbxassetid://{AssetID}`)[1]
        Results[Name] = Assets:Clone()

        table.insert(Asset, Assets)

        for Index, Object in pairs(Assets:GetDescendants()) do
            table.insert(Asset, Object)
        end

        Assets.Parent = nil
		Assets:PivotTo(CFrame.new(1e6, 1e6, 1e6))
		Assets.Parent = workspace
		RunService.RenderStepped:Wait()
		Assets.Parent = nil
    end

    ContentProvider:PreloadAsync(Asset)

    return Results
end

function Handler:Get_Asset_By_Folder(Folder: string, Result: {[string]: string})
    local Results, Asset = {}, {}

    for Name, AssetID in pairs(Result) do
        local Assets = game:GetObjects(getcustomasset(`{Folder}/{AssetID}`))[1]
        Results[AssetID:match("^(.-)%.rbxm$"):gsub(" ", "_")] = Assets:Clone()

        table.insert(Asset, Assets)

        for self, Object in pairs(Assets:GetDescendants()) do
            if Object:IsA("ParticleEmitter") or Object:IsA("Trail") or Object:IsA("Beam") or Object:IsA("Fire") or Object:IsA("Smoke") or Object:IsA("Sparkles") or Object:IsA("PointLight") or Object:IsA("SurfaceLight") or Object:IsA("SpotLight") then
                Object.Enabled = true
            end
            table.insert(Asset, Object)
        end

        Assets.Parent = nil
        Assets:PivotTo(CFrame.new(1e6, 1e6, 1e6))
        Assets.Parent = workspace
        RunService.RenderStepped:Wait()
        Assets.Parent = nil
    end

    ContentProvider:PreloadAsync(Asset)
    return Results
end

function Handler:Get_Player(Text: string): Player?
	for Index, Player in pairs(Players:GetPlayers()) do
		if Player and Player ~= LocalPlayer and (Player.Name:lower():sub(1, #Text) == Text:lower() or Player.DisplayName:lower():sub(1, #Text) == Text:lower()) then
			return Player
		end
	end
	return nil
end

function Handler:Get_Mouse_Player(): Player?
    local Player, Shortest = nil, math.huge
    local Players = Players:GetPlayers()

    for Index = 1, #Players do
        local Target = Players[Index]
        if Target ~= LocalPlayer and (Target.Character and Target.Character:FindFirstChild("Head") and Target.Character:FindFirstChild("Humanoid") and Target.Character.Humanoid.Health > 0) then
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

function Handler:Connected(Name: string)
	if typeof(Connections[Name]) == "RBXScriptConnection" then
		return Connections[Name].Connected
	elseif typeof(Connections[Name]) == "table" then
		for Index = 1, #Connections[Name] do
			if typeof(Connections[Name][Index]) == "RBXScriptConnection" and Connections[Name][Index].Connected then
				return true
			end
		end
		return false
	end
end

function Handler:Disconnect(Name: string | {string}, Nil: boolean)
	if typeof(Name) == "table" then
		for Index = 1, #Name do
			self:Disconnect(Name[Index], Nil)
		end
		return
	end

	if typeof(Connections[Name]) == "RBXScriptConnection" then
		if Connections[Name].Connected then
			Connections[Name]:Disconnect()
		end
	elseif typeof(Connections[Name]) == "table" then
		for Index = 1, #Connections[Name] do
			if typeof(Connections[Name][Index]) == "RBXScriptConnection" and Connections[Name][Index].Connected then
				Connections[Name][Index]:Disconnect()
			end
		end
	end

	if Nil then
		Connections[Name] = nil
	end
end

function Handler:AddConnection(Name: string | table, Connection: RBXScriptConnection?)
    if typeof(Connection) ~= "RBXScriptConnection" then 
        return 
    end
    
	if typeof(Name) == "string" then
		if typeof(Connections[Name]) == "RBXScriptConnection" and Connections[Name].Connected then
			Connections[Name]:Disconnect()
		end
		Connections[Name] = Connection
	elseif typeof(Name) == "table" then
		for Index = 1, #Name do
			if typeof(Name[Index]) == "RBXScriptConnection" and Name[Index].Connected then
				Name[Index]:Disconnect()
			end
		end
		table.insert(Name, Connection)
	end
end

function Handler:Unload()
    if not Connections or next(Connections) == nil then
        return
    end

    for Name, Connection in pairs(Connections) do
        if typeof(Connection) == "RBXScriptConnection" and Connection.Connected then
            Connection:Disconnect()
        end
    end

    table.clear(Connections)
end

function Handler:Create(Type: string, Properties: { [string]: any }): Instance
    if Properties.Name and (Properties.Parent or Workspace):FindFirstChild(Properties.Name) then
    	(Properties.Parent or Workspace):FindFirstChild(Properties.Name):Destroy()
    end

    local NewInstance = Instance.new(Type)

    for Index, Property in pairs(Properties) do
        NewInstance[Index] = Property
    end

    return NewInstance
end

function Handler:Find_Item(Name: string, Type: boolean)
	for Index, Shop in pairs(Workspace.Ignored.Shop:GetChildren()) do
		local Lower = Shop.Name:lower()
		if Type and Lower:find("ammo") and Lower:find(Name:lower()) and Shop:FindFirstChild("Head") then
			return Shop
		elseif not Type and not Lower:find("ammo") and Lower:find(Name:lower()) and Shop:FindFirstChild("Head") then
			return Shop
		end
	end
end

function Handler:Destroy(Name: Instance)
	if Name then
		Name:Destroy()
	end
end

function Handler:RemoveAccessory(Character: Model, Accessory: Accessory)
    for Name, Item in pairs(Character:GetChildren()) do
        if Item:IsA(Accessory) then
            Item:Destroy()
        end
    end
end

function Handler:Equip(Tool: string)
    if LocalPlayer.Backpack:FindFirstChild(Tool) and not LocalPlayer.Character:FindFirstChild(Tool) then
        LocalPlayer.Backpack:FindFirstChild(Tool).Parent = LocalPlayer.Character
    end
end

function Handler:PlaySound(ID: number, Vol: number)
    local Sound = Handler:Create("Sound", {
        SoundId = "rbxassetid://" .. ID,
        Volume = Vol,
        Parent = workspace
    })

    Sound:Play()

    Sound.Ended:Connect(function()
        Sound:Destroy()
    end)

    return Sound
end

function Handler:StopSound(Sound: any)
    if Sound and Sound.IsPlaying then
        Sound:Stop()
        Sound:Destroy()
    end
end

function Handler:Noclip(Character: Model)
    for Index, Part in pairs(Character:GetChildren()) do
        if (Part:IsA("Part") or Part:IsA("BasePart") or Part:IsA("MeshPart")) and Part.CanCollide then
            Part.CanCollide = false
        end
    end
end

function Handler:ZeroVelocity(Character: Model)
	for Index, Part in pairs(Character:GetChildren()) do
		if Part:IsA("BasePart") or Part:IsA("MeshPart") or Part:IsA("Part") then
			if Part.Velocity ~= Vector3.zero or Part.AssemblyLinearVelocity ~= Vector3.zero or Part.AssemblyAngularVelocity ~= Vector3.zero then
				Part.Velocity = Vector3.zero
				Part.AssemblyLinearVelocity = Vector3.zero
				Part.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end
end

function Handler:ZeroVelocityCharacter(Character: Model)
	if Character.Velocity ~= Vector3.zero or Character.AssemblyAngularVelocity ~= Vector3.zero or Character.AssemblyLinearVelocity ~= Vector3.zero then
		Character.Velocity = Vector3.zero
		Character.AssemblyAngularVelocity = Vector3.zero
		Character.AssemblyLinearVelocity = Vector3.zero
	end
end

function Handler:Stop(Character: Model)
    for Index, Track in pairs(Handler:Humanoid(Character):GetPlayingAnimationTracks()) do
        Track:Stop()
    end
end

function Handler:AnimPlay(ID: string, Speed: number?, Time: number?, Smoothing: number?)
	if not Handler:Humanoid(LocalPlayer) or not Handler:Humanoid(LocalPlayer).Parent then
		return
	end
    
	for Index, Tracks in pairs(Handler:Humanoid(LocalPlayer):GetPlayingAnimationTracks()) do
		if Tracks.Animation and Tracks.Animation.AnimationId:match("rbxassetid://" .. ID) then
			Tracks:Stop()
		end
	end

	local Animation = Instance.new("Animation", workspace)
	Animation.AnimationId = "rbxassetid://" .. ID
	Playing = Handler:Humanoid(LocalPlayer):LoadAnimation(Animation)
	Playing.Priority = 4

	Playing:Play(tonumber(Smoothing) or nil)

	Playing:AdjustSpeed(tonumber(Speed) or 1)

	if tonumber(Time) then
		Playing.TimePosition = Time
	end

	Animation:Destroy()
end

function Handler:AnimStop(ID: string, Speed: number?)
	if not Handler:Humanoid(LocalPlayer) or not Handler:Humanoid(LocalPlayer).Parent then
		return
	end

	for Index, Track in pairs(Handler:Humanoid(LocalPlayer):GetPlayingAnimationTracks()) do
		if Track.Animation and Track.Animation.AnimationId:match("rbxassetid://" .. ID) then
            Track:Stop(Speed or nil)
		end
	end
end

function Handler:IsAnimPlaying(ID: string): boolean
	if not Handler:Humanoid(LocalPlayer) or not Handler:Humanoid(LocalPlayer).Parent then
		return
	end
	
	for Index, Track in pairs(Handler:Humanoid(LocalPlayer):GetPlayingAnimationTracks()) do
		if Track.Animation and Track.Animation.AnimationId:match("rbxassetid://" .. ID) and Track.IsPlaying then
			return true
		end
	end
	return false
end

function Handler:Tween(Part: Instance, Duration: number, Properties: { [string]: any }): void
    TweenService:Create(Part, TweenInfo.new(Duration), Properties):Play()
end

function Handler:Chat(Message: any)
    TextChatService.TextChannels.RBXGeneral:SendAsync(Message)
end

function Handler:HttpGet(Url: string | {string}): any
	if typeof(Url) == "table" then
		local Results = {}
		for Index = 1, #Url do
			local Success, Result = pcall(function()
				return loadstring(game:HttpGet(Url[Index]))
			end)

			if Success and typeof(Result) == "function" then
				Results[Index] = Result()
			else
				warn("HttpGet failed at Index " .. Index, Result)
			end
		end
		return table.unpack(Results)
	end

	local Success, Result = pcall(function()
		return loadstring(game:HttpGet(Url))
	end)

	if Success and typeof(Result) == "function" then
		return Result()
	end

	return nil
end

function Handler:SendWebhook(Url: string, Data: table)
	spawn(function()
		(http_request or request or (http and http.request) or (syn and syn.request))({
			Url = Url,
			Method = "POST",
			Headers = { ["content-type"] = "application/json" },
			Body = game:GetService("HttpService"):JSONEncode(Data),
		})
	end)
end

function Handler:Is_Reloading()
    local BodyEffects = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("BodyEffects")
    local Reloading = BodyEffects and BodyEffects:FindFirstChild("Reload")
    return Reloading and Reloading.Value or false
end

function Handler:GetClosestPlayerToCharacter(MaxDistance: number): (Player, number)
    local ClosestPlayer, ShortestDistance = nil, MaxDistance or math.huge

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            local Distance = (LocalPlayer.Character.HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).Magnitude
            if Distance < ShortestDistance then
                ClosestPlayer = Player
                ShortestDistance = Distance
            end
        end
    end

    return ClosestPlayer, ShortestDistance
end

function Handler:GetOrigin(Player: Player): Vector3
    if Player and Player.Character then
        if Player.Character:FindFirstChild("HumanoidRootPart") then
            return Player.Character.HumanoidRootPart.Position
        elseif Player.Character:FindFirstChild("Torso") then
            return Player.Character.Torso.Position
        end
    end
    return Vector3.zero
end

function Handler:IsVisible(Target: Instance, Origin: Vector3?, Ignore: {Instance}?): boolean
    local StartPosition = Origin or Camera.CFrame.Position
    local EndPosition = Target.Position
    local Direction = EndPosition - StartPosition
    
    local RaycastParams = RaycastParams.new()
    RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera, table.unpack(Ignore or {})}
    RaycastParams.IgnoreWater = true

    local Result = Workspace:Raycast(StartPosition, Direction, RaycastParams)

    if Result then
        if Result.Instance:IsDescendantOf(Target.Parent) then
            return true
        end
        return false
    else
        return true -- No obstruction found, so it is visible
    end
end

function Handler:WTS(Position: Vector3): (Vector2, boolean)
    local Vector, OnScreen = Camera:WorldToViewportPoint(Position)
    return Vector2.new(Vector.X, Vector.Y), OnScreen
end

function Handler:ServerHop()
    local Servers = {}
    local Request = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    local Data = game:GetService("HttpService"):JSONDecode(Request)

    if Data.data then
        for _, Server in pairs(Data.data) do
            if Server.playing < Server.maxPlayers and Server.id ~= game.JobId then
                table.insert(Servers, Server.id)
            end
        end
    end

    if #Servers > 0 then
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, Servers[math.random(1, #Servers)], LocalPlayer)
    else
        api:notify("No compatible servers found.", 3)
    end
end

function Handler:Rejoin()
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\nRejoining...")
        task.wait()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    else
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end

return Handler
