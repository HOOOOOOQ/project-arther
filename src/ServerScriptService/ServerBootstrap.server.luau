local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataService = require(script.Parent.Services.PlayerDataService)
local PlayerService = require(script.Parent.Services.PlayerService)
local WorldService = require(script.Parent.Services.WorldService)
local InventoryService = require(script.Parent.Services.InventoryService)

local remotes = Instance.new("Folder"); remotes.Name = "AetherRemotes"; remotes.Parent = ReplicatedStorage
local state = Instance.new("RemoteEvent"); state.Name = "State"; state.Parent = remotes
local request = Instance.new("RemoteEvent"); request.Name = "RequestState"; request.Parent = remotes
local useItem = Instance.new("RemoteEvent"); useItem.Name = "UseItem"; useItem.Parent = remotes
PlayerService.init(state)
WorldService.build()

local requestTimes = {}
request.OnServerEvent:Connect(function(player, ...)
    if select("#", ...) ~= 0 then return end
    local now = os.clock()
    if requestTimes[player] and now - requestTimes[player] < 1 then return end
    requestTimes[player] = now
    PlayerService.send(player)
end)

useItem.OnServerEvent:Connect(function(player, ...)
    if select("#", ...) ~= 1 then return end
    local itemId = ...
    if type(itemId) ~= "string" or #itemId > 32 then return end
    InventoryService.use(player, itemId)
end)

local loading = {}
-- A removal may arrive before a scheduled onPlayer task starts, while Parent
-- is still set. Weak keys avoid retaining departed Player instances.
local departing = setmetatable({}, { __mode = "k" })
local inFlightLoads = 0
local shuttingDown = false
local function onPlayer(player)
    if loading[player] or departing[player] or shuttingDown or not player.Parent then return end
    local lifecycle = { cancelled = false }
    loading[player] = lifecycle
    player.CharacterAdded:Connect(function(character) PlayerService.characterAdded(player, character) end)
    inFlightLoads += 1
    local ok, data, err = pcall(PlayerDataService.load, player, function()
        return lifecycle.cancelled or shuttingDown
    end)
    inFlightLoads -= 1
    if not ok then
        err = data; data = nil
        PlayerDataService.release(player)
    end
    if not data then
        if not lifecycle.cancelled and not shuttingDown then
            warn("[Aether Data] load failed for " .. player.UserId .. ": " .. tostring(err))
            if player.Parent then player:Kick("Data tidak dapat dimuat dengan aman. Silakan masuk kembali.") end
        end
        if loading[player] == lifecycle then loading[player] = nil end
        return
    end
    if lifecycle.cancelled or shuttingDown then
        PlayerDataService.release(player)
        return
    end
    if player.Character then PlayerService.characterAdded(player, player.Character) end
    if player.Parent and not lifecycle.cancelled and not shuttingDown then PlayerService.send(player) end
end
Players.PlayerAdded:Connect(function(player) task.spawn(onPlayer, player) end)
Players.PlayerRemoving:Connect(function(player)
    departing[player] = true
    local lifecycle = loading[player]
    if lifecycle then lifecycle.cancelled = true end
    requestTimes[player] = nil
    InventoryService.remove(player)
    PlayerDataService.release(player)
    if loading[player] == lifecycle then loading[player] = nil end
end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, player) end

task.spawn(function()
    while true do
        task.wait(60)
        for _, player in ipairs(PlayerDataService.players()) do task.spawn(PlayerDataService.save, player) end
    end
end)

game:BindToClose(function()
    shuttingDown = true
    for _, lifecycle in pairs(loading) do lifecycle.cancelled = true end
    local deadline = os.clock() + 25
    -- A load may acquire a lease after shutdown starts. Let its cancellation
    -- path release it before taking the final session snapshot.
    while inFlightLoads > 0 and os.clock() < deadline do task.wait(0.1) end
    local pending = 0
    for _, player in ipairs(PlayerDataService.players()) do
        pending += 1
        task.spawn(function()
            PlayerDataService.release(player)
            pending -= 1
        end)
    end
    while pending > 0 and os.clock() < deadline do task.wait(0.1) end
    if pending > 0 or inFlightLoads > 0 then
        warn("[Aether Data] shutdown deadline reached with pending loads or saves")
    end
end)
