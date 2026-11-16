local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ProfileSchema = require(script.Parent.ProfileSchema)
local ProfileLease = require(script.Parent.ProfileLease)

local PlayerDataService = {}
local store = DataStoreService:GetDataStore("AetherProfiles_v1")
local sessions = {}
local LEASE_SECONDS = 180
local RETRIES = 3
-- Explicit opt-in for Studio prototyping only. NEVER use ephemeral profiles in published servers.
local STUDIO_EPHEMERAL = false

local function retry(label, operation)
    local lastError
    for attempt = 1, RETRIES do
        local ok, result = pcall(operation)
        if ok then return true, result end
        lastError = result
        warn(('[Aether Data] %s attempt %d failed: %s'):format(label, attempt, tostring(result)))
        if attempt < RETRIES then task.wait(2 ^ (attempt - 1)) end
    end
    return false, lastError
end

-- isCancelled is supplied by the player lifecycle; Parent alone is not sufficient
-- because PlayerRemoving can fire before the Player is unparented.
function PlayerDataService.load(player, isCancelled)
    local function cancelled()
        return not player.Parent or (isCancelled ~= nil and isCancelled())
    end
    if cancelled() then return nil, "player left before load" end
    local key = "player_" .. player.UserId
    local token = HttpService:GenerateGUID(false)
    if STUDIO_EPHEMERAL and RunService:IsStudio() then
        warn("[Aether Data] Studio ephemeral mode: changes will NOT be saved")
        local session = { data = ProfileSchema.new(), token = token, key = key, ephemeral = true }
        sessions[player] = session
        return session.data
    end
    local rejection
    local ok, result = retry("load " .. key, function()
        return store:UpdateAsync(key, function(old)
            local record
            record, rejection = ProfileLease.acquire(old, token, os.time(), LEASE_SECONDS)
            return record
        end)
    end)
    if not ok or rejection or not result then
        return nil, rejection or "DataStore unavailable; your data was not overwritten"
    end
    local session = { data = ProfileSchema.copy(result.data), token = token, key = key, saving = false, closed = false }
    sessions[player] = session
    -- If the player left during a yielding load, release the acquired lock.
    if cancelled() then
        PlayerDataService.release(player)
        return nil, "player left during load"
    end
    return session.data
end

function PlayerDataService.get(player)
    local session = sessions[player]
    if session and not session.closed then return session.data end
    return nil
end

-- Serialize writes per session. UpdateAsync verifies ownership and lease on every write.
local function save(player, release)
    local session = sessions[player]
    if not session then return true end
    while session.saving do task.wait(0.1) end
    -- Concurrent callers must not report success after a failed final write.
    if session.closed then return session.closeSucceeded == true end
    session.saving = true
    if session.ephemeral then
        session.saving = false
        if release then session.closed = true; session.closeSucceeded = true; sessions[player] = nil end
        return true
    end
    local valid, reason = ProfileSchema.validate(session.data)
    if not valid or session.data.schemaVersion ~= ProfileSchema.VERSION then
        session.saving = false
        warn("[Aether Data] refusing invalid save: " .. tostring(reason))
        if release then
            session.closed = true; session.closeSucceeded = false; sessions[player] = nil
        elseif player.Parent then
            player:Kick("Data sesi tidak valid; penyimpanan dibatalkan.")
        end
        return false
    end
    local snapshot = ProfileSchema.copy(session.data)
    local rejected
    local ok, result = retry("save " .. session.key, function()
        return store:UpdateAsync(session.key, function(old)
            local record
            record, rejected = ProfileLease.write(old, session.token, os.time(), LEASE_SECONDS, snapshot, release)
            return record
        end)
    end)
    session.saving = false
    if not ok or rejected or not result then
        warn("[Aether Data] save not confirmed for " .. session.key .. ": " .. tostring(if rejected then rejected else result))
        if release then
            -- Do not keep renewing a departed player's lease after a failed final save.
            -- The remote lease expires naturally; the failed write is never reported as saved.
            session.closed = true
            session.closeSucceeded = false
            sessions[player] = nil
        elseif player.Parent then
            player:Kick("Data sesi tidak dapat disimpan dengan aman. Silakan masuk kembali.")
        end
        return false
    end
    if release then session.closed = true; session.closeSucceeded = true; sessions[player] = nil end
    return true
end

function PlayerDataService.save(player) return save(player, false) end
function PlayerDataService.release(player) return save(player, true) end
function PlayerDataService.players()
    local list = {}
    for player in pairs(sessions) do table.insert(list, player) end
    return list
end
return PlayerDataService
