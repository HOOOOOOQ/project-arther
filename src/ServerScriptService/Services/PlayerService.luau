local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Progression = require(ReplicatedStorage.Shared.Progression)
local PlayerDataService = require(script.Parent.PlayerDataService)
local PlayerService = {}
local stateEvent

local function applyCharacter(player, data)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local stats = Progression.stats(data.level)
        local previousMax = humanoid.MaxHealth
        humanoid.MaxHealth = stats.maxHealth
        humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + math.max(0, humanoid.MaxHealth - previousMax))
        humanoid.WalkSpeed = Config.BaseWalkSpeed
        -- Mana is session-only for now; no skill currently consumes it.
        player:SetAttribute("AetherMaxMana", stats.maxMana)
        player:SetAttribute("AetherMana", stats.maxMana)
    end
end

function PlayerService.init(event)
    stateEvent = event
end

function PlayerService.send(player, message)
    if not player.Parent then return end
    local data = PlayerDataService.get(player)
    if not data then return end
    local stats = Progression.stats(data.level)
    stateEvent:FireClient(player, {
        level = data.level, xp = data.xp, xpRequired = Progression.requiredXP(data.level),
        gold = data.gold, class = data.class, stats = stats, maxLevel = Config.MaxLevel,
        inventory = { tonic = data.inventory.tonic }, trainingSessions = data.trainingSessions,
    }, message)
end

function PlayerService.characterAdded(player, character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid and player.Character == character then
        local data = PlayerDataService.get(player)
        if data then applyCharacter(player, data) end
    end
end

function PlayerService.rewardTraining(player)
    local data = PlayerDataService.get(player)
    if not data then return false end
    data.gold = math.min(1000000000, data.gold + Config.TrainingRewardGold)
    data.trainingSessions = math.min(1000000000, data.trainingSessions + 1)
    local levels = Progression.addXP(data, Config.TrainingRewardXP, Config.MaxLevel)
    if levels > 0 then applyCharacter(player, data) end
    PlayerService.send(player, if levels > 0 then "Level naik! Sekarang level " .. data.level else string.format("+%d EXP  •  +%d gold", Config.TrainingRewardXP, Config.TrainingRewardGold))
    return true
end
return PlayerService
