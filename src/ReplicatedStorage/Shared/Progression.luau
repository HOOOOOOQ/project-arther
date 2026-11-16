local Progression = {}

function Progression.requiredXP(level)
    return 100 + (level - 1) * 50
end

-- All inputs are trusted server data. Returns the number of levels gained.
function Progression.addXP(profile, amount, maxLevel)
    assert(type(amount) == "number" and amount >= 0 and amount == math.floor(amount), "invalid XP")
    local before = profile.level
    if profile.level >= maxLevel then
        profile.xp = 0
        return 0
    end
    profile.xp += amount
    while profile.level < maxLevel and profile.xp >= Progression.requiredXP(profile.level) do
        profile.xp -= Progression.requiredXP(profile.level)
        profile.level += 1
    end
    if profile.level >= maxLevel then
        profile.xp = 0
    end
    return profile.level - before
end

function Progression.stats(level)
    return {
        strength = 5 + (level - 1) * 2,
        defense = 5 + (level - 1) * 2,
        agility = 5 + level - 1,
        intelligence = 5 + level - 1,
        criticalChance = 5,
        criticalDamage = 150,
        maxHealth = 100 + (level - 1) * 10,
        maxMana = 100 + (level - 1) * 5,
    }
end

return Progression
