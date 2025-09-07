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
    ['Pot Hotspot'] = '📱',
    ['La Grande Combinasion'] = '❗',
    ['Garama and Madundung'] = '🥫',
    ['Secret Lucky Block'] = '⬛️',
    ['Strawberry Elephant'] = '🐘',
    ['Nuclearo Dinossauro'] = '🦕',
    ['Spaghetti Tualetti'] = '🚽',
    ['Chicleteira Bicicleteira'] = '🚲',
    ['Los Combinasionas'] = '⚒️',
    ['Ketchuru and Musturu'] = '🍾',
    ['Los Hotspotsitos'] = '☎️',
    ['Los Nooo My Hotspotsitos'] = '🥔',
    ['Esok Sekolah'] = '🏠',
    ["La Karkerkar Combinsion"] = "🥊",
    ["Tralaledon"] = "🦈",
    ["Los Bros"] = "✊"
}

local ESP_SETTINGS = {
    UpdateInterval = 0.2,
    MaxDistance = 500,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    Color = Color3.fromRGB(148, 0, 211),
    BgColor = Color3.fromRGB(24, 16, 40),
    TxtColor = Color3.fromRGB(225, 210, 255),
}

local camera = workspace.CurrentCamera
local espCache = {}

local screenGui = Instance.new('ScreenGui')
screenGui.Name = 'PurpleESP'
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false

local statusLabel = Instance.new('TextLabel')
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

local function clearOldESP()
    for obj, data in pairs(espCache) do
        if not obj or not obj.Parent then
            if data.gui then
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
    return OBJECT_EMOJIS[obj.Name]
        and ((obj:IsA('BasePart')) or (obj:IsA('Model') and getRootPart(obj)))
end

local function createESP(obj)
    local rootPart = getRootPart(obj)
    if not rootPart then
        return
    end

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
end

local lastUpdate = 0
local function updateESP(dt)
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
                    found = found + 1
                end
            else
                if espCache[obj] then
                    espCache[obj].gui.Enabled = false
                end
            end
        end
    end

    statusLabel.Text = '🔍 ESP: ACTIVE | Found: ' .. found
end

RunService.Heartbeat:Connect(updateESP)

Players.PlayerRemoving:Connect(function(player)
    if player == Players.LocalPlayer then
        clearOldESP()
        if screenGui then
            screenGui:Destroy()
        end
    end
end)

print('🔍 SCALABLE EMOJI ESP loaded!')
