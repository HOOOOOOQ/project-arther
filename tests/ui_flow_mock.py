#!/usr/bin/env python3
"""Run UIController with lightweight fakes; no rendering, input device or Roblox engine."""
import json
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root / "src/StarterPlayer/StarterPlayerScripts/Controllers/UIController.luau").read_text()
test = r'''
local Config = require("../src/ReplicatedStorage/Shared/Config")
local ItemConfig = require("../src/ReplicatedStorage/Shared/ItemConfig")
local function signal()
    local c = {}
    return {Connect=function(_,fn) local v={fn=fn,active=true}; table.insert(c,v); return {Disconnect=function() v.active=false end} end,
        Once=function(_,fn) local v={fn=fn,active=true,once=true}; table.insert(c,v) end,
        Wait=function() return end,
        Fire=function(_,...) for _,v in ipairs(c) do if v.active then if v.once then v.active=false end; v.fn(...) end end end}
end
local enum
function enum() return setmetatable({}, {__index=function(self,k) local v=enum(); rawset(self,k,v); return v end}) end
local Enum = enum()
local objectMeta = {}
function objectMeta.__index(self,key)
    if key == "WaitForChild" or key == "FindFirstChild" then
        return function(obj,name) for _,child in ipairs(obj.children) do if child.Name==name then return child end end end
    elseif key == "GetPropertyChangedSignal" then
        return function(obj,name) obj.signals[name]=obj.signals[name] or signal(); return obj.signals[name] end
    end
    return rawget(self,key)
end
function objectMeta.__newindex(self,key,value)
    rawset(self,key,value)
    if key == "Parent" and type(value)=="table" and value.children then table.insert(value.children,self) end
end
local function object(class)
    local o=setmetatable({ClassName=class,Name=class,children={},signals={}},objectMeta)
    if class=="TextButton" then o.Activated=signal(); o.MouseEnter=signal(); o.MouseLeave=signal(); o.InputBegan=signal(); o.InputEnded=signal() end
    return o
end
local colors = {__index={Lerp=function(self) return self end}}
local Color3={fromRGB=function(...) return setmetatable({},colors) end,new=function(...) return setmetatable({},colors) end}
local UDim2={new=function(...) return {...} end,fromOffset=function(...) return {...} end,fromScale=function(...) return {...} end}
local common={new=function(...) return {...} end}
local playerGui=object("PlayerGui")
local human=object("Humanoid"); human.Health=100; human.MaxHealth=100; human.HealthChanged=signal()
local character=object("Character"); human.Parent=character
function character:FindFirstChildOfClass(class) if class=="Humanoid" then return human end end
local player=object("Player"); player.DisplayName="Tester"; player.UserId=123; playerGui.Parent=player; player.Character=character
player.CharacterAdded=signal(); player.attrs={AetherMana=100,AetherMaxMana=100}
function player:GetAttribute(name) return self.attrs[name] end
function player:GetAttributeChangedSignal(name) return self:GetPropertyChangedSignal(name) end
local camera=object("Camera"); camera.ViewportSize={X=1280,Y=720}
local workspace=object("Workspace"); workspace.CurrentCamera=camera
local input={InputBegan=signal()}
local activeTweens={}
local TweenService={Create=function(_,target,info,props)
    local tween={Completed=signal(),cancelled=false}
    function tween:Play() for k,v in pairs(props) do target[k]=v end end
    function tween:Cancel() self.cancelled=true end
    table.insert(activeTweens,tween); return tween
end}
local state={OnClientEvent=signal()}
local data={level=1,xp=0,xpRequired=100,gold=0,class="Warrior",stats={strength=5,defense=5,agility=5,intelligence=5,criticalChance=5,criticalDamage=150,maxHealth=100,maxMana=100},maxLevel=100,inventory={tonic=2},trainingSessions=0}
local request={FireServer=function()
    -- Input and button activation while the profile is still loading must be ignored.
    input.InputBegan:Fire({KeyCode=Enum.KeyCode.C},false)
    input.InputBegan:Fire({KeyCode=Enum.KeyCode.I},false)
    local function findButton(node,text)
        if node.ClassName=="TextButton" and node.Text==text then return node end
        for _,child in ipairs(node.children) do local match=findButton(child,text); if match then return match end end
    end
    assert(findButton(playerGui,"MULAI PETUALANGAN    →")).Activated:Fire()
    assert(findButton(playerGui,"KARAKTER")).Activated:Fire()
    state.OnClientEvent:Fire(data)
end}
local useCount=0
local use={FireServer=function(_,item)
    assert(item=="tonic"); useCount+=1; data.inventory.tonic-=1; human.Health=80
    human.HealthChanged:Fire(human.Health); state.OnClientEvent:Fire(data,"Eldoria Tonic digunakan.")
end}
local remotes={WaitForChild=function(_,name) return ({State=state, RequestState=request,UseItem=use})[name] end}
local markerConfig,markerItem={},{}
local shared={WaitForChild=function(_,name) return ({Config=markerConfig,ItemConfig=markerItem})[name] end}
local replicated={WaitForChild=function(_,name) return ({Shared=shared,AetherRemotes=remotes})[name] end}
local fakeGame={IsLoaded=function() return true end,GetService=function(_,name) return assert(({Players={LocalPlayer=player},TweenService=TweenService,UserInputService=input,ReplicatedStorage=replicated})[name],name) end}
local tasks={}
local env=setmetatable({game=fakeGame,workspace=workspace,Enum=Enum,Color3=Color3,UDim2=UDim2,UDim=common,
    NumberSequence=common,NumberSequenceKeypoint=common,ColorSequence=common,TweenInfo=common,
    CFrame={lookAt=function(...) return {} end},Vector3={new=function(...) return {...} end},
    Instance={new=object},require=function(key) return assert(({[markerConfig]=Config,[markerItem]=ItemConfig})[key]) end,
    task={wait=function() end,spawn=function(fn,...) fn(...) end,delay=function(_,fn) table.insert(tasks,fn) end}}, {__index=getfenv()})
local chunk=assert(loadstring(__SOURCE__,"UIController")); setfenv(chunk,env)
chunk().start()
local gui=assert(playerGui:FindFirstChild("AetherUI")); assert(gui.IgnoreGuiInset==false)
local root=assert(gui:FindFirstChild("Root"))
local menu=assert(root:FindFirstChild("MainMenu")); local hud=assert(root:FindFirstChild("HUD")); local loading=assert(root:FindFirstChild("LoadingScreen"))
assert(menu.Visible~=false and hud.Visible==false and loading.Visible==false and camera.CameraType==Enum.CameraType.Scriptable)
local function find(obj, class, text)
    if obj.ClassName==class and obj.Text==text then return obj end
    for _,c in ipairs(obj.children) do local found=find(c,class,text); if found then return found end end
end
local function click(text) local b=assert(find(root,"TextButton",text),text); b.Activated:Fire() end
local shade = assert(find(root,"TextButton","×")).Parent.Parent
assert(shade.Visible == false, "keyboard opened a panel before profile loading completed")
assert(find(hud,"TextLabel","100 / 100")); assert(find(hud,"TextLabel","0 / 100")); assert(find(hud,"TextLabel","◈   0 GOLD"))
input.InputBegan:Fire({KeyCode=Enum.KeyCode.I},false)
assert(not find(root,"TextButton","GUNAKAN TONIC").Visible, "inventory shortcut opened before play")
click("KARAKTER"); assert(find(root,"TextLabel","KARAKTER"))
click("×")
click("PENGATURAN"); click("ANIMASI: NORMAL"); assert(find(root,"TextButton","ANIMASI: MINIMAL"))
assert(activeTweens[#activeTweens].cancelled, "reducing motion should cancel the menu camera tween")
click("×"); click("MULAI PETUALANGAN    →")
assert(menu.Visible==false and hud.Visible==true and camera.CameraType==Enum.CameraType.Custom)
click("TAS  [I]"); click("GUNAKAN TONIC")
assert(useCount==1 and data.inventory.tonic==1 and find(hud,"TextLabel","80 / 100"))
data.xp=35; data.gold=12; data.trainingSessions=1; state.OnClientEvent:Fire(data,"+35 EXP  •  +12 gold")
assert(find(hud,"TextLabel","35 / 100") and find(hud,"TextLabel","◈   12 GOLD"))
assert(find(hud,"TextLabel","+35 EXP  •  +12 gold"))
print("PASS: mocked UI creation, menu, panels, HUD updates, tonic request and reduced motion")
'''.replace("__SOURCE__", json.dumps(source, ensure_ascii=False))
path = None
try:
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", suffix=".luau", prefix="ui_", dir=root / "tests", delete=False) as f:
        f.write(test)
        path = Path(f.name)
    subprocess.run(["luau", str(path)], cwd=root, check=True)
finally:
    if path:
        path.unlink(missing_ok=True)
