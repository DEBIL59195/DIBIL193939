local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local CoreGui = game:GetService('CoreGui')
local UserInputService = game:GetService('UserInputService')

local player = Players.LocalPlayer

-- Настройки ESP
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

-- Настройки камеры и телепорта
local camera = workspace.CurrentCamera
local isCameraRaised = false
local isFrozen = false
local cameraFollowConnection = nil
local MAX_HEIGHT = 500
local CAMERA_HEIGHT_OFFSET = 20
local startingHeight = nil

-- Создание GUI элементов
local screenGui = Instance.new('ScreenGui')
screenGui.Name = 'PurpleESP'
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false

-- Статус ESP
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

-- GUI для координат
local CoordinatesFrame = Instance.new('Frame')
local CoordinatesLabel = Instance.new('TextLabel')

CoordinatesFrame.Parent = screenGui
CoordinatesFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
CoordinatesFrame.BackgroundTransparency = 0.3
CoordinatesFrame.BorderSizePixel = 0
CoordinatesFrame.Size = UDim2.new(0, 220, 0, 80)
CoordinatesFrame.Position = UDim2.new(0, 10, 0, 100) -- Подвинул ниже статуса ESP
CoordinatesFrame.Active = false

local UICorner = Instance.new('UICorner')
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = CoordinatesFrame

CoordinatesLabel.Parent = CoordinatesFrame
CoordinatesLabel.BackgroundTransparency = 1
CoordinatesLabel.Size = UDim2.new(1, 0, 1, 0)
CoordinatesLabel.Font = Enum.Font.Code
CoordinatesLabel.Text = 'X: 0, Y: 0, Z: 0\nВысота: 0'
CoordinatesLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
CoordinatesLabel.TextSize = 12
CoordinatesLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ESP функциональность
local espCache = {}

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

local lastESPUpdate = 0
local function updateESP(dt)
    lastESPUpdate = lastESPUpdate + dt
    if lastESPUpdate < ESP_SETTINGS.UpdateInterval then
        return
    end
    lastESPUpdate = 0
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
                    espCache[obj].gui:Destroy()
                    espCache[obj] = nil
                end
            end
        end
    end

    statusLabel.Text = '🔍 ESP: ACTIVE | Found: ' .. found
end

-- Функции камеры и телепорта
local function enableFollowCamera()
    if not isCameraRaised then
        camera.CameraType = Enum.CameraType.Scriptable

        cameraFollowConnection = RunService.RenderStepped:Connect(function()
            local character = player.Character
            if character then
                local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
                if humanoidRootPart then
                    local characterPosition = humanoidRootPart.Position
                    local cameraPosition = characterPosition + Vector3.new(0, CAMERA_HEIGHT_OFFSET, 0)
                    camera.CFrame = CFrame.lookAt(cameraPosition, characterPosition)
                end
            end
        end)

        isCameraRaised = true
        print('Камера следует за персонажем сверху')
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
        print('Камера возвращена в стандартный режим')
    end
end

local function freezeCharacter()
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
        local humanoid = character:FindFirstChild('Humanoid')

        if humanoidRootPart and humanoid then
            if not isFrozen then
                if not startingHeight then
                    startingHeight = humanoidRootPart.Position.Y
                end

                humanoidRootPart.Anchored = true
                humanoid.WalkSpeed = 0
                humanoid.JumpPower = 0
                humanoid.PlatformStand = true
                isFrozen = true
                print('Персонаж заморожен')
            else
                humanoidRootPart.Anchored = false
                humanoid.WalkSpeed = 16
                humanoid.JumpPower = 50
                humanoid.PlatformStand = false
                isFrozen = false
                print('Персонаж разморожен')
            end
        end
    end
end

local function safeMicroTeleportUp()
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
        if humanoidRootPart then
            local currentPosition = humanoidRootPart.Position

            if startingHeight and (currentPosition.Y - startingHeight) >= MAX_HEIGHT then
                print('Достигнута максимальная высота!')
                return
            end

            local teleportDistance = 0.4
            local targetPosition = currentPosition + Vector3.new(0, teleportDistance, 0)

            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            raycastParams.FilterDescendantsInstances = { character }

            local rayDirection = Vector3.new(0, teleportDistance + 0.5, 0)
            local raycastResult = workspace:Raycast(currentPosition, rayDirection, raycastParams)

            if raycastResult then
                local safePosition = raycastResult.Position - Vector3.new(0, 1, 0)
                if safePosition.Y > currentPosition.Y then
                    humanoidRootPart.CFrame = CFrame.new(
                        safePosition.X,
                        safePosition.Y,
                        safePosition.Z,
                        humanoidRootPart.CFrame.LookVector.X,
                        0,
                        humanoidRootPart.CFrame.LookVector.Z
                    )
                    print('Телепорт до препятствия: +' .. math.floor((safePosition.Y - currentPosition.Y) * 10) / 10)
                else
                    print('Препятствие слишком близко!')
                end
            else
                humanoidRootPart.CFrame = CFrame.new(
                    targetPosition,
                    targetPosition + humanoidRootPart.CFrame.LookVector
                )
                print('Безопасный микро-телепорт: +0.4')
            end
        end
    end
end

-- Обновление координат
local function updateCoordinates()
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
        if humanoidRootPart then
            local pos = humanoidRootPart.Position
            local heightFromStart = startingHeight and (pos.Y - startingHeight) or 0
            local cameraStatus = isCameraRaised and 'Следит' or 'Стандарт'

            CoordinatesLabel.Text = string.format(
                'X: %.1f, Y: %.1f, Z: %.1f\nВысота: %.1f | Камера: %s',
                pos.X,
                pos.Y,
                pos.Z,
                heightFromStart,
                cameraStatus
            )
        end
    else
        CoordinatesLabel.Text = 'Персонаж не найден'
    end
end

-- Обработчики событий
RunService.Heartbeat:Connect(function(dt)
    updateESP(dt)
    updateCoordinates()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Y then
        if not isCameraRaised then
            enableFollowCamera()
        else
            disableFollowCamera()
        end
    end

    if input.KeyCode == Enum.KeyCode.T then
        freezeCharacter()
    end

    if input.KeyCode == Enum.KeyCode.U then
        safeMicroTeleportUp()
    end

    if input.KeyCode == Enum.KeyCode.R then
        local character = player.Character
        if character and character:FindFirstChild('HumanoidRootPart') then
            startingHeight = character.HumanoidRootPart.Position.Y
            print('Начальная высота сброшена')
        end
    end

    if input.KeyCode == Enum.KeyCode.G then
        if CAMERA_HEIGHT_OFFSET == 8 then
            CAMERA_HEIGHT_OFFSET = 15
            print('Высота камеры: 15 studs')
        elseif CAMERA_HEIGHT_OFFSET == 15 then
            CAMERA_HEIGHT_OFFSET = 25
            print('Высота камеры: 25 studs')
        else
            CAMERA_HEIGHT_OFFSET = 8
            print('Высота камеры: 8 studs')
        end
    end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        clearOldESP()
        if cameraFollowConnection then
            cameraFollowConnection:Disconnect()
        end
        if screenGui then
            screenGui:Destroy()
        end
    end
end)

print('🔍 SCALABLE EMOJI ESP + CAMERA CONTROLS loaded!')
print('Y - камера следует сверху, T - заморозка, U - телепорт, R - сброс высоты, G - высота камеры')
