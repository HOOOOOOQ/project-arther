local ProfileSchema = {}
ProfileSchema.VERSION = 2

function ProfileSchema.new()
    return { schemaVersion = 2, level = 1, xp = 0, gold = 0, class = "Warrior", inventory = { tonic = 2 }, trainingSessions = 0 }
end

local function integer(value, minimum, maximum)
    return type(value) == "number" and value == value and value >= minimum and value <= maximum and value == math.floor(value)
end

function ProfileSchema.validate(profile)
    if type(profile) ~= "table" then return false, "profile is not a table" end
    if profile.schemaVersion ~= 1 and profile.schemaVersion ~= ProfileSchema.VERSION then return false, "unsupported profile schema" end
    local allowed = { schemaVersion = true, level = true, xp = true, gold = true, class = true }
    if profile.schemaVersion == 2 then allowed.inventory = true; allowed.trainingSessions = true end
    for key in pairs(profile) do if not allowed[key] then return false, "unknown profile field" end end
    if not integer(profile.level, 1, 100) then return false, "invalid level" end
    if not integer(profile.xp, 0, 1000000000) then return false, "invalid XP" end
    if profile.level == 100 and profile.xp ~= 0 then return false, "invalid max-level XP" end
    if profile.level < 100 and profile.xp >= 100 + (profile.level - 1) * 50 then return false, "XP exceeds level threshold" end
    if not integer(profile.gold, 0, 1000000000) then return false, "invalid gold" end
    if profile.class ~= "Warrior" then return false, "unsupported class" end
    if profile.schemaVersion == 2 then
        if type(profile.inventory) ~= "table" or not integer(profile.inventory.tonic, 0, 99) then return false, "invalid inventory" end
        for key in pairs(profile.inventory) do if key ~= "tonic" then return false, "unknown inventory item" end end
        if not integer(profile.trainingSessions, 0, 1000000000) then return false, "invalid training count" end
    end
    return true
end

-- v1 was released without inventory; migrate in memory only after validation.
function ProfileSchema.migrate(profile)
    local valid, reason = ProfileSchema.validate(profile)
    if not valid then return nil, reason end
    if profile.schemaVersion == 1 then
        return { schemaVersion = 2, level = profile.level, xp = profile.xp, gold = profile.gold, class = profile.class, inventory = { tonic = 2 }, trainingSessions = 0 }
    end
    return ProfileSchema.copy(profile)
end

function ProfileSchema.copy(profile)
    return { schemaVersion = profile.schemaVersion, level = profile.level, xp = profile.xp, gold = profile.gold, class = profile.class,
        inventory = { tonic = profile.inventory.tonic }, trainingSessions = profile.trainingSessions }
end
return ProfileSchema
