local G = (getgenv and getgenv()) or _G

local function clog(msg)
    msg = '[SAFE-BLOCK] ' .. tostring(msg)
    if warn then
        warn(msg)
    else
        print(msg)
    end
    if G.rconsoleprint then
        G.rconsoleprint(msg .. '\n')
    end
end

local function safe_replace(table, key, new_func)
    local success = pcall(function()
        table[key] = new_func
    end)
    if success then
        clog('Replaced ' .. tostring(key))
    else
        clog('Failed to replace ' .. tostring(key) .. ' (readonly)')
    end
    return success
end

local function block_request(opts)
    local url = 'unknown'
    if type(opts) == 'table' then
        url = opts.Url or opts.url or tostring(opts)
    else
        url = tostring(opts)
    end
    clog('BLOCKED: ' .. url)
    return {
        StatusCode = 200,
        Headers = {},
        Body = '{"blocked":true}',
        Success = true,
    }
end

safe_replace(G, 'request', block_request)
safe_replace(G, 'http_request', block_request)
safe_replace(G, 'syn_request', block_request)

pcall(function()
    if G.syn and type(G.syn) == 'table' then
        safe_replace(G.syn, 'request', block_request)
    end
end)

pcall(function()
    if G.http and type(G.http) == 'table' then
        safe_replace(G.http, 'request', block_request)
    end
end)

pcall(function()
    if G.fluxus and type(G.fluxus) == 'table' then
        safe_replace(G.fluxus, 'request', block_request)
    end
end)

pcall(function()
    if G.krnl and type(G.krnl) == 'table' then
        safe_replace(G.krnl, 'request', block_request)
    end
end)

pcall(function()
    local HttpService = game:GetService('HttpService')
    if HttpService then
        HttpService.RequestAsync = function(self, opts)
            clog(
                'BLOCKED HttpService.RequestAsync: '
                    .. tostring(opts.Url or 'unknown')
            )
            return {
                StatusCode = 200,
                Success = true,
                Body = '{"blocked":true}',
            }
        end

        game.HttpGet = function(self, url)
            clog('BLOCKED game:HttpGet: ' .. tostring(url))
            return '{"blocked":true}'
        end

        game.HttpPost = function(self, url, data)
            clog('BLOCKED game:HttpPost: ' .. tostring(url))
            return '{"blocked":true}'
        end
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

local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local CoreGui = game:GetService('CoreGui')

local OBJECT_EMOJIS = {
    ['La Vacca Saturno Saturnita'] = '🐮',
    ['Nooo My Hotspot'] = '👽',
    ['La Supreme Combinasion'] = '🔫',
    ['Ketupat Kepat'] = '⚰️',
    ['Graipuss Medussi'] = '🦑',
    ['Torrtuginni Dragonfrutini'] = '🐢',
    ['Pot Hotspot'] = ' 📱',
    ['La Grande Combinasion'] = '❗️',
    ['Garama and Madundung'] = '🥫',
    ['Secret Lucky Block'] = '⬛️',
    ['Strawberry Elephant'] = '🐘',
    ['Nuclearo Dinossauro'] = '🦕',
    ['Spaghetti Tualetti'] = '🚽',
    ['Chicleteira Bicicleteira'] = '🚲',
    ['Los Combinasionas'] = '⚒️',
    ['Ketchuru and Musturu'] = '🍾',
    ['Los Hotspotsitos'] = '☎️',
    ['Los Nooo My Hotspotsitos'] = '🔔',
    ['Esok Sekolah'] = '🏠',
}

local ESP_SETTINGS = {
    UpdateInterval = 0.2,
    MaxDistance = 500,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    Color = Color3.fromRGB(148, 0, 211),
    BgColor = Color3.fromRGB(24, 16, 40),
    TtxtColor = Color3.fromRGB(225, 210, 255),
}

local camera = workspace.CurrentCamera
local espCache = {}
local screenGui = nil
local statusLabel = nil

local function initializeGUI()
    if not CoreGui:FindFirstChild('PurpleESP') then
        screenGui = Instance.new('ScreenGui')
        screenGui.Name = 'PurpleESP'
        screenGui.Parent = CoreGui
        screenGui.ResetOnSpawn = false
        
        statusLabel = Instance.new('TextLabel')
        statusLabel.Name = 'ESPStatus'
        statusLabel.Text = '🔍 ESP: ACTIVE'
        statusLabel.TextColor3 = ESP_SETTINGS.Color
        statusLabel.TextSize = 18
        statusLabel.Font = ESP_SETTINGS.Font
        statusLabel.BackgroundColor3 = ESP_SETTINGS.BgColor
        statusLabel.BackgroundTransparency = 0.2
        statusLabel.AnchorPoint = Vector2.new(1, 0)
        statusLabel.Position = UDim2.new(1, -10, 0, 10)
        statusLabel.Size = UDim2.new(0, 220, 0, 36)
        statusLabel.TextXAlignment = Enum.TextXAlignment.Right
        statusLabel.Parent = screenGui
    else
        screenGui = CoreGui:FindFirstChild('PurpleESP')
        statusLabel = screenGui:FindFirstChild('ESPStatus')
    end
end

local function clearOldESP()
    for obj, data in pairs(espCache) do
        if not obj or not obj.Parent then
            if data and data.gui then
                data.gui:Destroy()
            end
            espCache[obj] = nil
        end
    end
end

local function getRootPart(obj)
    if obj:IsA('BasePart') then
        return obj
    end
    if obj:IsA('Model') then
        return obj.PrimaryPart
            or obj:FindFirstChild('HumanoidRootPart')
            or obj:FindFirstChildWhichIsA('BasePart')
    end
    return nil
end

local function isValidTarget(obj)
    return OBJECT_EMOJIS[obj.Name] and ((obj:IsA('BasePart')) or (obj:IsA('Model') and getRootPart(obj)))
end

local function createESP(obj)
    local success, result = pcall(function()
        local rootPart = getRootPart(obj)
        if not rootPart then return nil end

        local gui = Instance.new('BillboardGui')
        gui.Adornee = rootPart
        gui.Size = UDim2.new(0, 220, 0, 30)
        gui.AlwaysOnTop = true
        gui.MaxDistance = ESP_SETTINGS.MaxDistance
        gui.LightInfluence = 0
        gui.StudsOffset = Vector3.new(0, 3, 0)
        gui.Parent = screenGui

        local frame = Instance.new('Frame')
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = ESP_SETTINGS.BgColor
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 0
        frame.Parent = gui

        local corner = Instance.new('UICorner')
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame

        local border = Instance.new('UIStroke')
        border.Color = ESP_SETTINGS.Color
        border.Thickness = 1.5
        border.Parent = frame

        local textLabel = Instance.new('TextLabel')
        textLabel.Size = UDim2.new(1, -8, 1, -4)
        textLabel.Position = UDim2.new(0, 4, 0, 2)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = ESP_SETTINGS.TxtColor
        textLabel.Font = ESP_SETTINGS.Font
        textLabel.TextSize = ESP_SETTINGS.TextSize
        textLabel.TextXAlignment = Enum.TextXAlignment.Center
        textLabel.TextYAlignment = Enum.TextYAlignment.Center
        textLabel.Text = OBJECT_EMOJIS[obj.Name] .. ' ' .. obj.Name
        textLabel.TextScaled = true
        textLabel.TextWrapped = false
        textLabel.ClipsDescendants = true
        textLabel.Parent = frame

        return { gui = gui, rootPart = rootPart }
    end)
    
    if not success then
        warn("ESP creation error:", result)
        return nil
    end
    return result
end

local lastUpdate = 0
local function updateESP(dt)
    if not screenGui or not statusLabel then return end
    
    lastUpdate = lastUpdate + dt
    if lastUpdate < ESP_SETTINGS.UpdateInterval then
        return
    end
    lastUpdate = 0
    
    clearOldESP()

    local found = 0

    for _, obj in ipairs(workspace:GetDescendants()) do
        if isValidTarget(obj) then
            local rootPart = getRootPart(obj)
            if rootPart then
                local dist = (rootPart.Position - camera.CFrame.Position).Magnitude
                if dist <= ESP_SETTINGS.MaxDistance then
                    if not espCache[obj] then
                        local espData = createESP(obj)
                        if espData then
                            espCache[obj] = espData
                        end
                    end
                    local espData = espCache[obj]
                    if espData then
                        local _, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                        espData.gui.Enabled = onScreen
                        if onScreen then
                            found = found + 1
                        end
                    end
                else
                    if espCache[obj] then
                        espCache[obj].gui.Enabled = false
                    end
                end
            end
        end
    end

    statusLabel.Text = '🔍 ESP: ACTIVE | Found: ' .. found
end

initializeGUI()

local heartbeatConnection
local playerRemovingConnection

local function startESP()
    if not heartbeatConnection then
        heartbeatConnection = RunService.Heartbeat:Connect(updateESP)
    end
end

local function stopESP()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    clearOldESP()
    if statusLabel then
        statusLabel.Text = '🔍 ESP: INACTIVE'
    end
end

playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
    if player == Players.LocalPlayer then
        stopESP()
        if screenGui then
            screenGui:Destroy()
        end
    end
end)

startESP()
print('🔍 SCALABLE EMOJI ESP loaded!')

local UserInputService = game:GetService('UserInputService')
local player = Players.LocalPlayer

local isCameraRaised = false
local cameraFollowConnection = nil
local CAMERA_HEIGHT_OFFSET = 20

local function enableFollowCamera()
    if not isCameraRaised then
        camera.CameraType = Enum.CameraType.Scriptable
        cameraFollowConnection = RunService.RenderStepped:Connect(function()
            local character = player.Character
            if character then
                local humanoidRootPart =
                    character:FindFirstChild('HumanoidRootPart')
                if humanoidRootPart then
                    local characterPosition = humanoidRootPart.Position
                    local cameraPosition = characterPosition
                        + Vector3.new(0, CAMERA_HEIGHT_OFFSET, 0)
                    camera.CFrame =
                        CFrame.lookAt(cameraPosition, characterPosition)
                end
            end
        end)
        isCameraRaised = true
    end
end

local function disableFollowCamera()
    if isCameraRaised then
        if cameraFollowConnection then
            cameraFollowConnection:Disconnect()
            cameraFollowConnection = nil
        end
        camera.CameraType = Enum.CameraType.Custom
        isCameraRaised = false
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.R then
        if not isCameraRaised then
            enableFollowCamera()
        else
            disableFollowCamera()
        end
    end
end)

return {
    startESP = startESP,
    stopESP = stopESP,
    espSettings = ESP_SETTINGS,
    enableCamera = enableFollowCamera,
    disableCamera = disableFollowCamera,
    blockHTTP = function()
        clog('Manual HTTP blocking triggered')
    end,
}
