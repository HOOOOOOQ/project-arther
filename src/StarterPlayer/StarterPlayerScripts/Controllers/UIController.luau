local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemConfig"))
local player = Players.LocalPlayer
local UIController = {}
local reduceAnimations = false

local colors = {
    ink = Color3.fromRGB(14, 19, 25), panel = Color3.fromRGB(23, 29, 35),
    border = Color3.fromRGB(101, 91, 69), gold = Color3.fromRGB(223, 194, 132),
    text = Color3.fromRGB(239, 233, 218), muted = Color3.fromRGB(160, 164, 158),
}
local function create(class, properties, parent)
    local object = Instance.new(class)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end
local function round(object, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, object)
end
local function stroke(object, color)
    create("UIStroke", { Color = color or colors.border, Transparency = 0.35, Thickness = 1 }, object)
end
local function label(parent, text, size, position, textSize, color, font)
    return create("TextLabel", { BackgroundTransparency = 1, Size = size, Position = position,
        Text = text, TextColor3 = color or colors.text, TextSize = textSize,
        Font = font or Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd }, parent)
end
local function panel(parent, size, position)
    local frame = create("Frame", { Size = size, Position = position, BackgroundColor3 = colors.panel, BackgroundTransparency = 0.08, BorderSizePixel = 0 }, parent)
    round(frame); stroke(frame)
    create("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(200,207,203)), Rotation = 90 }, frame)
    return frame
end
local function button(parent, text, size, position, accent)
    local b = create("TextButton", { Size = size, Position = position, BackgroundColor3 = if accent then colors.gold else colors.panel,
        TextColor3 = if accent then colors.ink else colors.text, Text = text, Font = Enum.Font.GothamBold,
        TextSize = 14, AutoButtonColor = false, BorderSizePixel = 0 }, parent)
    round(b); if not accent then stroke(b) end
    local base = b.BackgroundColor3
    local activeTween
    local function tint(color)
        if activeTween then activeTween:Cancel() end
        if reduceAnimations then b.BackgroundColor3 = color else
            activeTween = TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = color }); activeTween:Play()
        end
    end
    b.MouseEnter:Connect(function() tint(base:Lerp(Color3.new(1,1,1), 0.12)) end)
    b.MouseLeave:Connect(function() tint(base) end)
    b.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then tint(base:Lerp(Color3.new(0,0,0), 0.16)) end
    end)
    b.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then tint(base) end
    end)
    return b
end
local function bar(parent, title, y, tint)
    local titleLabel = label(parent, title, UDim2.new(0.32,0,0,16), UDim2.new(0,14,0,y), 10, colors.muted, Enum.Font.GothamBold)
    local valueLabel = label(parent, "—", UDim2.new(0.55,0,0,16), UDim2.new(0.4,0,0,y), 10, colors.text)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    local track = create("Frame", { Size = UDim2.new(1,-28,0,5), Position = UDim2.new(0,14,0,y+17), BackgroundColor3 = Color3.fromRGB(51,57,59), BorderSizePixel = 0 }, parent)
    round(track, 4)
    local fill = create("Frame", { Size = UDim2.fromScale(0,1), BackgroundColor3 = tint, BorderSizePixel = 0 }, track); round(fill, 4)
    return valueLabel, fill
end

function UIController.start()
    -- Respect Roblox's safe area / top bar rather than drawing the HUD underneath it.
    local gui = create("ScreenGui", { Name = "AetherUI", ResetOnSpawn = false, IgnoreGuiInset = false, DisplayOrder = 10 }, player:WaitForChild("PlayerGui"))
    local root = create("Frame", { Name = "Root", Size = UDim2.fromScale(1,1), BackgroundTransparency = 1 }, gui)
    local scale = create("UIScale", { Scale = 1 }, root)
    -- UIScale affects the root's coordinates too, so expand its logical canvas accordingly.
    local function resize()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local viewport = camera.ViewportSize
        local factor = math.clamp(math.min(viewport.X / 900, viewport.Y / 600), 0.55, 1)
        scale.Scale = factor
        root.Size = UDim2.fromScale(1 / factor, 1 / factor)
    end
    local viewportConnection
    local function bindCamera()
        if viewportConnection then viewportConnection:Disconnect() end
        local camera = workspace.CurrentCamera
        if camera then viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
        resize()
    end
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
    bindCamera()

    local menu = create("CanvasGroup", { Name = "MainMenu", Size = UDim2.fromScale(1,1), BackgroundColor3 = colors.ink, BackgroundTransparency = 0.22, BorderSizePixel = 0 }, root)
    local menuShade = create("Frame", { Size = UDim2.fromScale(1,1), BackgroundColor3 = colors.ink, BackgroundTransparency = 0.38, BorderSizePixel = 0 }, menu)
    create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,0.8) }) }, menuShade)
    local menuContent = create("Frame", { Size = UDim2.new(0,440,0,430), Position = UDim2.new(0.08,0,0.5,-215), BackgroundTransparency = 1 }, menu)
    label(menuContent, "AN OPEN WORLD ADVENTURE", UDim2.new(1,0,0,22), UDim2.fromOffset(0,5), 12, colors.gold, Enum.Font.GothamBold)
    label(menuContent, "PROJECT", UDim2.new(1,0,0,32), UDim2.fromOffset(0,43), 23, colors.text, Enum.Font.GothamMedium)
    label(menuContent, "AETHER", UDim2.new(1,0,0,75), UDim2.fromOffset(0,70), 58, colors.text, Enum.Font.GothamBold)
    label(menuContent, "A new journey begins in Eldoria.", UDim2.new(1,0,0,28), UDim2.fromOffset(0,155), 15, colors.muted)
    local play = button(menuContent, "MULAI PETUALANGAN    →", UDim2.fromOffset(280,50), UDim2.fromOffset(0,213), true)
    local menuCharacter = button(menuContent, "KARAKTER", UDim2.fromOffset(135,42), UDim2.fromOffset(0,275), false)
    local menuSettings = button(menuContent, "PENGATURAN", UDim2.fromOffset(135,42), UDim2.fromOffset(145,275), false)
    label(menuContent, "FOUNDATION BUILD  ·  " .. Config.Version, UDim2.fromOffset(400,22), UDim2.fromOffset(0,375), 10, colors.muted, Enum.Font.GothamBold)

    local hud = create("Frame", { Name = "HUD", Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Visible = false }, root)
    local identity = panel(hud, UDim2.fromOffset(278,170), UDim2.fromOffset(20,20))
    label(identity, player.DisplayName, UDim2.new(1,-85,0,22), UDim2.fromOffset(14,10), 15, colors.text, Enum.Font.GothamBold)
    local portrait = create("ImageLabel", { Size = UDim2.fromOffset(36,36), Position = UDim2.new(1,-50,0,10), BackgroundColor3 = colors.ink,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150", BorderSizePixel = 0 }, identity)
    round(portrait, 18); stroke(portrait)
    local subtitle = label(identity, "ADVENTURER", UDim2.new(1,-28,0,16), UDim2.fromOffset(14,32), 10, colors.gold, Enum.Font.GothamBold)
    local hpText, hpFill = bar(identity, "HEALTH", 53, Color3.fromRGB(183,94,84))
    local manaText, manaFill = bar(identity, "MANA", 91, Color3.fromRGB(99,151,190))
    local xpText, xpFill = bar(identity, "EXPERIENCE", 129, colors.gold)
    local goldBox = panel(hud, UDim2.fromOffset(156,45), UDim2.new(1,-176,0,20))
    local goldText = label(goldBox, "◈   0 GOLD", UDim2.new(1,-24,1,0), UDim2.fromOffset(12,0), 13, colors.gold, Enum.Font.GothamBold)
    local quest = panel(hud, UDim2.fromOffset(278,82), UDim2.fromOffset(20,205))
    label(quest, "ELDORIA  /  AKTIVITAS", UDim2.new(1,-24,0,18), UDim2.fromOffset(12,10), 10, colors.gold, Enum.Font.GothamBold)
    local guide = label(quest, "Kunjungi papan petualang di plaza", UDim2.new(1,-24,0,36), UDim2.fromOffset(12,32), 12, colors.text)
    guide.TextWrapped = true
    -- Top-right actions leave the Roblox mobile joystick, jump and prompt areas unobstructed.
    local hudCharacter = button(hud, "KARAKTER  [C]", UDim2.fromOffset(150,42), UDim2.new(1,-170,0,75), false)
    local hudInventory = button(hud, "TAS  [I]", UDim2.fromOffset(150,42), UDim2.new(1,-170,0,123), false)
    local hudSettings = button(hud, "PENGATURAN", UDim2.fromOffset(150,42), UDim2.new(1,-170,0,171), false)
    local toast = panel(hud, UDim2.fromOffset(320,45), UDim2.new(0.5,-160,0,30)); toast.Visible = false
    local toastText = label(toast, "", UDim2.new(1,-24,1,0), UDim2.fromOffset(12,0), 13, colors.gold, Enum.Font.GothamBold)
    toastText.TextXAlignment = Enum.TextXAlignment.Center

    local modalShade = create("Frame", { Size = UDim2.fromScale(1,1), BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.35, Visible = false, BorderSizePixel = 0 }, root)
    local modal = panel(modalShade, UDim2.fromOffset(420,390), UDim2.new(0.5,-210,0.5,-195))
    local modalTitle = label(modal, "KARAKTER", UDim2.fromOffset(330,30), UDim2.fromOffset(20,15), 18, colors.gold, Enum.Font.GothamBold)
    local close = button(modal, "×", UDim2.fromOffset(36,36), UDim2.new(1,-48,0,12), false)
    local modalBody = label(modal, "", UDim2.new(1,-40,1,-80), UDim2.fromOffset(20,60), 15, colors.text)
    modalBody.TextYAlignment = Enum.TextYAlignment.Top; modalBody.TextWrapped = true
    local settingButton = button(modal, "", UDim2.fromOffset(240,42), UDim2.fromOffset(20,125), false); settingButton.Visible = false
    local itemButton = button(modal, "GUNAKAN TONIC", UDim2.fromOffset(240,42), UDim2.fromOffset(20,190), true); itemButton.Visible = false
    local itemIcon = create("TextLabel", { Size = UDim2.fromOffset(64,64), Position = UDim2.new(1,-85,0,90), BackgroundColor3 = Color3.fromRGB(66,86,74), Text = "+", TextSize = 38, Font = Enum.Font.GothamBold, TextColor3 = colors.text, Visible = false, BorderSizePixel = 0 }, modal)
    round(itemIcon); stroke(itemIcon)
    local useItemRequest
    local reducedMotion = false
    local currentState
    local currentModal = ""
    local ready = false
    local playing = false
    local cameraTween
    local function updateModal()
        if currentModal == "character" and currentState then
            local s = currentState.stats
            modalTitle.Text = "KARAKTER"; settingButton.Visible = false; itemButton.Visible = false; itemIcon.Visible = false
            modalBody.Text = string.format("%s   •   LEVEL %d\n\nStrength       %d\nDefense         %d\nAgility             %d\nIntelligence    %d\nCritical chance   %d%%\nCritical damage  %d%%\nMax health     %d\nMax mana      %d", currentState.class, currentState.level, s.strength, s.defense, s.agility, s.intelligence, s.criticalChance, s.criticalDamage, s.maxHealth, s.maxMana)
        elseif currentModal == "settings" then
            modalTitle.Text = "PENGATURAN"; itemButton.Visible = false; itemIcon.Visible = false
            modalBody.Text = "Preferensi antarmuka lokal untuk sesi ini."
            settingButton.Visible = true
            settingButton.Text = if reducedMotion then "ANIMASI: MINIMAL" else "ANIMASI: NORMAL"
        elseif currentModal == "inventory" and currentState then
            modalTitle.Text = "TAS PETUALANG"; settingButton.Visible = false; itemButton.Visible = true; itemIcon.Visible = true
            modalBody.Text = string.format("CONSUMABLE  ·  %s\n\n%s   × %d\n%s\n\nJumlah tersimpan di server.", string.upper(ItemConfig.tonic.rarity), ItemConfig.tonic.name, currentState.inventory.tonic, ItemConfig.tonic.description)
            itemButton.Text = if currentState.inventory.tonic > 0 then "GUNAKAN TONIC" else "TONIC HABIS"
        end
    end
    local function openModal(which)
        if not ready then return end
        currentModal = which; modalShade.Visible = true; updateModal()
    end
    close.Activated:Connect(function() modalShade.Visible = false end)
    settingButton.Activated:Connect(function()
        reducedMotion = not reducedMotion; reduceAnimations = reducedMotion
        if reducedMotion and cameraTween then cameraTween:Cancel(); cameraTween = nil end
        updateModal()
    end)
    itemButton.Activated:Connect(function() if useItemRequest then useItemRequest:FireServer("tonic") end end)
    menuCharacter.Activated:Connect(function() openModal("character") end)
    hudCharacter.Activated:Connect(function() openModal("character") end)
    hudInventory.Activated:Connect(function() openModal("inventory") end)
    menuSettings.Activated:Connect(function() openModal("settings") end)
    hudSettings.Activated:Connect(function() openModal("settings") end)
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not ready then return end
        if input.KeyCode == Enum.KeyCode.C then
            if modalShade.Visible then modalShade.Visible = false else openModal("character") end
        elseif input.KeyCode == Enum.KeyCode.I and playing then
            if modalShade.Visible and currentModal == "inventory" then modalShade.Visible = false else openModal("inventory") end
        elseif input.KeyCode == Enum.KeyCode.Escape and modalShade.Visible then modalShade.Visible = false end
    end)

    local loading = create("CanvasGroup", { Name = "LoadingScreen", Size = UDim2.fromScale(1,1), BackgroundColor3 = colors.ink, BorderSizePixel = 0 }, root)
    local loadTitle = label(loading, "PROJECT AETHER", UDim2.fromOffset(400,55), UDim2.new(0.5,-200,0.5,-75), 30, colors.text, Enum.Font.GothamBold)
    loadTitle.TextXAlignment = Enum.TextXAlignment.Center
    local loadStatus = label(loading, "Menunggu dunia Roblox…", UDim2.fromOffset(400,30), UDim2.new(0.5,-200,0.5,-10), 13, colors.gold)
    loadStatus.TextXAlignment = Enum.TextXAlignment.Center
    local loadTip = label(loading, "TIP  •  Papan petualang berada di plaza Eldoria.", UDim2.fromOffset(440,30), UDim2.new(0.5,-220,0.5,38), 12, colors.muted)
    loadTip.TextXAlignment = Enum.TextXAlignment.Center
    local spinner = create("Frame", { Size = UDim2.fromOffset(36,3), Position = UDim2.new(0.5,-18,0.5,84), BackgroundColor3 = colors.gold, BorderSizePixel = 0 }, loading)
    round(spinner, 3)
    local spinnerTween = TweenService:Create(spinner, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 })
    spinnerTween:Play()

    local notificationId = 0
    local toastTween
    local function notify(message)
        if not message then return end
        notificationId += 1; local id = notificationId
        if toastTween then toastTween:Cancel() end
        toastText.Text = message; toast.Visible = true
        toast.Position = UDim2.new(0.5,-160,0,10)
        if reducedMotion then toast.Position = UDim2.new(0.5,-160,0,30) else
            toastTween = TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5,-160,0,30) })
            toastTween:Play()
        end
        task.delay(3, function()
            if id ~= notificationId then return end
            if reducedMotion then toast.Visible = false else
                toastTween = TweenService:Create(toast, TweenInfo.new(0.2), { Position = UDim2.new(0.5,-160,0,10) })
                toastTween:Play()
                toastTween.Completed:Once(function(state) if state == Enum.PlaybackState.Completed and id == notificationId then toast.Visible = false end end)
            end
        end)
    end
    local barTweens = {}
    local function setBar(fill, fraction)
        if barTweens[fill] then barTweens[fill]:Cancel() end
        local target = UDim2.fromScale(math.clamp(fraction,0,1),1)
        if reducedMotion then fill.Size = target else
            barTweens[fill] = TweenService:Create(fill, TweenInfo.new(0.25), { Size = target })
            barTweens[fill]:Play()
        end
    end
    local function updateMana()
        local current = player:GetAttribute("AetherMana")
        local maximum = player:GetAttribute("AetherMaxMana")
        if type(current) ~= "number" or type(maximum) ~= "number" then manaText.Text = "—"; setBar(manaFill, 0); return end
        manaText.Text = string.format("%d / %d", math.floor(current), math.floor(maximum))
        setBar(manaFill, current / math.max(1, maximum))
    end
    player:GetAttributeChangedSignal("AetherMana"):Connect(updateMana)
    player:GetAttributeChangedSignal("AetherMaxMana"):Connect(updateMana)
    updateMana()
    local healthConnection, maxConnection
    local function health(character)
        if healthConnection then healthConnection:Disconnect() end
        if maxConnection then maxConnection:Disconnect() end
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid or player.Character ~= character then return end
        local function update()
            hpText.Text = string.format("%d / %d", math.ceil(humanoid.Health), math.ceil(humanoid.MaxHealth))
            setBar(hpFill, humanoid.Health / math.max(1, humanoid.MaxHealth))
        end
        healthConnection = humanoid.HealthChanged:Connect(update)
        maxConnection = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
        update()
    end
    player.CharacterAdded:Connect(health)
    if player.Character then task.spawn(health, player.Character) end
    play.Activated:Connect(function()
        if playing or not ready then return end
        playing = true; modalShade.Visible = false
        if cameraTween then cameraTween:Cancel() end
        if reducedMotion then menu.Visible = false else
            local tween = TweenService:Create(menu, TweenInfo.new(0.25), { GroupTransparency = 1 })
            tween:Play(); task.delay(0.25, function() menu.Visible = false end)
        end
        hud.Visible = true
        local camera = workspace.CurrentCamera
        if camera then camera.CameraType = Enum.CameraType.Custom; local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if humanoid then camera.CameraSubject = humanoid end end
    end)

    if not game:IsLoaded() then game.Loaded:Wait() end
    loadStatus.Text = "Menghubungkan data petualang…"
    local remotes = ReplicatedStorage:WaitForChild("AetherRemotes", 30)
    if not remotes then spinnerTween:Cancel(); loadStatus.Text = "Server belum siap. Silakan masuk kembali."; return end
    local stateEvent = remotes:WaitForChild("State", 10)
    local request = remotes:WaitForChild("RequestState", 10)
    useItemRequest = remotes:WaitForChild("UseItem", 10)
    if not stateEvent or not request or not useItemRequest then spinnerTween:Cancel(); loadStatus.Text = "Koneksi server tidak tersedia."; return end
    stateEvent.OnClientEvent:Connect(function(data, message)
        currentState = data
        subtitle.Text = string.upper(data.class) .. "  •  LEVEL " .. data.level
        goldText.Text = "◈   " .. data.gold .. " GOLD"
        xpText.Text = if data.level >= data.maxLevel then "MAX" else data.xp .. " / " .. data.xpRequired
        setBar(xpFill, if data.level >= data.maxLevel then 1 else data.xp / data.xpRequired)
        guide.Text = "Latihan di papan plaza  •  Selesai: " .. data.trainingSessions
        if modalShade.Visible then updateModal() end
        if playing then notify(message) end
    end)
    local started = os.clock()
    while not currentState do
        request:FireServer()
        if os.clock() - started > 30 then loadStatus.Text = "Data masih dimuat; menunggu server…" end
        task.wait(2)
    end
    spinnerTween:Cancel()
    if reducedMotion then loading.Visible = false else
        local fade = TweenService:Create(loading, TweenInfo.new(0.3), { GroupTransparency = 1 })
        fade:Play(); fade.Completed:Wait(); loading.Visible = false
    end
    local camera = workspace.CurrentCamera
    if camera and not playing then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.lookAt(Vector3.new(68, 45, 85), Vector3.new(0, 4, -10))
        if not reducedMotion then
            cameraTween = TweenService:Create(camera, TweenInfo.new(20, Enum.EasingStyle.Linear), { CFrame = CFrame.lookAt(Vector3.new(48, 38, 75), Vector3.new(0, 4, -10)) })
            cameraTween:Play()
        end
    end
    ready = true
end
return UIController
