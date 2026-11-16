local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local PlayerService = require(script.Parent.PlayerService)
local WorldService = {}

local function part(parent, name, size, position, color, material)
    local p = Instance.new("Part")
    p.Name = name; p.Size = size; p.Position = position; p.Color = color
    p.Material = material or Enum.Material.WoodPlanks; p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function tree(parent, x, z, scale)
    part(parent, "Trunk", Vector3.new(2, 12, 2) * scale, Vector3.new(x, 6 * scale + 1, z), Color3.fromRGB(80, 59, 43), Enum.Material.Wood)
    local foliage = part(parent, "Canopy", Vector3.new(11, 11, 11) * scale, Vector3.new(x, 14 * scale + 1, z), Color3.fromRGB(67, 99, 61), Enum.Material.Grass)
    foliage.Shape = Enum.PartType.Ball
    foliage.CanCollide = false
end

local function house(parent, name, x, z, color)
    local model = Instance.new("Model"); model.Name = name; model.Parent = parent
    -- Open-front interiors keep the prototype buildings navigable.
    part(model, "Floor", Vector3.new(20, 1, 16), Vector3.new(x, 1, z), Color3.fromRGB(106, 84, 65), Enum.Material.WoodPlanks)
    part(model, "Back", Vector3.new(20, 10, 1), Vector3.new(x, 6, z - 7.5), color, Enum.Material.Brick)
    part(model, "Left", Vector3.new(1, 10, 16), Vector3.new(x - 9.5, 6, z), color, Enum.Material.Brick)
    part(model, "Right", Vector3.new(1, 10, 16), Vector3.new(x + 9.5, 6, z), color, Enum.Material.Brick)
    local roofColor = Color3.fromRGB(74, 48, 43)
    for _, side in ipairs({-1, 1}) do
        local roof = part(model, "RoofSlope", Vector3.new(12, 1, 18), Vector3.new(x + side * 5.2, 13.4, z), roofColor, Enum.Material.Slate)
        roof.CFrame = CFrame.new(roof.Position) * CFrame.Angles(0, 0, math.rad(-side * 25))
    end
    for _, offset in ipairs({-8.5, 8.5}) do
        part(model, "Timber", Vector3.new(1, 10, 1), Vector3.new(x + offset, 6, z + 7.5), Color3.fromRGB(74, 53, 40), Enum.Material.Wood)
    end
    part(model, "Counter", Vector3.new(8, 3, 2), Vector3.new(x, 2.5, z - 4), Color3.fromRGB(91, 62, 42))
end

local function sign(parent, title, position)
    local post = part(parent, title .. "Post", Vector3.new(1, 6, 1), position + Vector3.new(0, 3, 0), Color3.fromRGB(86, 61, 42), Enum.Material.Wood)
    local face = part(parent, title .. "Sign", Vector3.new(8, 3, 0.5), position + Vector3.new(0, 6, 0), Color3.fromRGB(71, 54, 43), Enum.Material.WoodPlanks)
    local surface = Instance.new("SurfaceGui"); surface.Face = Enum.NormalId.Front; surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; surface.PixelsPerStud = 35; surface.Parent = face
    local text = Instance.new("TextLabel"); text.Size = UDim2.fromScale(1,1); text.BackgroundTransparency = 1; text.Text = title
    text.TextColor3 = Color3.fromRGB(233, 218, 182); text.Font = Enum.Font.GothamBold; text.TextScaled = true; text.Parent = surface
    return post
end

local function marketStall(parent, name, x, z, cloth)
    local model = Instance.new("Model"); model.Name = name; model.Parent = parent
    part(model, "Counter", Vector3.new(12, 3, 5), Vector3.new(x, 2.5, z), Color3.fromRGB(105, 73, 49))
    for _, dx in ipairs({-5.5,5.5}) do
        part(model, "Pole", Vector3.new(0.8, 8, 0.8), Vector3.new(x+dx, 5, z), Color3.fromRGB(83, 58, 42), Enum.Material.Wood)
    end
    local canopy = part(model, "Awning", Vector3.new(14, 0.6, 7), Vector3.new(x, 9, z), cloth, Enum.Material.Fabric)
    canopy.CFrame = CFrame.new(canopy.Position) * CFrame.Angles(math.rad(8), 0, 0)
    part(model, "Crate", Vector3.new(3, 3, 3), Vector3.new(x + 7, 2.5, z + 2), Color3.fromRGB(110, 79, 49))
end

local function lamp(parent, x, z)
    part(parent, "LampPost", Vector3.new(0.8, 8, 0.8), Vector3.new(x, 5, z), Color3.fromRGB(65, 55, 44), Enum.Material.Wood)
    local lantern = part(parent, "Lantern", Vector3.new(1.5, 2, 1.5), Vector3.new(x, 9.5, z), Color3.fromRGB(244, 201, 117), Enum.Material.Glass)
    lantern.CanCollide = false
    local light = Instance.new("PointLight"); light.Color = Color3.fromRGB(255, 205, 133); light.Range = 18; light.Brightness = 0.8; light.Parent = lantern
end

function WorldService.build()
    -- This generated village is a small playable greybox, not a finished environment.
    local existing = Workspace:FindFirstChild("AetherWorld")
    if existing then error("Workspace.AetherWorld already exists; refusing to replace it") end
    local world = Instance.new("Folder"); world.Name = "AetherWorld"; world.Parent = Workspace
    local village = Instance.new("Folder"); village.Name = "EldoriaVillage"; village.Parent = world
    local terrain = Workspace.Terrain
    terrain:FillBlock(CFrame.new(0, -10, 0), Vector3.new(512, 20, 512), Enum.Material.Grass)
    terrain:FillBlock(CFrame.new(0, 0, 0), Vector3.new(512, 2, 512), Enum.Material.Grass)
    terrain:FillBlock(CFrame.new(0, -3, -82), Vector3.new(512, 12, 18), Enum.Material.Water)
    part(village, "Plaza", Vector3.new(65, 1, 65), Vector3.new(0, 1, 0), Color3.fromRGB(115, 113, 101), Enum.Material.Cobblestone)
    part(village, "NorthRoad", Vector3.new(12, 1, 100), Vector3.new(0, 1, -55), Color3.fromRGB(119, 112, 97), Enum.Material.Cobblestone)
    part(village, "Bridge", Vector3.new(16, 2, 28), Vector3.new(0, 3, -82), Color3.fromRGB(103, 73, 50), Enum.Material.WoodPlanks)
    for _, side in ipairs({-1,1}) do
        part(village, "BridgeRail", Vector3.new(0.7, 1, 28), Vector3.new(side * 7.7, 5.3, -82), Color3.fromRGB(78, 56, 42), Enum.Material.Wood)
        local ramp = part(village, "BridgeRamp", Vector3.new(16, 0.8, 8.5), Vector3.new(0, 2.65, -82 + side * 18), Color3.fromRGB(103,73,50))
        ramp.CFrame = CFrame.new(ramp.Position) * CFrame.Angles(math.rad(side * 18), 0, 0)
    end
    part(village, "EastRoad", Vector3.new(9, 0.5, 130), Vector3.new(72, 1.3, -52), Color3.fromRGB(119,112,97), Enum.Material.Cobblestone)
    part(village, "EastBridge", Vector3.new(12, 2, 28), Vector3.new(72, 3, -82), Color3.fromRGB(103,73,50), Enum.Material.WoodPlanks)
    for _, side in ipairs({-1,1}) do
        part(village, "EastBridgeRail", Vector3.new(0.7,1,28), Vector3.new(72 + side * 5.7,5.3,-82), Color3.fromRGB(78,56,42), Enum.Material.Wood)
        local ramp = part(village, "EastBridgeRamp", Vector3.new(12,0.8,8.5), Vector3.new(72,2.65,-82 + side * 18), Color3.fromRGB(103,73,50))
        ramp.CFrame = CFrame.new(ramp.Position) * CFrame.Angles(math.rad(side * 18),0,0)
    end
    part(village, "MarketRoad", Vector3.new(80, 0.5, 8), Vector3.new(0, 1.3, 40), Color3.fromRGB(119,112,97), Enum.Material.Cobblestone)
    part(village, "ForestRoad", Vector3.new(10, 0.5, 100), Vector3.new(0, 1.3, -155), Color3.fromRGB(109,103,87), Enum.Material.Ground)
    house(village, "Inn", -46, 12, Color3.fromRGB(165, 143, 114))
    house(village, "Smithy", 46, 12, Color3.fromRGB(136, 128, 113))
    house(village, "Cottage", -46, -35, Color3.fromRGB(167, 150, 126))
    house(village, "Store", 46, -35, Color3.fromRGB(154, 137, 115))
    for _, coords in ipairs({{-100,-110}, {-75,-115}, {50,-125}, {95,-105}, {-110,20}, {105,20}, {-85,65}, {90,70}, {-35,-130}, {20,-145}, {120,-160}, {-150,-150}}) do
        tree(village, coords[1], coords[2], 1)
    end
    -- Distant low terrain forms a forest edge without blocking village routes.
    for _, hill in ipairs({{-190,-180,22}, {180,-175,24}, {-200,145,25}, {185,140,20}}) do
        terrain:FillBall(Vector3.new(hill[1], -6, hill[2]), hill[3], Enum.Material.Grass)
    end
    local forest = Instance.new("Folder"); forest.Name = "ForestEntrance"; forest.Parent = world
    for _, coords in ipairs({{-35,-185}, {-55,-200}, {-85,-200}, {-115,-185}, {35,-185}, {55,-200}, {85,-200}, {115,-185}, {-30,-220}, {30,-225}, {95,-230}, {-110,-235}}) do
        tree(forest, coords[1], coords[2], 1.15)
    end
    sign(forest, "WHISPERING FOREST", Vector3.new(12, 1, -170))
    local market = Instance.new("Folder"); market.Name = "Market"; market.Parent = village
    marketStall(market, "ProvisionStall", -20, 48, Color3.fromRGB(133,83,72))
    marketStall(market, "GoodsStall", 20, 48, Color3.fromRGB(92,112,103))
    sign(market, "MARKET", Vector3.new(0, 1, 53))
    -- Markers are locations for future NPCs, not interactive NPCs or functioning shops.
    sign(village, "INN", Vector3.new(-45, 1, 25))
    sign(village, "SMITHY", Vector3.new(45, 1, 25))
    local training = Instance.new("Folder"); training.Name = "TrainingGround"; training.Parent = village
    part(training, "Ground", Vector3.new(35,0.5,28), Vector3.new(90,1.2,18), Color3.fromRGB(119,98,77), Enum.Material.Ground)
    for _, x in ipairs({82, 90, 98}) do
        part(training, "TrainingPost", Vector3.new(1.5,7,1.5), Vector3.new(x,4.5,10), Color3.fromRGB(105,75,53), Enum.Material.Wood)
        part(training, "Crossbar", Vector3.new(5,1,1), Vector3.new(x,6,10), Color3.fromRGB(105,75,53), Enum.Material.Wood)
    end
    sign(training, "TRAINING", Vector3.new(90,1,35))
    for _, coords in ipairs({{-28,28}, {28,28}, {-10,-38}, {10,-38}, {-9,-105}, {9,-105}}) do lamp(village, coords[1], coords[2]) end
    local well = part(village, "Well", Vector3.new(8, 3, 8), Vector3.new(-20,2.5,5), Color3.fromRGB(125,123,111), Enum.Material.Cobblestone)
    local wellWater = part(village, "WellWater", Vector3.new(6,0.2,6), Vector3.new(-20,4.1,5), Color3.fromRGB(76,122,133), Enum.Material.Glass); wellWater.CanCollide = false
    local spawn = Instance.new("SpawnLocation"); spawn.Name = "VillageSpawn"; spawn.Size = Vector3.new(8, 1, 8)
    spawn.Position = Vector3.new(0, 2, 18); spawn.Anchored = true; spawn.Transparency = 1; spawn.Neutral = true; spawn.Parent = village
    local board = part(village, "AdventurerBoard", Vector3.new(7, 6, 1), Vector3.new(0, 4.5, -22), Color3.fromRGB(87, 59, 40))
    local prompt = Instance.new("ProximityPrompt"); prompt.ActionText = "Latihan petualang"; prompt.ObjectText = string.format("Papan Eldoria • +%d EXP / +%d gold", Config.TrainingRewardXP, Config.TrainingRewardGold)
    prompt.HoldDuration = 1; prompt.MaxActivationDistance = 10; prompt.Parent = board
    local cooldowns = {}
    prompt.Triggered:Connect(function(player)
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 or (root.Position - board.Position).Magnitude > Config.MaxInteractionDistance then return end
        local now = os.clock()
        if cooldowns[player] and now - cooldowns[player] < Config.TrainingCooldown then
            PlayerService.send(player, "Latihan belum siap. Tunggu sebentar.")
            return
        end
        if PlayerService.rewardTraining(player) then cooldowns[player] = now end
    end)
    game:GetService("Players").PlayerRemoving:Connect(function(player) cooldowns[player] = nil end)
    Lighting.ClockTime = 15; Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(90, 90, 100); Lighting.OutdoorAmbient = Color3.fromRGB(128, 127, 120)
    local atmosphere = Instance.new("Atmosphere"); atmosphere.Name = "AetherAtmosphere"; atmosphere.Density = 0.3
    atmosphere.Color = Color3.fromRGB(205, 216, 217); atmosphere.Decay = Color3.fromRGB(109, 125, 135); atmosphere.Parent = Lighting
end
return WorldService
