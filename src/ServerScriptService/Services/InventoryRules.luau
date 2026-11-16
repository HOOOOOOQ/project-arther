-- Pure validation/mutation logic; caller supplies server-observed health.
local InventoryRules = {}
function InventoryRules.consumeTonic(profile, health, maxHealth, heal)
    if type(health) ~= "number" or type(maxHealth) ~= "number" or health <= 0 or health >= maxHealth then
        return false, "Health sudah penuh atau karakter tidak aktif."
    end
    if profile.inventory.tonic <= 0 then return false, "Tonic sudah habis." end
    profile.inventory.tonic -= 1
    return true, math.min(maxHealth, health + heal)
end
return InventoryRules
