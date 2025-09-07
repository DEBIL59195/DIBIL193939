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
-- SAFE ANTI-LEAK PROTECTION for Roblox (Ð¾Ð±ÑÐ¾Ð´ readonly Ð¾ÑÐ¸Ð±Ð¾Ðº)
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

-- ÐÐµÐ·Ð¾Ð¿Ð°ÑÐ½Ð°Ñ Ð·Ð°Ð¼ÐµÐ½Ð° Ñ Ð¿ÑÐ¾Ð²ÐµÑÐºÐ¾Ð¹ readonly
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

-- Ð¤ÑÐ½ÐºÑÐ¸Ñ-Ð±Ð»Ð¾ÐºÐ¸ÑÐ¾Ð²ÑÐ¸Ðº
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

-- ÐÐ¾Ð¿ÑÑÐºÐ° Ð·Ð°Ð¼ÐµÐ½Ñ Ð¾ÑÐ½Ð¾Ð²Ð½ÑÑ HTTP ÑÑÐ½ÐºÑÐ¸Ð¹
safe_replace(G, 'request', block_request)
safe_replace(G, 'http_request', block_request)
safe_replace(G, 'syn_request', block_request)

-- ÐÐ°Ð¼ÐµÐ½Ð° Ð²Ð¾ Ð²Ð»Ð¾Ð¶ÐµÐ½Ð½ÑÑ ÑÐ°Ð±Ð»Ð¸ÑÐ°Ñ
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

-- ÐÐ»Ð¾ÐºÐ¸ÑÐ¾Ð²ÐºÐ° Roblox Ð²ÑÑÑÐ¾ÐµÐ½Ð½ÑÑ ÑÑÐ½ÐºÑÐ¸Ð¹ (Ð¾Ð½Ð¸ Ð¾Ð±ÑÑÐ½Ð¾ Ð½Ðµ readonly)
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

-- ÐÐ¾Ð¿Ð¾Ð»Ð½Ð¸ÑÐµÐ»ÑÐ½Ð°Ñ Ð·Ð°ÑÐ¸ÑÐ° ÑÐµÑÐµÐ· Ð¼ÐµÑÐ°ÑÐ°Ð±Ð»Ð¸ÑÑ
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
-- Скрипт для Executor с координатами, проверкой стен, ограничением высоты и камерой выше персонажа

local camera = workspace.CurrentCamera
local UserInputService = game:GetService('UserInputService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local player = Players.LocalPlayer

-- Переменные для отслеживания состояний
local isCameraRaised = false
local originalCFrame = nil
local isFrozen = false
local cameraFollowConnection = nil

-- Максимальная высота от земли (можете изменить это значение)
local MAX_HEIGHT = 500 -- Максимум 500 studs от начальной позиции
local CAMERA_HEIGHT_OFFSET = 20 -- На сколько studs камера выше персонажа

-- Создание GUI для координат
local ScreenGui = Instance.new('ScreenGui')
local CoordinatesFrame = Instance.new('Frame')
local CoordinatesLabel = Instance.new('TextLabel')

ScreenGui.Name = 'CoordinatesGUI'
ScreenGui.Parent = player:WaitForChild('PlayerGui')
ScreenGui.ResetOnSpawn = false

-- Настройка рамки для координат в левом верхнем углу
CoordinatesFrame.Parent = ScreenGui
CoordinatesFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
CoordinatesFrame.BackgroundTransparency = 0.3
CoordinatesFrame.BorderSizePixel = 0
CoordinatesFrame.Size = UDim2.new(0, 220, 0, 80)
CoordinatesFrame.Position = UDim2.new(0, 10, 0, 10)
CoordinatesFrame.Active = false

-- Добавляем скругленные углы
local UICorner = Instance.new('UICorner')
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = CoordinatesFrame

-- Настройка текста координат
CoordinatesLabel.Parent = CoordinatesFrame
CoordinatesLabel.BackgroundTransparency = 1
CoordinatesLabel.Size = UDim2.new(1, 0, 1, 0)
CoordinatesLabel.Font = Enum.Font.Code
CoordinatesLabel.Text = 'X: 0, Y: 0, Z: 0\nВысота: 0'
CoordinatesLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
CoordinatesLabel.TextSize = 12
CoordinatesLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Переменные для отслеживания начальной позиции
local startingHeight = nil

-- Функция для включения камеры выше персонажа
local function enableFollowCamera()
    if not isCameraRaised then
        -- Устанавливаем камеру в режим Scriptable для полного контроля
        camera.CameraType = Enum.CameraType.Scriptable

        -- Создаем соединение для постоянного обновления позиции камеры
        cameraFollowConnection = RunService.RenderStepped:Connect(function()
            local character = player.Character
            if character then
                local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
                if humanoidRootPart then
                    -- Позиция камеры выше персонажа
                    local characterPosition = humanoidRootPart.Position
                    local cameraPosition = characterPosition + Vector3.new(0, CAMERA_HEIGHT_OFFSET, 0)

                    -- Камера смотрит на персонажа сверху под небольшим углом
                    local lookDirection = (characterPosition - cameraPosition).Unit
                    camera.CFrame = CFrame.lookAt(cameraPosition, characterPosition)
                end
            end
        end)

        isCameraRaised = true
        print('Камера следует за персонажем сверху')
    end
end

-- Функция для возврата камеры в исходное состояние
local function disableFollowCamera()
    if isCameraRaised then
        -- Отключаем следование камеры
        if cameraFollowConnection then
            cameraFollowConnection:Disconnect()
            cameraFollowConnection = nil
        end

        -- Возвращаем камеру в режим Custom (стандартный)
        camera.CameraType = Enum.CameraType.Custom

        isCameraRaised = false
        print('Камера возвращена в стандартный режим')
    end
end

-- Функция заморозки персонажа
local function freezeCharacter()
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
        local humanoid = character:FindFirstChild('Humanoid')

        if humanoidRootPart and humanoid then
            if not isFrozen then
                -- Сохраняем начальную высоту при первой заморозке
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

-- Функция безопасного микро-телепорта вверх с проверкой стен и высоты
local function safeMicroTeleportUp()
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
        if humanoidRootPart then
            local currentPosition = humanoidRootPart.Position

            -- Проверяем максимальную высоту
            if startingHeight and (currentPosition.Y - startingHeight) >= MAX_HEIGHT then
                print('Достигнута максимальная высота!')
                return
            end

            -- Дистанция телепорта (очень маленькая для обхода античитов)
            local teleportDistance = 0.4
            local targetPosition = currentPosition + Vector3.new(0, teleportDistance, 0)

            -- Настройка Raycast параметров
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            raycastParams.FilterDescendantsInstances = { character }

            -- Проверяем путь вверх на наличие препятствий
            local rayDirection = Vector3.new(0, teleportDistance + 0.5, 0)
            local raycastResult = workspace:Raycast(currentPosition, rayDirection, raycastParams)

            if raycastResult then
                -- Есть препятствие, телепортируемся только до него
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
                -- Путь свободен, можем телепортироваться
                humanoidRootPart.CFrame = CFrame.new(
                    targetPosition,
                    targetPosition + humanoidRootPart.CFrame.LookVector
                )
                print('Безопасный микро-телепорт: +0.4')
            end
        end
    end
end

-- Обновление координат и высоты в реальном времени
RunService.Heartbeat:Connect(function()
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
end)

-- Обработчик нажатия клавиш
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    -- Клавиша Y - включить/выключить камеру следования сверху
    if input.KeyCode == Enum.KeyCode.Y then
        if not isCameraRaised then
            enableFollowCamera()
        else
            disableFollowCamera()
        end
    end

    -- Клавиша T - заморозка персонажа
    if input.KeyCode == Enum.KeyCode.T then
        freezeCharacter()
    end

    -- Клавиша U - безопасный микро-телепорт вверх
    if input.KeyCode == Enum.KeyCode.U then
        safeMicroTeleportUp()
    end

    -- Клавиша R - сброс максимальной высоты
    if input.KeyCode == Enum.KeyCode.R then
        local character = player.Character
        if character and character:FindFirstChild('HumanoidRootPart') then
            startingHeight = character.HumanoidRootPart.Position.Y
            print('Начальная высота сброшена')
        end
    end

    -- Клавиша G - изменить высоту камеры (для настройки)
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

print('Скрипт загружен! Y - камера следует сверху, T - заморозка, U - телепорт, R - сброс высоты, G - высота камеры')
