local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemConfig = require(ReplicatedStorage.Shared.ItemConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)
local PlayerService = require(script.Parent.PlayerService)
local InventoryRules = require(script.Parent.InventoryRules)
local InventoryService = {}
local lastUse = {}

function InventoryService.use(player, itemId)
    if itemId ~= "tonic" then return end
    local now = os.clock()
    if lastUse[player] and now - lastUse[player] < 0.5 then return end
    lastUse[player] = now
    local data = PlayerDataService.get(player)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not data or not humanoid then return end
    local ok, result = InventoryRules.consumeTonic(data, humanoid.Health, humanoid.MaxHealth, ItemConfig.tonic.heal)
    if ok then
        humanoid.Health = result
        PlayerService.send(player, "Eldoria Tonic digunakan.")
    else
        PlayerService.send(player, result)
    end
end
function InventoryService.remove(player) lastUse[player] = nil end
return InventoryService
