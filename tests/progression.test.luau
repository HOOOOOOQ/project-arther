local Progression = require("../src/ReplicatedStorage/Shared/Progression")
local Schema = require("../src/ServerScriptService/Services/ProfileSchema")
local profile = Schema.new()
assert(Schema.validate(profile))
assert(Progression.requiredXP(1) == 100)
assert(Progression.addXP(profile, 99, 100) == 0 and profile.xp == 99)
assert(Progression.addXP(profile, 1, 100) == 1 and profile.level == 2 and profile.xp == 0)
assert(Progression.addXP(profile, 650, 100) == 3 and profile.level == 5 and profile.xp == 50)
assert(Schema.validate(profile))
assert(Progression.stats(2).maxHealth == 110)
local maxed = Schema.new(); maxed.level = 99
Progression.addXP(maxed, 100000, 100)
assert(maxed.level == 100 and maxed.xp == 0 and Schema.validate(maxed))
local invalid = Schema.new(); invalid.schemaVersion = 999
assert(not Schema.validate(invalid))
invalid = Schema.new(); invalid.gold = -1
assert(not Schema.validate(invalid))
invalid = Schema.new(); invalid.xp = 100
assert(not Schema.validate(invalid))
assert(not pcall(function() Progression.addXP(profile, -1, 100) end))
local copy = Schema.copy(profile); copy.gold = 500
assert(profile.gold == 0)
print("PASS: progression and profile schema")
