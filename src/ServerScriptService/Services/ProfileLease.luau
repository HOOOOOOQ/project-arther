local ProfileSchema = if script then require(script.Parent.ProfileSchema) else require("./ProfileSchema")
local ProfileLease = {}

local function validRecord(old)
    if type(old) ~= "table" then return false, "invalid record" end
    for key in pairs(old) do if key ~= "data" and key ~= "session" then return false, "unknown record field" end end
    if old.session ~= nil then
        local lock = old.session
        if type(lock) ~= "table" or type(lock.token) ~= "string" or type(lock.expires) ~= "number" or lock.expires ~= lock.expires or lock.expires == math.huge or lock.expires == -math.huge then
            return false, "invalid session lease"
        end
        for key in pairs(lock) do if key ~= "token" and key ~= "expires" then return false, "unknown session field" end end
    end
    return true
end

function ProfileLease.acquire(old, token, now, leaseSeconds)
    local data
    if old == nil then
        data = ProfileSchema.new()
    else
        local valid, reason = validRecord(old)
        if not valid then return nil, reason end
        if old.session and old.session.expires > now and old.session.token ~= token then
            return nil, "profile is active on another server"
        end
        data, reason = ProfileSchema.migrate(old.data)
        if not data then return nil, reason end
    end
    return { data = data, session = { token = token, expires = now + leaseSeconds } }
end

function ProfileLease.write(old, token, now, leaseSeconds, snapshot, release)
    local valid = validRecord(old)
    if not valid or not old.session or old.session.token ~= token or old.session.expires <= now then return nil, "lease lost" end
    local validData, reason = ProfileSchema.validate(snapshot)
    if not validData or snapshot.schemaVersion ~= ProfileSchema.VERSION then return nil, reason or "unsupported snapshot" end
    return { data = ProfileSchema.copy(snapshot), session = if release then nil else { token = token, expires = now + leaseSeconds } }
end
return ProfileLease
