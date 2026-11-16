#!/usr/bin/env python3
"""Exercise actual server gameplay modules against minimal Luau fakes, not Roblox physics."""
import json
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
services = root / "src/ServerScriptService/Services"
sources = {name: (services / (name + ".luau")).read_text() for name in ("PlayerService", "InventoryService", "WorldService")}
test = r'''
local Config = require("../src/ReplicatedStorage/Shared/Config")
local Progression = require("../src/ReplicatedStorage/Shared/Progression")
local Schema = require("../src/ServerScriptService/Services/ProfileSchema")
local ItemConfig = require("../src/ReplicatedStorage/Shared/ItemConfig")
local InventoryRules = require("../src/ServerScriptService/Services/InventoryRules")
local now = 100
local function signal()
    local connections = {}
    return {Connect = function(_, fn) table.insert(connections, fn) end,
        Fire = function(_, ...) for _, fn in ipairs(connections) do fn(...) end end}
end
local vectorMeta = {}
function vectorMeta.__index(self, key)
    if key == "Magnitude" then return math.sqrt(self.X*self.X + self.Y*self.Y + self.Z*self.Z) end
end
function vectorMeta.__add(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},vectorMeta) end
function vectorMeta.__sub(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},vectorMeta) end
function vectorMeta.__mul(a,b) return setmetatable({X=a.X*b,Y=a.Y*b,Z=a.Z*b},vectorMeta) end
local Vector3 = {new = function(x,y,z) return setmetatable({X=x,Y=y,Z=z},vectorMeta) end}
local cframeMeta = {__mul = function(a,b) return a end}
local CFrame = {new = function(...) return setmetatable({}, cframeMeta) end, Angles = function(...) return setmetatable({}, cframeMeta) end}
local function enum()
    return setmetatable({}, {__index = function(self, k) local item = enum(); rawset(self,k,item); return item end})
end
local instanceMeta = {}
function instanceMeta.__index(self, key)
    if key == "FindFirstChild" then return function(obj, name) for _, child in ipairs(obj.children) do if child.Name == name then return child end end end end
    return rawget(self, key)
end
function instanceMeta.__newindex(self, key, value)
    rawset(self,key,value)
    if key == "Parent" and type(value) == "table" and value.children then table.insert(value.children, self) end
end
local function object(class)
    local obj = setmetatable({ClassName = class, Name = class, children = {}},instanceMeta)
    if class == "ProximityPrompt" then obj.Triggered = signal() end
    return obj
end
local workspace = object("Workspace")
workspace.Terrain = {FillBlock = function() end, FillBall = function() end}
local lighting = object("Lighting")
local players = {PlayerRemoving = signal()}
local marker = {Config={}, Progression={}, ItemConfig={}, Data={}, Player={}, Rules={}}
local replicated = {Shared = {Config=marker.Config, Progression=marker.Progression, ItemConfig=marker.ItemConfig}}
local profiles = {}
local dataService = {get = function(player) return profiles[player] end}
local modules = {[marker.Config]=Config, [marker.Progression]=Progression, [marker.ItemConfig]=ItemConfig, [marker.Data]=dataService, [marker.Rules]=InventoryRules}
local fakeGame = {GetService = function(_, name) return assert(({Workspace=workspace, Lighting=lighting, Players=players, ReplicatedStorage=replicated})[name], name) end}
local env = setmetatable({game=fakeGame, workspace=workspace, script={Parent={PlayerDataService=marker.Data, PlayerService=marker.Player, InventoryRules=marker.Rules}},
    require=function(m) return assert(modules[m], "missing fake dependency") end,
    os={clock=function() return now end}, Vector3=Vector3, CFrame=CFrame, Enum=enum(),
    Color3={fromRGB=function(...) return {} end}, UDim2={fromScale=function(...) return {} end},
    Instance={new=object}}, {__index=getfenv()})
local function load(source)
    local chunk = assert(loadstring(source)); setfenv(chunk,env); return chunk()
end
local PlayerService = load(__PLAYER__); modules[marker.Player]=PlayerService
local InventoryService = load(__INVENTORY__)
local WorldService = load(__WORLD__)
local messages = {}
PlayerService.init({FireClient=function(_, player, data, message) messages[player]={data=data,message=message} end})
WorldService.build()
local world = assert(workspace:FindFirstChild("AetherWorld"))
local village = assert(world:FindFirstChild("EldoriaVillage"))
assert(village:FindFirstChild("VillageSpawn") and village:FindFirstChild("Bridge") and village:FindFirstChild("EastBridge"))
local board = assert(village:FindFirstChild("AdventurerBoard"))
local prompt = assert(board:FindFirstChild("ProximityPrompt"))
local function makePlayer(id)
    local humanoid = {Health=100, MaxHealth=100}
    local root = {Position=Vector3.new(0,4.5,-22)}
    local character = {FindFirstChild=function(_,name) if name == "HumanoidRootPart" then return root end end,
        FindFirstChildOfClass=function(_,name) if name == "Humanoid" then return humanoid end end,
        WaitForChild=function(_,name) if name == "Humanoid" then return humanoid end end}
    local p = {UserId=id, Parent=true, Character=character, attrs={}, SetAttribute=function(self,key,value) self.attrs[key]=value end}
    profiles[p]=Schema.new()
    PlayerService.characterAdded(p,character)
    return p, humanoid, root
end
local a, human, root = makePlayer(1)
local b = makePlayer(2)
assert(a.attrs.AetherMana==100 and a.attrs.AetherMaxMana==100 and human.WalkSpeed==Config.BaseWalkSpeed)
prompt.Triggered:Fire(a)
assert(profiles[a].xp==35 and profiles[a].gold==12 and profiles[a].trainingSessions==1)
assert(messages[a].data.level==1 and messages[a].data.inventory.tonic==2)
prompt.Triggered:Fire(a)
assert(profiles[a].gold==12 and messages[a].message:find("belum siap"))
prompt.Triggered:Fire(b)
assert(profiles[b].gold==12 and profiles[a].gold==12)
now += 21; root.Position=Vector3.new(100,4.5,-22); prompt.Triggered:Fire(a)
assert(profiles[a].gold==12)
root.Position=Vector3.new(0,4.5,-22); human.Health=0; prompt.Triggered:Fire(a)
assert(profiles[a].gold==12)
human.Health=100; prompt.Triggered:Fire(a)
now += 21; prompt.Triggered:Fire(a)
assert(profiles[a].level==2 and profiles[a].xp==5 and profiles[a].gold==36)
assert(human.MaxHealth==110 and a.attrs.AetherMaxMana==105)
human.Health=50; InventoryService.use(a,"unknown"); assert(profiles[a].inventory.tonic==2)
InventoryService.use(a,"tonic"); assert(human.Health==90 and profiles[a].inventory.tonic==1)
InventoryService.use(a,"tonic"); assert(profiles[a].inventory.tonic==1)
now += 1; InventoryService.use(a,"tonic"); assert(human.Health==110 and profiles[a].inventory.tonic==0)
now += 1; human.Health=20; InventoryService.use(a,"tonic"); assert(human.Health==20)
assert(profiles[b].inventory.tonic==2 and profiles[b].gold==12)
print("PASS: mocked server training, cooldown, level/health/mana, tonic and two-player isolation")
'''
for name, source in sources.items():
    test = test.replace("__" + {"PlayerService": "PLAYER", "InventoryService": "INVENTORY", "WorldService": "WORLD"}[name] + "__", json.dumps(source, ensure_ascii=False))
path = None
try:
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", suffix=".luau", prefix="flow_", dir=root / "tests", delete=False) as f:
        f.write(test)
        path = Path(f.name)
    subprocess.run(["luau", str(path)], cwd=root, check=True)
finally:
    if path:
        path.unlink(missing_ok=True)
