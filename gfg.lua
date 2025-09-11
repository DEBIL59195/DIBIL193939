-- ===== SAFE HTTP BLOCK =====
local G = (getgenv and getgenv()) or _G
local function clog(msg)
    msg = '[SAFE-BLOCK] ' .. tostring(msg)
    if warn then warn(msg) else print(msg) end
    if G.rconsoleprint then G.rconsoleprint(msg .. '\n') end
end
local function safe_replace(tableObj, key, new_func)
    local success = pcall(function() tableObj[key] = new_func end)
    if success then clog('Replaced ' .. tostring(key)) else clog('Failed to replace ' .. tostring(key) .. ' (readonly)') end
    return success
end
local function block_request(opts)
    local url = 'unknown'
    if type(opts) == 'table' then url = opts.Url or opts.url or tostring(opts) else url = tostring(opts) end
    clog('BLOCKED: ' .. url)
    return { StatusCode = 200, Headers = {}, Body = '{"blocked":true}', Success = true }
end
safe_replace(G, 'request', block_request)
safe_replace(G, 'http_request', block_request)
safe_replace(G, 'syn_request', block_request)
pcall(function() if G.syn and type(G.syn) == 'table' then safe_replace(G.syn, 'request', block_request) end end)
pcall(function() if G.http and type(G.http) == 'table' then safe_replace(G.http, 'request', block_request) end end)
pcall(function() if G.fluxus and type(G.fluxus) == 'table' then safe_replace(G.fluxus, 'request', block_request) end end)
pcall(function() if G.krnl and type(G.krnl) == 'table' then safe_replace(G.krnl, 'request', block_request) end end)
pcall(function()
    local HttpService = game:GetService('HttpService')
    if HttpService then
        HttpService.RequestAsync = function(self, opts)
            clog('BLOCKED HttpService.RequestAsync: ' .. tostring(opts.Url or 'unknown'))
            return { StatusCode = 200, Success = true, Body = '{"blocked":true}' }
        end
        game.HttpGet = function(self, url) clog('BLOCKED game:HttpGet: ' .. tostring(url)); return '{"blocked":true}' end
        game.HttpPost = function(self, url, data) clog('BLOCKED game:HttpPost: ' .. tostring(url)); return '{"blocked":true}' end
    end
end)
pcall(function()
    local mt = getmetatable(G) or {}
    local old_index = mt.__index
    mt.__index = function(t, k)
        if k == 'request' or k == 'http_request' or k == 'syn_request' then
            return block_request
        end
        return old_index and old_index(t, k) or rawget(t, k)
    end
    setmetatable(G, mt)
    clog('Metatable protection enabled')
end)
clog('SAFE PROTECTION ENABLED - HTTP requests blocked where possible')

-- ===== SETTINGS & CONSTANTS =====
local Players = game:GetService('Players')
local CoreGui = game:GetService('CoreGui')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')
local player = Players.LocalPlayer

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
}

local ESP_SETTINGS = {
    MaxDistance = 500,
    Font = Enum.Font.GothamBold,
    Color = Color3.fromRGB(148, 0, 211),
    BgColor = Color3.fromRGB(24, 16, 40),
    TxtColor = Color3.fromRGB(225, 210, 255),
    TextSize = 16,
}

local OBJECT_EMOJIS = {
    ['La Vacca Saturno Saturnita'] = '🐮',['Nooo My Hotspot'] = '👽',['La Supreme Combinasion'] = '🔫',['Ketupat Kepat'] = '⚰️',['Graipuss Medussi'] = '🦑',['Torrtuginni Dragonfrutini'] = '🐢',['Pot Hotspot'] = ' 📱',['La Grande Combinasion'] = '❗️',['Garama and Madundung'] = '🥫',['Secret Lucky Block'] = '⬛️',['Strawberry Elephant'] = '🐘',['Nuclearo Dinossauro'] = '🦕',['Spaghetti Tualetti'] = '🚽',['Chicleteira Bicicleteira'] = '🚲',['Los Combinasionas'] = '⚒️',['Ketchuru and Musturu'] = '🍾',['Los Hotspotsitos'] = '☎️',['Los Nooo My Hotspotsitos'] = '🔔',['Esok Sekolah'] = '🏠',
}

-- ESP
local espCache, esp3DRoot, heartbeatConnection = {}, nil, nil
local camera = workspace.CurrentCamera
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
    local rootPart = getRootPart(obj)
    if not rootPart then return nil end
    local gui = Instance.new('BillboardGui')
    gui.Adornee = rootPart
    gui.Size = UDim2.new(0, 220, 0, 30)
    gui.AlwaysOnTop = true
    gui.MaxDistance = ESP_SETTINGS.MaxDistance
    gui.LightInfluence = 0
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.Parent = esp3DRoot
    local frame = Instance.new('Frame', gui); frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = ESP_SETTINGS.BgColor
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    Instance.new('UICorner', frame).CornerRadius = UDim.new(0,8)
    local border = Instance.new('UIStroke', frame)
    border.Color = ESP_SETTINGS.Color border.Thickness = 1.5
    local textLabel = Instance.new('TextLabel', frame)
    textLabel.Size = UDim2.new(1, -8, 1, -4)
    textLabel.Position = UDim2.new(0, 4, 0, 2)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = ESP_SETTINGS.TxtColor
    textLabel.Font = ESP_SETTINGS.Font
    textLabel.TextSize = ESP_SETTINGS.TextSize
    textLabel.TextXAlignment = Enum.TextXAlignment.Center textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Text = OBJECT_EMOJIS[obj.Name].." "..obj.Name
    textLabel.TextScaled = true textLabel.ClipsDescendants = true
    return {gui=gui, rootPart=rootPart}
end
local function updateESP()
    clearOldESP()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isValidTarget(obj) then
            local rootPart = getRootPart(obj)
            if rootPart then
                local dist = (rootPart.Position - camera.CFrame.Position).Magnitude
                if dist <= ESP_SETTINGS.MaxDistance then
                    if not espCache[obj] then
                        local data = createESP(obj)
                        if data then espCache[obj]=data end
                    end
                    local data = espCache[obj]
                    if data then
                        local _, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                        data.gui.Enabled = onScreen
                    end
                elseif espCache[obj] then
                    espCache[obj].gui.Enabled = false
                end
            end
        end
    end
end
local function startESP()
    if not heartbeatConnection then heartbeatConnection = RunService.Heartbeat:Connect(updateESP) end
end
local function stopESP()
    if heartbeatConnection then heartbeatConnection:Disconnect(); heartbeatConnection = nil end
    clearOldESP()
end

-- CAMERA
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

-- FREEZE FPS
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
    local TOOL_NAME = 'Tung Bat'
    local function equip() local c=player.Character local b=player:FindFirstChild('Backpack') if not c or not b then return false end local t=b:FindFirstChild(TOOL_NAME) if t then t.Parent=c return true end return false end
    local function unequip() local c=player.Character local b=player:FindFirstChild('Backpack') if not c or not b then return false end local t=c:FindFirstChild(TOOL_NAME) if t then t.Parent=b return true end return false end
    function FPSDevourer:Start()
        if FPSDevourer.running then return end FPSDevourer.running=true; FPSDevourer._stop=false;
        task.spawn(function()
            while FPSDevourer.running and not FPSDevourer._stop do equip(); task.wait(0.035); unequip(); task.wait(0.035); end
        end)
    end
    function FPSDevourer:Stop() FPSDevourer.running = false; FPSDevourer._stop = true; unequip() end
    player.CharacterAdded:Connect(function() FPSDevourer.running=false FPSDevourer._stop=true end)
end

-- ===== GUI =====
local uiRoot, sidebar, btnESP, btnCam, btnFreeze, minimizeButton, closeButton, grad, btnSelect, btnPlayer, btnTroll
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
    sidebar.Size = UDim2.new(0, 220, 0, 272)
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

    local header = Instance.new('Frame',sidebar)
    header.Size = UDim2.new(1,0,0,32)
    header.BackgroundTransparency = 1
    local titleLabel = Instance.new('TextLabel',header)
    titleLabel.Text = 'Purple ESP'
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = UI_THEME.Text
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1,-68,1,0)
    titleLabel.Position = UDim2.new(0,10,0,0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    minimizeButton = Instance.new('TextButton',header)
    minimizeButton.Text = '⎯'
    minimizeButton.Font = Enum.Font.GothamBlack
    minimizeButton.TextSize = 14
    minimizeButton.TextColor3 = UI_THEME.Text
    minimizeButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    minimizeButton.BackgroundTransparency = 0.5
    minimizeButton.Size = UDim2.new(0, 24, 0, 24)
    minimizeButton.Position = UDim2.new(1, -54, 0.5, -12)
    closeButton = Instance.new('TextButton',header)
    closeButton.Text = '✕'
    closeButton.Font = Enum.Font.GothamBlack
    closeButton.TextSize = 15
    closeButton.TextColor3 = Color3.fromRGB(220, 120, 145)
    closeButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    closeButton.BackgroundTransparency = 0.5
    closeButton.Size = UDim2.new(0, 24, 0, 24)
    closeButton.Position = UDim2.new(1, -26, 0.5, -12)

    local buttonArea = Instance.new('Frame',sidebar)
    buttonArea.BackgroundTransparency = 1
    buttonArea.Position = UDim2.new(0, 10, 0, 38)
    buttonArea.Size = UDim2.new(1, -20, 1, -52)
    local layout = Instance.new("UIListLayout",buttonArea)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0,8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    btnFreeze = makeMenuButton("Freeze FPS", ICONS.Zap, false) btnFreeze.Name = "FreezeFPS"
    btnESP = makeMenuButton("ESP",ICONS.Eye,true) btnESP.Name = "ESP"
    btnCam = makeMenuButton("CameraUP (R)",ICONS.Camera,false) btnCam.Name = "CameraUP"
    btnSelect = makeMenuButton("Выбрать игрока","",false) btnSelect.Name = "SelBtn"
    btnPlayer = makeMenuButton("Player: None","",false) btnPlayer.Name = "PlBtn" btnPlayer.Visible = false
    btnTroll = makeMenuButton("Troll Player","",false) btnTroll.Name = "TrollBtn" btnTroll.Visible = false

    btnFreeze.Parent = buttonArea
    btnESP.Parent = buttonArea
    btnCam.Parent = buttonArea
    btnSelect.Parent = buttonArea
    btnPlayer.Parent = buttonArea
    btnTroll.Parent = buttonArea

    -- actions, drags, minimize, etc. код не изменяется...

    btnESP.MouseButton1Click:Connect(function()
        if heartbeatConnection then
            stopESP()
            btnESP.BackgroundColor3 = UI_THEME.ButtonOff
        else
            startESP()
            btnESP.BackgroundColor3 = UI_THEME.ButtonOn
        end
    end)
    btnFreeze.MouseButton1Click:Connect(function()
        if FPSDevourer.running then
            FPSDevourer:Stop()
            btnFreeze.BackgroundColor3 = UI_THEME.ButtonOff
        else
            FPSDevourer:Start()
            btnFreeze.BackgroundColor3 = UI_THEME.ButtonOn
        end
    end)
    btnCam.MouseButton1Click:Connect(function()
        if isCameraRaised then
            disableFollowCamera()
            btnCam.BackgroundColor3 = UI_THEME.ButtonOff
        else
            enableFollowCamera()
            btnCam.BackgroundColor3 = UI_THEME.ButtonOn
        end
        btnCam.Text = "   CameraUP (R)"
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
        btnSelect.MouseButton1Click:Fire()
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
UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode==Enum.KeyCode.R then
        if isCameraRaised then disableFollowCamera() btnCam.BackgroundColor3=UI_THEME.ButtonOff
        else enableFollowCamera() btnCam.BackgroundColor3=UI_THEME.ButtonOn end
        btnCam.Text = "   CameraUP (R)"
    end
end)
