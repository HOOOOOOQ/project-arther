#!/usr/bin/env python3
"""Exercise the real PlayerDataService with deterministic, in-memory platform fakes.
This is NOT a Roblox DataStore or a concurrency/engine test.
"""
import json
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root / "src/ServerScriptService/Services/PlayerDataService.luau").read_text()
test = r'''
local Schema = require("../src/ServerScriptService/Services/ProfileSchema")
local Lease = require("../src/ServerScriptService/Services/ProfileLease")
local now = 1000
local records = {}
local failures = 0
local hook = nil
local calls = 0
local waitThread
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = copy(v) end
    return result
end
local store = {}
function store:UpdateAsync(key, callback)
    calls += 1
    if failures > 0 then failures -= 1; error("simulated service failure") end
    local value = callback(copy(records[key]))
    if value ~= nil then records[key] = copy(value) end
    if hook then local f = hook; hook = nil; f() end
    return copy(value)
end
local datastore = {GetDataStore = function(_, name) assert(name == "AetherProfiles_v1"); return store end}
local nextToken = 0
local http = {GenerateGUID = function() nextToken += 1; return "session-" .. nextToken end}
local runtime = {IsStudio = function() return false end}
local fakeGame = {GetService = function(_, name)
    return assert(({DataStoreService = datastore, HttpService = http, RunService = runtime})[name], name)
end}
local markerSchema, markerLease = {}, {}
local fakeScript = {Parent = {ProfileSchema = markerSchema, ProfileLease = markerLease}}
local realRequire = require
local fakeRequire = function(module)
    if module == markerSchema then return Schema end
    if module == markerLease then return Lease end
    return realRequire(module)
end
local env = setmetatable({game = fakeGame, script = fakeScript, require = fakeRequire,
    task = {wait = function(seconds)
        if coroutine.running() == waitThread then coroutine.yield() else now += seconds or 0 end
    end}, os = {time = function() return now end},
    warn = function(...) end}, {__index = getfenv()})
local chunk = assert(loadstring(__SOURCE__, "PlayerDataService"))
setfenv(chunk, env)
local service = chunk()
local function player(id)
    return {UserId = id, Parent = true, Kick = function(self, reason) self.kicked = reason end}
end
-- Valid v1 migration, successful retry, exclusive lock, save/release.
records.player_1 = {data = {schemaVersion = 1, level = 4, xp = 12, gold = 345, class = "Warrior"}}
failures = 2
local p = player(1)
local data = assert(service.load(p))
assert(calls == 3 and data.schemaVersion == 2 and data.gold == 345 and records.player_1.session)
local other = player(1)
assert(not service.load(other))
assert(records.player_1.data.gold == 345)
data.gold = 500; data.inventory.tonic = 1
assert(service.save(p) and records.player_1.data.gold == 500)
assert(service.release(p) and records.player_1.session == nil and not service.get(p))
-- A failed load never overwrites the old record or opens a session.
local original = copy(records.player_1)
failures = 3
assert(not service.load(player(1)))
assert(records.player_1.data.gold == original.data.gold and records.player_1.session == nil)
-- Cancellation can happen while the player is still parented (PlayerRemoving).
local leaving = player(2)
local cancelled = false
hook = function() cancelled = true end
local loaded = service.load(leaving, function() return cancelled end)
assert(not loaded, "load must stop if PlayerRemoving fired before UpdateAsync returned")
assert(not service.get(leaving), "cancelled load leaked a session")
assert(records.player_2.session == nil, "cancelled load failed to release its lease")
-- Lease loss must not overwrite the newer owner's data.
local lost = player(3)
local lostData = assert(service.load(lost))
lostData.gold = 999
records.player_3.session.token = "new-owner"
records.player_3.data.gold = 17
assert(not service.save(lost) and lost.kicked)
assert(records.player_3.data.gold == 17)
assert(not service.release(lost) and not service.get(lost))
-- Failed final write must not keep a session in memory.
local departing = player(4)
assert(service.load(departing))
failures = 3
assert(not service.release(departing) and not service.get(departing))
assert(records.player_4.session ~= nil)
-- A concurrent waiter must observe a failed final save, not a false success.
local concurrent = player(6)
assert(service.load(concurrent))
local waiterResult
hook = function()
    waitThread = coroutine.create(function() waiterResult = service.release(concurrent) end)
    assert(coroutine.resume(waitThread))
    failures = 2
    error("simulated lost response after commit")
end
assert(not service.release(concurrent))
assert(coroutine.resume(waitThread))
assert(waiterResult == false, "waiting release falsely reported a failed save as successful")
waitThread = nil
-- Invalid in-memory inventory cannot be copied or saved over a valid record.
local invalid = player(5)
local invalidData = assert(service.load(invalid))
invalidData.inventory = nil
assert(not service.release(invalid) and not service.get(invalid))
assert(records.player_5.data.inventory.tonic == 2)
print("PASS: mocked PlayerDataService retries, migration, cancellation, ownership and failed saves")
'''.replace("__SOURCE__", json.dumps(source))
path = None
try:
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", suffix=".luau", prefix="mock_", dir=root / "tests", delete=False) as f:
        f.write(test)
        path = Path(f.name)
    subprocess.run(["luau", str(path)], cwd=root, check=True)
finally:
    if path:
        path.unlink(missing_ok=True)
