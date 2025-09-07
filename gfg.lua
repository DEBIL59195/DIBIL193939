-- SAFE ANTI-LEAK PROTECTION for Roblox (обход readonly ошибок)
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

-- Безопасная замена с проверкой readonly
local function safe_replace(table, key, new_func)
    local success, error_msg = pcall(function()
        local original = table[key]
        if original ~= new_func then
            table[key] = new_func
        end
    end)
    if success then
        clog('Replaced ' .. tostring(key))
    else
        clog('Failed to replace ' .. tostring(key) .. ' (' .. tostring(error_msg) .. ')')
    end
    return success
end

-- Функция-блокировщик
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

-- Пытаемся заменить основные HTTP функции
if type(G.request) == 'function' then
    safe_replace(G, 'request', block_request)
end

if type(G.http_request) == 'function' then
    safe_replace(G, 'http_request', block_request)
end

if type(G.syn_request) == 'function' then
    safe_replace(G, 'syn_request', block_request)
end

-- Замена во вложенных таблицах (только если они существуют)
pcall(function()
    if G.syn and type(G.syn) == 'table' and type(G.syn.request) == 'function' then
        safe_replace(G.syn, 'request', block_request)
    end
end)

pcall(function()
    if G.http and type(G.http) == 'table' and type(G.http.request) == 'function' then
        safe_replace(G.http, 'request', block_request)
    end
end)

pcall(function()
    if G.fluxus and type(G.fluxus) == 'table' and type(G.fluxus.request) == 'function' then
        safe_replace(G.fluxus, 'request', block_request)
    end
end)

pcall(function()
    if G.krnl and type(G.krnl) == 'table' and type(G.krnl.request) == 'function' then
        safe_replace(G.krnl, 'request', block_request)
    end
end)

-- Альтернативный подход через перехват вызовов
pcall(function()
    -- Создаем прокси-функции вместо прямой замены
    local function create_proxy(original_func, func_name)
        if type(original_func) ~= 'function' then return original_func end
        
        return function(...)
            local args = {...}
            if #args > 0 then
                local url = 'unknown'
                if type(args[1]) == 'table' then
                    url = args[1].Url or args[1].url or tostring(args[1])
                else
                    url = tostring(args[1])
                end
                clog('BLOCKED ' .. func_name .. ': ' .. url)
                return {
                    StatusCode = 200,
                    Success = true,
                    Body = '{"blocked":true}',
                }
            end
            return original_func(...)
        end
    end

    -- Пытаемся создать прокси для основных функций
    if type(G.request) == 'function' then
        G.request = create_proxy(G.request, 'request')
    end
    
    if type(game.HttpGet) == 'function' then
        game.HttpGet = create_proxy(game.HttpGet, 'HttpGet')
    end
    
    if type(game.HttpPost) == 'function' then
        game.HttpPost = create_proxy(game.HttpPost, 'HttpPost')
    end
end)

clog('SAFE PROTECTION ENABLED - HTTP requests blocked where possible')

-- ОСНОВНОЙ СКРИПТ
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
    ['Ketupat Kepat'] = '☕',
    ['Graipuss Medussi'] = '🦑',
    ['Torrtuginni Dragonfrutini'] = '🐢',
    ['Pot Hotspot'] = '📱',
    ['La Grande Combinasion'] = '❗',
    ['Garama and Madundung'] = '🥛',
    ['Secret Lucky Block'] = '❓',
    ['Strawberry Elephant'] = '🐘',
    ['Nuclearo Dinossauro'] = '🦕',
    ['Spaghetti Tualetti'] = '🚽',
    ['Chicleteira Bicicleteira'] = '🚲',
    ['Los Combinasionas'] = '⚡',
    ['Ketchuru and Musturu'] = '🍶',
    ['Los Hotspotsitos'] = '⭐',
    ['Los Nooo My Hotspotsitos'] = '🔄',
    ['Esok Sekolah'] = '🏫',
    ["La Karkerkar Combinsion"] = "💊",
    ["Tralaledon"] = "🐬",
    ["Los Bros"] = "✨"
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
CoordinatesFrame.Position = UDim2.new(0, 10, 0, 100)
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
    end

    statusLabel.Text = '🔍 ESP: ACTIVE | Found: ' .. found
end

-- Функция камеры
local function enableFollowCamera()
    if not isCameraRaised then
        camera.CameraType = Enum.CameraType.Scriptable

        cameraFollowConnection = RunService.RenderStepped:Connect(function()
            local character = player.Character
            if character and character:FindFirstChild('HumanoidRootPart') then
                local humanoidRootPart = character.HumanoidRootPart
                local characterPosition = humanoidRootPart.Position
                
                local cameraOffset = Vector3.new(0, CAMERA_HEIGHT_OFFSET, 15)
                local cameraPosition = characterPosition + cameraOffset
                
                local lookAtPoint = characterPosition + Vector3.new(0, 3, 0)
                
                camera.CFrame = camera.CFrame:Lerp(
                    CFrame.new(cameraPosition, lookAtPoint),
                    0.2
                )
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

-- Исправленная функция координат
local function updateCoordinates()
    local character = player.Character
    if character and character:FindFirstChild('HumanoidRootPart') then
        local humanoidRootPart = character.HumanoidRootPart
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
    else
        CoordinatesLabel.Text = 'Персонаж не найден'
    end
end

-- Обработчики событий
RunService.Heartbeat:Connect(function(dt)
    pcall(function()
        updateESP(dt)
        updateCoordinates()
    end)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    pcall(function()
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
