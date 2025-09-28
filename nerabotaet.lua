-- == Безопасный HTTP Block ==
local G = (getgenv and getgenv()) or _G

local function clog(msg)
    msg = '[SAFE-BLOCK] ' .. tostring(msg)
    if warn then warn(msg) else print(msg) end
    if G.rconsoleprint then G.rconsoleprint(msg .. '\n') end
end

-- Паттерны для обнаружения Discord webhook URL
local DISCORD_PATTERNS = {
    "discord%.com/api/webhooks/",
    "discordapp%.com/api/webhooks/",
    "webhook%.lewisakura%.moe/api/webhooks/",
    "hooks%.hyra%.io/api/webhooks/",
    "canary%.discord%.com/api/webhooks/",
    "ptb%.discord%.com/api/webhooks/"
}

local function isDiscordWebhook(url)
    if type(url) ~= "string" then return false end
    url = url:lower()
    
    for _, pattern in ipairs(DISCORD_PATTERNS) do
        if url:match(pattern) then
            return true
        end
    end
    
    if url:match("webhooks/%d+/[%w%-_]+") then
        return true
    end
    
    return false
end

local function block_request(opts)
    local url = 'unknown'
    if type(opts) == 'table' then 
        url = opts.Url or opts.url or tostring(opts) 
    else 
        url = tostring(opts) 
    end
    
    -- Специальная блокировка Discord webhooks
    if isDiscordWebhook(url) then
        clog('BLOCKED DISCORD WEBHOOK: ' .. url)
        return { 
            StatusCode = 403, 
            Headers = {}, 
            Body = '{"message":"403: Forbidden","code":50013}', 
            Success = false 
        }
    end
    
    clog('BLOCKED: ' .. url)
    return { StatusCode = 200, Headers = {}, Body = '{"blocked":true}', Success = true }
end

local function safe_replace(tableObj, key, new_func)
    local succ = pcall(function() tableObj[key] = new_func end)
    if succ then clog('Replaced ' .. tostring(key)) end
    return succ
end

safe_replace(G, 'request', block_request)
safe_replace(G, 'http_request', block_request)
pcall(function() if G.syn then safe_replace(G.syn, 'request', block_request) end end)
pcall(function() if G.http then safe_replace(G.http, 'request', block_request) end end)

-- == Гарантированное получение LocalPlayer ==
local Players = game:GetService('Players')
local player = Players.LocalPlayer
if not player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local CoreGui = game:GetService('CoreGui')
local UserInputService = game:GetService('UserInputService')

-- == ФУНКЦИЯ ПОЛНОГО ОТКЛЮЧЕНИЯ АНИМАЦИЙ ==
local function disableAllAnimations(character)
    -- Отключаем основной скрипт анимаций
    local animate = character:FindFirstChild("Animate")
    if animate then
        animate.Disabled = true
        animate:Destroy() -- Полностью удаляем скрипт
    end
    
    -- Останавливаем все текущие анимации
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            -- Останавливаем все играющие анимации
            for _, animationTrack in pairs(animator:GetPlayingAnimationTracks()) do
                animationTrack:Stop()
                animationTrack:Destroy()
            end
            -- Уничтожаем сам Animator
            animator:Destroy()
        end
        
        -- Останавливаем анимации через устаревший метод (на всякий случай)
        local success, tracks = pcall(function()
            return humanoid:GetPlayingAnimationTracks()
        end)
        if success and tracks then
            for _, track in pairs(tracks) do
                track:Stop()
                track:Destroy()
            end
        end
    end
end

-- Функция постоянного отключения анимаций
local function keepAnimationsDisabled(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            -- Постоянно останавливаем любые анимации, которые могут запуститься
            for _, animationTrack in pairs(animator:GetPlayingAnimationTracks()) do
                animationTrack:Stop()
                animationTrack:Destroy()
            end
            -- Удаляем Animator если он появился снова
            animator:Destroy()
        end
    end
    
    -- Отключаем Animate скрипт, если он снова появился
    local animate = character:FindFirstChild("Animate")
    if animate then
        animate.Disabled = true
        animate:Destroy()
    end
end

-- == СИСТЕМА INFINITY JUMP ==
local infinityJumpEnabled = true -- ВСЕГДА ВКЛЮЧЕНО
local isSpacePressed = false

-- Функция настройки персонажа для полёта
local function setupCharacterForFlight(character)
    local humanoid = character:WaitForChild("Humanoid")
    wait(0.1)
    
    -- ПОЛНОЕ ОТКЛЮЧЕНИЕ АНИМАЦИЙ
    disableAllAnimations(character)
    
    -- Отключаем только защиту от падения с краёв
    humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
end

-- Функция проверки на землю
local function isOnGround(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    -- Используем встроенные методы Roblox для определения состояния
    local state = humanoid:GetState()
    return state ~= Enum.HumanoidStateType.Freefall and 
           state ~= Enum.HumanoidStateType.Jumping and
           state ~= Enum.HumanoidStateType.Flying and
           humanoid.FloorMaterial ~= Enum.Material.Air
end

-- Функция бесконечного прыжка вверх
local function infinityJump()
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoidRootPart or not humanoid then return end
    
    -- Используем MoveDirection напрямую - он уже учитывает камеру!
    local moveVector = humanoid.MoveDirection
    local walkSpeed = humanoid.WalkSpeed
    
    -- Естественное движение: используем MoveDirection как есть
    local horizontalVelocity = moveVector * walkSpeed
    
    -- УВЕЛИЧЕННАЯ скорость полёта вверх (в 2 раза больше)
    humanoidRootPart.AssemblyLinearVelocity = Vector3.new(
        horizontalVelocity.X,
        32, -- Увеличено с 16 до 32 (в 2 раза больше)
        horizontalVelocity.Z
    )
end

-- Функция быстрого падения с естественным движением
local function fall()
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoidRootPart or not humanoid then return end
    
    -- Переводим в свободное падение
    if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
        humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
    end
    
    -- Используем MoveDirection для естественного движения
    local moveVector = humanoid.MoveDirection
    local walkSpeed = humanoid.WalkSpeed
    
    -- БЫСТРОЕ ПАДЕНИЕ - увеличенная скорость падения
    local fastFallSpeed = -80 -- Увеличено с -50 до -80 (в 1.6 раза быстрее)
    
    -- Естественное горизонтальное движение
    local horizontalVelocity = moveVector * walkSpeed
    
    humanoidRootPart.AssemblyLinearVelocity = Vector3.new(
        horizontalVelocity.X,
        fastFallSpeed,
        horizontalVelocity.Z
    )
end

-- Основной цикл Infinity Jump (ВСЕГДА РАБОТАЕТ)
local infinityJumpConnection = nil
local function startInfinityJump()
    if infinityJumpConnection then return end
    infinityJumpConnection = RunService.RenderStepped:Connect(function()
        local character = player.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        -- ПОСТОЯННОЕ ОТКЛЮЧЕНИЕ АНИМАЦИЙ
        keepAnimationsDisabled(character)
        
        local onGround = isOnGround(character)
        
        -- ВСЕГДА АКТИВНЫЙ Infinity Jump
        if isSpacePressed then
            infinityJump() -- Бесконечный прыжок вверх когда зажат пробел
        elseif not onGround then
            fall() -- БЫСТРОЕ падение когда пробел не зажат и не на земле
        end
        -- На земле - система Humanoid управляет движением
    end)
end

local function stopInfinityJump()
    if infinityJumpConnection then
        infinityJumpConnection:Disconnect()
        infinityJumpConnection = nil
    end
end

-- Обработка ввода для Infinity Jump
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Space then
        isSpacePressed = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Space then
        isSpacePressed = false
    end
end)

-- Настройка при возрождении
player.CharacterAdded:Connect(function(character)
    setupCharacterForFlight(character)
    
    -- Дополнительное отключение анимаций с задержкой
    task.wait(0.5)
    disableAllAnimations(character)
end)

-- Настройка текущего персонажа
if player.Character then
    setupCharacterForFlight(player.Character)
end

-- АВТОЗАПУСК Infinity Jump
startInfinityJump()

-- == Стиль UI и иконки ==
local UI_THEME = {
    PanelBg = Color3.fromRGB(16, 14, 24),
    PanelStroke = Color3.fromRGB(95, 70, 160),
    Accent = Color3.fromRGB(148, 0, 211),
    Accent2 = Color3.fromRGB(90, 60, 200),
    Text = Color3.fromRGB(235, 225, 255),
    ButtonOn = Color3.fromRGB(40, 160, 120),
    ButtonOff = Color3.fromRGB(160, 60, 80),
}
local ICONS = {
    Zap = "rbxassetid://7733911822", 
    Eye = "rbxassetid://7733745385", 
    Camera = "rbxassetid://7733871300",
    Jump = "rbxassetid://7733708835" -- Иконка для Infinity Jump
}
local ESP_SETTINGS = { MaxDistance = 500, Font = Enum.Font.GothamBold, Color = Color3.fromRGB(148, 0, 211),
    BgColor = Color3.fromRGB(24, 16, 40), TxtColor = Color3.fromRGB(225, 210, 255), TextSize = 16 }
local OBJECT_EMOJIS = {['La Vacca Saturno Saturnita'] = '🐮', ['Nooo My Hotspot'] = '👽', ['La Supreme Combinasion'] = '🔫',
    ['Ketupat Kepat'] = '⚰️',['Graipuss Medussi'] = '🦑',['Torrtuginni Dragonfrutini'] = '🐢',
    ['Pot Hotspot'] = ' 📱',['La Grande Combinasion'] = '❗️',['Garama and Madundung'] = '🥫',
    ['Secret Lucky Block'] = '⬛️',['Strawberry Elephant'] = '🐘',['Nuclearo Dinossauro'] = '🦕',['Spaghetti Tualetti'] = '🚽',
    ['Chicleteira Bicicleteira'] = '🚲',['Los Combinasionas'] = '⚒️',['Ketchuru and Musturu'] = '🍾',['Los Hotspotsitos'] = '☎️',['Tacorita Bicicleta'] = '🌮',
    ['Los Nooo My Hotspotsitos'] = '🔔',['Esok Sekolah'] = '🏠',['Los Bros'] = '✊',["Tralaledon"] = "🦈",["La Extinct Grande"] = "🦴",["Las Sis"] = "👧",["Los Chicleteiras"] = "🚳",["Celularcini Viciosini"] = "📢",["Dragon Cannelloni"] = "🐉"
}

-- == ОПТИМАЛЬНЫЙ ESP ==
local espCache, esp3DRoot, heartbeatConnection = {}, nil, nil
local camera = workspace.CurrentCamera
local ESP_UPDATE_INTERVAL = 0.25
local MAX_ESP_TARGETS = 24
local lastESPUpdate = 0
local function getRootPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChild('HumanoidRootPart') or obj:FindFirstChildWhichIsA('BasePart')
    end
    return nil
end
local function isValidTarget(obj)
    return OBJECT_EMOJIS[obj.Name] and ((obj:IsA('BasePart')) or (obj:IsA('Model') and getRootPart(obj)))
end
local function clearOldESP()
    for obj,data in pairs(espCache) do
        if not obj or not obj.Parent then if data and data.gui then data.gui:Destroy() end; espCache[obj]=nil end
    end
end
local function createESP(obj)
    local rootPart = getRootPart(obj) if not rootPart then return nil end
    local gui = Instance.new('BillboardGui')
    gui.Adornee = rootPart gui.Size = UDim2.new(0,220,0,30) gui.AlwaysOnTop = true
    gui.MaxDistance = ESP_SETTINGS.MaxDistance gui.LightInfluence = 0 gui.StudsOffset = Vector3.new(0,3,0)
    gui.Parent = esp3DRoot
    local frame = Instance.new('Frame', gui); frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = ESP_SETTINGS.BgColor; frame.BackgroundTransparency = 0.2; frame.BorderSizePixel = 0
    Instance.new('UICorner', frame).CornerRadius = UDim.new(0,8)
    local border = Instance.new('UIStroke', frame)
    border.Color = ESP_SETTINGS.Color; border.Thickness = 1.5
    local textLabel = Instance.new('TextLabel', frame)
    textLabel.Size = UDim2.new(1, -8, 1, -4); textLabel.Position = UDim2.new(0,4,0,2)
    textLabel.BackgroundTransparency = 1; textLabel.TextColor3 = ESP_SETTINGS.TxtColor; textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 16; textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center; textLabel.Text = OBJECT_EMOJIS[obj.Name].." "..obj.Name
    textLabel.TextScaled = true; textLabel.ClipsDescendants = true
    return {gui=gui, rootPart=rootPart}
end
local function updateESP()
    if tick() - lastESPUpdate < ESP_UPDATE_INTERVAL then return end
    lastESPUpdate = tick()
    clearOldESP()
    local candidates = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isValidTarget(obj) then
            local root = getRootPart(obj)
            if root then
                table.insert(candidates, {obj=obj,dist=(root.Position-camera.CFrame.Position).Magnitude})
            end
        end
    end
    table.sort(candidates, function(a,b) return a.dist<b.dist end)
    for i,data in ipairs(candidates) do
        if i > MAX_ESP_TARGETS then break end
        local obj = data.obj
        local root = getRootPart(obj)
        if not espCache[obj] then
            local d = createESP(obj)
            if d then espCache[obj] = d end
        end
        local dat = espCache[obj]
        if dat then
            local _, onScreen = camera:WorldToViewportPoint(root.Position)
            dat.gui.Enabled = onScreen and (data.dist <= ESP_SETTINGS.MaxDistance)
        end
    end
end
local function startESP()
    if not heartbeatConnection then heartbeatConnection = RunService.Heartbeat:Connect(updateESP) end
end
local function stopESP()
    if heartbeatConnection then heartbeatConnection:Disconnect() heartbeatConnection = nil end
    clearOldESP()
end

-- == CAMERAUP ==
local isCameraRaised, cameraFollowConnection = false, nil
local CAMERA_HEIGHT_OFFSET = 20
local function enableFollowCamera()
    if isCameraRaised then return end
    camera.CameraType = Enum.CameraType.Scriptable
    cameraFollowConnection = RunService.RenderStepped:Connect(function()
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild('HumanoidRootPart')
            if hrp then
                local pos = hrp.Position
                camera.CFrame = CFrame.lookAt(pos + Vector3.new(0, CAMERA_HEIGHT_OFFSET, 0), pos)
            end
        end
    end)
    isCameraRaised = true
end
local function disableFollowCamera()
    if not isCameraRaised then return end
    if cameraFollowConnection then cameraFollowConnection:Disconnect() cameraFollowConnection = nil end
    camera.CameraType = Enum.CameraType.Custom isCameraRaised = false
end

-- == FPSDevourer ==
local function removeAllAccessoriesFromCharacter()
    local char = player.Character
    if not char then return end
    for _,item in ipairs(char:GetChildren()) do
        if item:IsA('Accessory') or item:IsA('LayeredClothing') or item:IsA('Shirt')
        or item:IsA('ShirtGraphic') or item:IsA('Pants') or item:IsA('BodyColors') or item:IsA('CharacterMesh') then
            pcall(function() item:Destroy() end)
        end
    end
end
player.CharacterAdded:Connect(function() task.wait(0.2) removeAllAccessoriesFromCharacter() end)
if player.Character then task.defer(removeAllAccessoriesFromCharacter) end
local FPSDevourer = {}
do
    FPSDevourer.running = false
    local TOOL_NAME = 'Bat'
    local function equip() local c=player.Character local b=player:FindFirstChild('Backpack') if not c or not b then return false end local t=b:FindFirstChild(TOOL_NAME) if t then t.Parent=c return true end return false end
    local function unequip() local c=player.Character local b=player:FindFirstChild('Backpack') if not c or not b then return false end local t=c:FindFirstChild(TOOL_NAME) if t then t.Parent=b return true end return false end
    function FPSDevourer:Start()
        if FPSDevourer.running then return end FPSDevourer.running=true; FPSDevourer._stop=false
        task.spawn(function()
            while FPSDevourer.running and not FPSDevourer._stop do equip(); task.wait(0.035); unequip(); task.wait(0.035); end
        end)
    end
    function FPSDevourer:Stop() FPSDevourer.running = false; FPSDevourer._stop = true; unequip() end
    player.CharacterAdded:Connect(function() FPSDevourer.running=false FPSDevourer._stop=true end)
end

-- == UI ==
local uiRoot, sidebar, btnESP, btnCam, btnFreeze, btnJump, btnSelect, btnPlayer, btnTroll
local selectedPlayer = nil
local function makeMenuButton(text, icon, isOn)
    local btn = Instance.new("TextButton")
    btn.Text = "   "..text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.BackgroundColor3 = isOn and UI_THEME.ButtonOn or UI_THEME.ButtonOff
    btn.TextColor3 = UI_THEME.Text
    btn.Size = UDim2.new(1,0,0,36)
    btn.AutoButtonColor = true
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,10)
    local i = Instance.new("ImageLabel",btn)
    i.BackgroundTransparency = 1
    i.Image = icon
    i.Size = UDim2.new(0,18,0,18)
    i.Position = UDim2.new(0,7,0.5,-9)
    i.ImageColor3 = UI_THEME.Text
    i.AnchorPoint = Vector2.new(0,0.5)
    return btn
end
local function buildUI()
    uiRoot = Instance.new('ScreenGui',CoreGui)
    uiRoot.Name = 'PurpleESP_UI'
    uiRoot.ResetOnSpawn = false
    uiRoot.IgnoreGuiInset = true
    uiRoot.DisplayOrder = 1000
    sidebar = Instance.new('Frame', uiRoot)
    sidebar.Size = UDim2.new(0, 220, 0, 308)
    sidebar.AnchorPoint = Vector2.new(1, 0.5)
    sidebar.Position = UDim2.new(1, -12, 0.4, 0)
    sidebar.BackgroundColor3 = UI_THEME.PanelBg
    sidebar.Active = true
    Instance.new('UICorner', sidebar).CornerRadius = UDim.new(0,12)
    local stroke = Instance.new('UIStroke',sidebar)
    stroke.Color = UI_THEME.PanelStroke
    stroke.Thickness = 2
    local grad = Instance.new('UIGradient',sidebar)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, UI_THEME.Accent2),
        ColorSequenceKeypoint.new(0.5, UI_THEME.Accent),
        ColorSequenceKeypoint.new(1, UI_THEME.Accent2)})
    grad.Transparency = NumberSequence.new(0.1)
    grad.Rotation = 35
    grad.Offset = Vector2.new(-1.1,0)
    TweenService:Create(grad,TweenInfo.new(2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Offset=Vector2.new(1.1,0)}):Play()
    local buttonArea = Instance.new('Frame',sidebar)
    buttonArea.BackgroundTransparency = 1
    buttonArea.Position = UDim2.new(0, 10, 0, 38)
    buttonArea.Size = UDim2.new(1, -20, 1, -52)
    local layout = Instance.new("UIListLayout",buttonArea)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0,8)
    btnFreeze = makeMenuButton("Freeze FPS", ICONS.Zap, false) btnFreeze.Name = "FreezeFPS"
    btnESP = makeMenuButton("ESP",ICONS.Eye,true) btnESP.Name = "ESP"
    btnCam = makeMenuButton("CameraUP (R)",ICONS.Camera,false) btnCam.Name = "CameraUP"
    btnJump = makeMenuButton("Infinity Jump",ICONS.Jump,true) btnJump.Name = "InfinityJump" -- ПЕРЕИМЕНОВАНО И ВСЕГДА ВКЛЮЧЕНО
    btnSelect = makeMenuButton("Выбрать игрока","",false) btnSelect.Name = "SelBtn"
    btnPlayer = makeMenuButton("Player: None","",false) btnPlayer.Name = "PlBtn" btnPlayer.Visible = false
    btnTroll = makeMenuButton("Troll Player","",false) btnTroll.Name = "TrollBtn" btnTroll.Visible = false
    btnFreeze.Parent = buttonArea
    btnESP.Parent = buttonArea
    btnCam.Parent = buttonArea
    btnJump.Parent = buttonArea
    btnSelect.Parent = buttonArea
    btnPlayer.Parent = buttonArea
    btnTroll.Parent = buttonArea
    btnESP.MouseButton1Click:Connect(function()
        if heartbeatConnection then stopESP(); btnESP.BackgroundColor3 = UI_THEME.ButtonOff
        else startESP(); btnESP.BackgroundColor3 = UI_THEME.ButtonOn end
    end)
    btnFreeze.MouseButton1Click:Connect(function()
        if FPSDevourer.running then FPSDevourer:Stop() btnFreeze.BackgroundColor3 = UI_THEME.ButtonOff
        else FPSDevourer:Start() btnFreeze.BackgroundColor3 = UI_THEME.ButtonOn end
    end)
    btnCam.MouseButton1Click:Connect(function()
        if isCameraRaised then disableFollowCamera() btnCam.BackgroundColor3 = UI_THEME.ButtonOff
        else enableFollowCamera() btnCam.BackgroundColor3 = UI_THEME.ButtonOn end
        btnCam.Text = "   CameraUP (R)"
    end)
    -- УБРАН обработчик кнопки - Infinity Jump всегда включён
    btnJump.MouseButton1Click:Connect(function()
        -- Ничего не делаем - функция всегда активна
        -- Можно добавить уведомление
        btnJump.Text = "   No Animations!"
        task.wait(1)
        btnJump.Text = "   Infinity Jump"
    end)
    btnSelect.MouseButton1Click:Connect(function()
        local popup = Instance.new("Frame",uiRoot)
        popup.BackgroundColor3 = UI_THEME.PanelBg
        popup.Size = UDim2.new(0, 220, 0, 190)
        popup.Position = UDim2.new(0, 250, 0.5, -95)
        popup.AnchorPoint = Vector2.new(0,0)
        Instance.new("UICorner", popup).CornerRadius = UDim.new(0,9)
        local border = Instance.new("UIStroke", popup)
        border.Color = UI_THEME.PanelStroke
        border.Thickness = 2
        local header = Instance.new("TextLabel", popup)
        header.BackgroundTransparency = 1
        header.Text = "Список игроков"
        header.Font = Enum.Font.GothamBold
        header.TextSize = 16
        header.TextColor3 = UI_THEME.Text
        header.Size = UDim2.new(1, -28, 0, 28)
        header.Position = UDim2.new(0,12,0,0)
        header.TextXAlignment = Enum.TextXAlignment.Left
        local close = Instance.new("TextButton", popup)
        close.Text = "✕"
        close.Font = Enum.Font.GothamBlack
        close.TextSize = 17
        close.Size = UDim2.new(0,26,0,26)
        close.Position = UDim2.new(1, -30, 0, 2)
        close.BackgroundTransparency = 1
        close.TextColor3 = UI_THEME.Accent
        close.AutoButtonColor = true
        close.MouseButton1Click:Connect(function() popup:Destroy() end)
        local scroll = Instance.new("ScrollingFrame", popup)
        scroll.BackgroundTransparency = 1
        scroll.Size = UDim2.new(1, -18, 1, -34)
        scroll.Position = UDim2.new(0,9,0,32)
        scroll.CanvasSize = UDim2.new(0,0,0,0)
        scroll.ScrollBarThickness = 6
        scroll.BottomImage,scroll.TopImage,scroll.MidImage = "","",""
        scroll.BorderSizePixel = 0
        local layout = Instance.new("UIListLayout", scroll)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0,3)
        for _,plr in ipairs(Players:GetPlayers()) do
            local f = Instance.new("Frame",scroll)
            f.BackgroundColor3 = Color3.fromRGB(48,36,72)
            f.Size = UDim2.new(1,0,0,32)
            Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
            local lbl = Instance.new("TextLabel",f)
            lbl.BackgroundTransparency = 1 lbl.Size = UDim2.new(0.66,0,1,0)
            lbl.Position = UDim2.new(0,10,0,0)
            lbl.Text = plr.DisplayName ~= plr.Name and (plr.DisplayName.." ("..plr.Name..")") or plr.Name
            lbl.Font = Enum.Font.Gotham lbl.TextSize = 15
            lbl.TextColor3 = UI_THEME.Text lbl.TextXAlignment=Enum.TextXAlignment.Left
            local sel = Instance.new("TextButton",f)
            sel.Text = "Выбрать"
            sel.Font = Enum.Font.GothamBold
            sel.TextSize = 13
            sel.Size = UDim2.new(0.266,0,0.7,0)
            sel.Position = UDim2.new(0.71,0,0.16,0)
            sel.BackgroundColor3 = UI_THEME.Accent
            sel.TextColor3 = Color3.new(1,1,1)
            sel.AutoButtonColor = true
            Instance.new("UICorner",sel).CornerRadius = UDim.new(0,3)
            sel.MouseButton1Click:Connect(function()
                selectedPlayer = plr
                btnPlayer.Text = "Player: "..plr.Name
                btnPlayer.Visible = true
                btnTroll.Visible = true
                btnSelect.Visible = false
                popup:Destroy()
            end)
        end
        task.wait()
        scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
    end)
    btnPlayer.MouseButton1Click:Connect(function()
        btnSelect.Visible = true
        btnPlayer.Visible = false
        btnTroll.Visible = false
    end)
    btnTroll.MouseButton1Click:Connect(function()
        if not selectedPlayer then return end
        local Event = ReplicatedStorage.Packages.Net["RE/AdminPanelService/ExecuteCommand"]
        local plr = selectedPlayer
        Event:FireServer(plr, "ragdoll")
        task.spawn(function()
            task.wait(4)
            Event:FireServer(plr, "jail")
            task.wait(9.5)
            Event:FireServer(plr, "inverse")
            task.wait(9)
            Event:FireServer(plr, "rocket")
            task.wait(3)
            Event:FireServer(plr, "jumpscare")
        end)
    end)
end
if not CoreGui:FindFirstChild('PurpleESP_3D') then
    esp3DRoot = Instance.new('ScreenGui'); esp3DRoot.Name = 'PurpleESP_3D'; esp3DRoot.Parent=CoreGui; esp3DRoot.ResetOnSpawn=false
else
    esp3DRoot = CoreGui:FindFirstChild('PurpleESP_3D')
end
buildUI()
startESP()

-- == Camera toggle on R ==
UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode==Enum.KeyCode.R then
        if isCameraRaised then disableFollowCamera() btnCam.BackgroundColor3=UI_THEME.ButtonOff
        else enableFollowCamera() btnCam.BackgroundColor3=UI_THEME.ButtonOn end
        btnCam.Text = "   CameraUP (R)"
    end
end)

-- == Быстрый выбор инструментов (Z/X) ==
local function equipToolByName(toolName)
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")
    if not (char and backpack) then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    humanoid:UnequipTools()
    local tool = backpack:FindFirstChild(toolName)
    if tool and tool:IsA("Tool") then
        humanoid:EquipTool(tool)
    end
end
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Z then
        equipToolByName("Invisibility Cloak")
    elseif input.KeyCode == Enum.KeyCode.X then
        equipToolByName("Quantum Cloner")
    end
end)

-- == INPUT TELEPORT BY JOBID (Key T) - Centered & No AutoFocus + AutoTeleport ==
local okTG, TeleportService = pcall(function() return game:GetService("TeleportService") end)
local LocalPlayer = player
-- Переключатель между старыми и новыми API телепорта
local USE_TELEPORT_ASYNC = false -- true для TeleportAsync + TeleportOptions.ServerInstanceId [docs recommend TeleportAsync]
-- Интервал авто-попыток
local ATTEMPT_INTERVAL = 1.5
-- UUID паттерн 8-4-4-4-12
local UUID_PATTERN = "^[%x][%x][%x][%x][%x][%x][%x][%x]%-[%x][%x][%x][%x]%-[%x][%x][%x][%x]%-[%x][%x][%x][%x]%-[%x][%x][%x][%x][%x][%x][%x][%x][%x][%x][%x][%x]$"
local function parsePlaceAndJob(input)
    if type(input) ~= "string" then return nil, nil, "Пустой ввод" end
    local s = input:gsub("^%s+", ""):gsub("%s+$", "")
    local placeStr, jobStr = s:match("TeleportToPlaceInstance%s*%(%s*(%d+)%s*,%s*['\"]([%w%-]+)['\"]")
    if placeStr and jobStr then
        local placeId = tonumber(placeStr)
        if not placeId then return nil, nil, "Некорректный placeId" end
        if not jobStr:match(UUID_PATTERN) then return nil, nil, "Некорректный JobId" end
        return placeId, jobStr, nil
    end
    if s:match(UUID_PATTERN) then
        return tonumber(game.PlaceId), s, nil
    end
    -- Вариант "placeId | jobId"
    local p2, j2 = s:match("^(%d+)%s*[|,;%s]%s*([%w%-]+)$")
    if p2 and j2 and j2:match(UUID_PATTERN) then
        return tonumber(p2), j2, nil
    end
    return nil, nil, "Неверный ввод (ожидается JobId или placeId, JobId)"
end
-- Общая функция одного телепорта
local function teleportOnce(placeId, jobId)
    if not okTG or not TeleportService then
        return false, "TeleportService недоступен"
    end
    local ok, err = pcall(function()
        if USE_TELEPORT_ASYNC then
            local TeleportOptions = Instance.new("TeleportOptions")
            TeleportOptions.ServerInstanceId = jobId -- InstanceId (JobId)
            TeleportService:TeleportAsync(placeId, {LocalPlayer}, TeleportOptions)
        else
            TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
        end
    end)
    if ok then
        return true, nil
    else
        return false, tostring(err)
    end
end
-- Подписка на ошибки и статусы
local lastTeleportStatus = ""
local function setStatus(lbl, txt)
    lastTeleportStatus = txt or ""
    if lbl then lbl.Text = txt or "" end
end
-- Реакция на TeleportInitFailed (по докам можно ретраить) 
if okTG and TeleportService then
    TeleportService.TeleportInitFailed:Connect(function(plr, result, msg, placeId, teleOpts)
        if plr == LocalPlayer then
            lastTeleportStatus = ("TeleportInitFailed: %s"):format(tostring(result))
        end
    end)
end
-- Создание окна
local function safeCreatePrompt()
    local gui = Instance.new("ScreenGui")
    gui.Name = "JobIdTeleportPrompt"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 480, 0, 182)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.BackgroundColor3 = UI_THEME.PanelBg
    frame.Active = true
    frame.ClipsDescendants = true
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = UI_THEME.PanelStroke
    stroke.Thickness = 2
    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.BackgroundTransparency = 1
    header.Text = "Введите ID"
    header.Font = Enum.Font.GothamBold
    header.TextSize = 18
    header.TextColor3 = UI_THEME.Text
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Size = UDim2.new(1, -36, 0, 28)
    header.Position = UDim2.new(0, 12, 0, 10)
    header.Parent = frame
    local close = Instance.new("TextButton")
    close.Text = "✕"
    close.Font = Enum.Font.GothamBlack
    close.TextSize = 18
    close.Size = UDim2.new(0, 26, 0, 26)
    close.Position = UDim2.new(1, -30, 0, 8)
    close.BackgroundTransparency = 1
    close.TextColor3 = UI_THEME.Accent
    close.Parent = frame
    close.MouseButton1Click:Connect(function() gui:Destroy() end)
    local inputRow = Instance.new("Frame")
    inputRow.BackgroundTransparency = 1
    inputRow.Size = UDim2.new(1, -24, 0, 36)
    inputRow.AnchorPoint = Vector2.new(0.5, 0.5)
    inputRow.Position = UDim2.new(0.5, 0, 0.5, -8)
    inputRow.Parent = frame
    local box = Instance.new("TextBox")
    box.Font = Enum.Font.Gotham
    box.PlaceholderText = "Примеры: 123456|job-uuid ... или просто job-uuid"
    box.Text = ""
    box.TextSize = 14
    box.TextColor3 = UI_THEME.Text
    box.BackgroundColor3 = Color3.fromRGB(30, 22, 46)
    box.Size = UDim2.new(1, -150, 0, 32)
    box.AnchorPoint = Vector2.new(0, 0.5)
    box.Position = UDim2.new(0, 12, 0.5, 0)
    box.ClearTextOnFocus = false
    box.Parent = inputRow
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
    local boxStroke = Instance.new("UIStroke", box)
    boxStroke.Color = UI_THEME.Accent2
    boxStroke.Thickness = 1
    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Text = ""
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.TextColor3 = Color3.fromRGB(255, 200, 200)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Size = UDim2.new(1, -24, 0, 20)
    status.Position = UDim2.new(0, 12, 1, -52)
    status.Parent = frame
    -- Кнопка Teleport (многоразовая) — окно не закрываем
    local go = Instance.new("TextButton")
    go.Text = "Teleport"
    go.Font = Enum.Font.GothamBold
    go.TextSize = 15
    go.TextColor3 = Color3.new(1,1,1)
    go.BackgroundColor3 = UI_THEME.Accent
    go.Size = UDim2.new(0, 110, 0, 30)
    go.AnchorPoint = Vector2.new(1, 1)
    go.Position = UDim2.new(1, -12, 1, -10)
    Instance.new("UICorner", go).CornerRadius = UDim.new(0, 8)
    go.Parent = frame
    -- Тумблер AutoTeleport
    local auto = Instance.new("TextButton")
    auto.Text = "AutoTeleport: OFF"
    auto.Font = Enum.Font.GothamBold
    auto.TextSize = 14
    auto.TextColor3 = UI_THEME.Text
    auto.BackgroundColor3 = UI_THEME.ButtonOff
    auto.Size = UDim2.new(0, 140, 0, 30)
    auto.AnchorPoint = Vector2.new(1, 1)
    auto.Position = UDim2.new(1, -134, 1, -10)
    Instance.new("UICorner", auto).CornerRadius = UDim.new(0, 8)
    auto.Parent = frame
    local busy = false
    local autoOn = false
    local autoThread = nil
    local function parseNow()
        local placeId, jobId, err = parsePlaceAndJob(box.Text)
        if err then
            setStatus(status, "Ошибка: "..err)
            return nil, nil
        end
        return placeId, jobId
    end
    local function doTeleport()
        if busy then
            setStatus(status, "Идёт попытка...")
            return
        end
        local placeId, jobId = parseNow()
        if not placeId or not jobId then return end
        busy = true
        setStatus(status, ("Телепорт в %d | %s ..."):format(placeId, jobId))
        local ok, err = teleportOnce(placeId, jobId)
        if ok then
            setStatus(status, "Телепорт вызван, ждём загрузки...")
            -- ВАЖНО: окно НЕ закрываем; оставляем для повторных нажатий
        else
            setStatus(status, "Не удалось: "..tostring(err))
        end
        busy = false
    end
    go.MouseButton1Click:Connect(doTeleport)
    box.FocusLost:Connect(function(enter) if enter then doTeleport() end end)
    local function startAuto()
        if autoOn then return end
        autoOn = true
        auto.Text = "AutoTeleport: ON"
        auto.BackgroundColor3 = UI_THEME.ButtonOn
        setStatus(status, "Автотелепорт включён")
        autoThread = task.spawn(function()
            while autoOn do
                local placeId, jobId = parseNow()
                if placeId and jobId then
                    if not busy then
                        busy = true
                        local ok, err = teleportOnce(placeId, jobId)
                        if ok then
                            setStatus(status, "Авто: вызван телепорт...")
                        else
                            setStatus(status, "Авто: ошибка — "..tostring(err))
                        end
                        busy = false
                    end
                else
                    -- Некорректный ввод — просто ждём
                end
                local t0 = tick()
                while tick() - t0 < ATTEMPT_INTERVAL do
                    if not autoOn then break end
                    RunService.Heartbeat:Wait()
                end
            end
        end)
    end
    local function stopAuto()
        autoOn = false
        auto.Text = "AutoTeleport: OFF"
        auto.BackgroundColor3 = UI_THEME.ButtonOff
        setStatus(status, "Автотелепорт выключен")
        autoThread = nil
    end
    auto.MouseButton1Click:Connect(function()
        if autoOn then stopAuto() else startAuto() end
    end)
    return gui
end
-- Тоггл окна на T
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.T then
        local existing = CoreGui:FindFirstChild("JobIdTeleportPrompt")
        if existing then
            existing.Enabled = not existing.Enabled
        else
            local okP, guiOrErr = pcall(function() return safeCreatePrompt() end)
            if not okP then
                warn("[TeleportPrompt] "..tostring(guiOrErr))
            end
        end
    end
end)

print("🚀 Улучшенный скрипт загружен!")
print("✅ HTTP блокировщик активен")
print("✅ INFINITY JUMP: всегда включен, быстрое падение!")
print("   - Зажимайте ПРОБЕЛ для прыжка вверх (скорость 32)")
print("   - Отпускайте ПРОБЕЛ для БЫСТРОГО падения (скорость -80)")
print("   - ВСЕ АНИМАЦИИ ПОЛНОСТЬЮ ОТКЛЮЧЕНЫ!")
print("✅ ESP, Camera, Freeze, Troll - всё работает")
print("✅ Телепорт по JobID: клавиша T")
print("✅ Быстрый выбор инструментов: Z/X")
