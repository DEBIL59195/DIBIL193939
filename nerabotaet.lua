-- == УДАЛЕНИЕ ГРАНИЦ КАРТЫ ==
pcall(function()
    local mapFolder = workspace:FindFirstChild("Map")
    if mapFolder then
        local borders = mapFolder:FindFirstChild("Borders")
        if borders then
            borders:Destroy()
            print("✅ workspace.Map.Borders успешно удалены!")
        else
            warn("⚠️ workspace.Map.Borders не найдены")
        end
    else
        warn("⚠️ workspace.Map не найдена")
    end
end)


-- == РАСШИРЕНИЕ ПЛАТФОРМ ==
local targetColor = Color3.fromRGB(99, 95, 98)
local targetMaterial = Enum.Material.SmoothPlastic
local count = 0

for _, obj in pairs(workspace.Map:GetDescendants()) do
    if obj:IsA("BasePart") then
        -- Проверяем Material, Color и наличие MaterialVariant
        if obj.Material == targetMaterial and obj.Color == targetColor then
            obj.Size = Vector3.new(
                obj.Size.X,
                obj.Size.Y,
                obj.Size.Z * 4
            )
            count = count + 1
            print("Расширен:", obj.Name)
            if obj.MaterialVariant ~= "" then
                print("MaterialVariant:", obj.MaterialVariant)
            end
        end
    end
end

print("Всего расширено:", count)

-- == Гарантированное получение LocalPlayer ==

-- == Безопасный HTTP Block с исключениями ==
local G = (getgenv and getgenv()) or _G

-- Кеш для отслеживания уже залогированных URL
local logged_urls = {}
local log_cooldown = 20  -- Показывать повторное сообщение только раз в 20 секунд

local function clog(msg, url)
    local current_time = tick()

    -- Проверяем, логировали ли мы этот URL недавно
    if url and logged_urls[url] then
        local time_diff = current_time - logged_urls[url]
        if time_diff < log_cooldown then
            return  -- Не логируем, если прошло меньше cooldown секунд
        end
    end

    -- Обновляем время последнего лога
    if url then
        logged_urls[url] = current_time
    end

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

-- Белый список - разрешенные паттерны (не блокируются)
local WHITELIST_PATTERNS = {
    "discord%.com/api/v%d+/channels/%d+/messages",  -- Каналы Discord
    "discordapp%.com/api/v%d+/channels/%d+/messages",
    "discord%.com/api/v%d+/guilds/",  -- API гильдий
    "discord%.com/api/v%d+/users/",    -- API пользователей
    
    -- LuaArmor исключения
    "luarmor%.net",                    -- Основной домен LuaArmor
    "api%.luarmor%.net",               -- API LuaArmor
    "cdn%.luarmor%.net",               -- CDN LuaArmor
    "ads%.luarmor%.net",               -- Рекламный домен LuaArmor
    "docs%.luarmor%.net"               -- Документация LuaArmor
}

local function isWhitelisted(url)
    if type(url) ~= "string" then return false end
    url = url:lower()

    for _, pattern in ipairs(WHITELIST_PATTERNS) do
        if url:match(pattern) then
            return true
        end
    end

    return false
end

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

    -- Проверяем белый список ПЕРВЫМ (приоритет)
    if isWhitelisted(url) then
        clog('ALLOWED (whitelist): ' .. url, url)
        -- Пропускаем запрос, вызываем оригинальную функцию
        if G._original_request then
            return G._original_request(opts)
        else
            return { StatusCode = 200, Headers = {}, Body = '{"allowed":true}', Success = true }
        end
    end

    -- Специальная блокировка Discord webhooks
    if isDiscordWebhook(url) then
        clog('BLOCKED DISCORD WEBHOOK: ' .. url, url)
        return {
            StatusCode = 403,
            Headers = {},
            Body = '{"message":"403: Forbidden","code":50013}',
            Success = false
        }
    end

    clog('BLOCKED: ' .. url, url)
    return { StatusCode = 200, Headers = {}, Body = '{"blocked":true}', Success = true }
end

local function safe_replace(tableObj, key, new_func)
    -- Сохраняем оригинальную функцию
    if not G._original_request and tableObj[key] then
        G._original_request = tableObj[key]
    end

    local succ = pcall(function() tableObj[key] = new_func end)
    if succ then clog('Replaced ' .. tostring(key)) end
    return succ
end

safe_replace(G, 'request', block_request)
safe_replace(G, 'http_request', block_request)
pcall(function() if G.syn then safe_replace(G.syn, 'request', block_request) end end)
pcall(function() if G.http then safe_replace(G.http, 'request', block_request) end end)


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

-- == ФУНКЦИЯ REMOVEPLAYERR (ПОЛНОЕ УДАЛЕНИЕ ВСЕХ ИГРОКОВ ВИЗУАЛЬНО) ==
local removePlayerEnabled = false
local removePlayerConnection = nil

local function removeAllPlayers()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local character = plr.Character
            if character then
                -- Удаляем визуально все части тела
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = 1
                        part.CanCollide = false
                        part.CanQuery = false
                        part.CanTouch = false
                    elseif part:IsA("Decal") or part:IsA("Texture") then
                        part.Transparency = 1
                    elseif part:IsA("Accessory") then
                        local handle = part:FindFirstChild("Handle")
                        if handle then
                            handle.Transparency = 1
                            handle.CanCollide = false
                        end
                    end
                end
            end
        end
    end
end

local function restoreAllPlayers()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local character = plr.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if part.Name ~= "HumanoidRootPart" then
                            part.Transparency = 0
                        else
                            part.Transparency = 1
                        end
                        part.CanCollide = true
                        part.CanQuery = true
                        part.CanTouch = true
                    elseif part:IsA("Decal") or part:IsA("Texture") then
                        part.Transparency = 0
                    elseif part:IsA("Accessory") then
                        local handle = part:FindFirstChild("Handle")
                        if handle then
                            handle.Transparency = 0
                            handle.CanCollide = true
                        end
                    end
                end
            end
        end
    end
end

local function startRemovePlayers()
    if removePlayerConnection then return end
    removePlayerEnabled = true

    -- Постоянное обновление для скрытия игроков
    removePlayerConnection = RunService.RenderStepped:Connect(function()
        if removePlayerEnabled then
            removeAllPlayers()
        end
    end)

    -- Обработка новых игроков
    Players.PlayerAdded:Connect(function(newPlayer)
        if newPlayer ~= player then
            newPlayer.CharacterAdded:Connect(function(character)
                if removePlayerEnabled then
                    task.wait(0.5)
                    removeAllPlayers()
                end
            end)
        end
    end)

    print("✅ RemovePlayer ВКЛЮЧЕН - все игроки скрыты!")
end

local function stopRemovePlayers()
    if removePlayerConnection then
        removePlayerConnection:Disconnect()
        removePlayerConnection = nil
    end
    removePlayerEnabled = false
    restoreAllPlayers()
    print("❌ RemovePlayer ВЫКЛЮЧЕН - игроки восстановлены!")
end

-- == БИНД НА КЛАВИШУ V ДЛЯ REMOVEPLAYER ==
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.G then
        if removePlayerEnabled then
            stopRemovePlayers()
        else
            startRemovePlayers()
        end
    end
end)


-- == ФУНКЦИЯ ПОЛНОГО ОТКЛЮЧЕНИЯ АНИМАЦИЙ ==
local function disableAllAnimations(character)
    local animate = character:FindFirstChild("Animate")
    if animate then
        animate.Disabled = true
        animate:Destroy()
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, animationTrack in pairs(animator:GetPlayingAnimationTracks()) do
                animationTrack:Stop()
                animationTrack:Destroy()
            end
            animator:Destroy()
        end
        
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

local function keepAnimationsDisabled(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, animationTrack in pairs(animator:GetPlayingAnimationTracks()) do
                animationTrack:Stop()
                animationTrack:Destroy()
            end
            animator:Destroy()
        end
    end
    
    local animate = character:FindFirstChild("Animate")
    if animate then
        animate.Disabled = true
        animate:Destroy()
    end
end

-- == СИСТЕМА INFINITY JUMP ==
local infinityJumpEnabled = true
local isSpacePressed = false

local function setupCharacterForFlight(character)
    local humanoid = character:WaitForChild("Humanoid")
    wait(0.1)
    
    disableAllAnimations(character)
    
    humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
end

local function isOnGround(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    local state = humanoid:GetState()
    return state ~= Enum.HumanoidStateType.Freefall and 
           state ~= Enum.HumanoidStateType.Jumping and
           state ~= Enum.HumanoidStateType.Flying and
           humanoid.FloorMaterial ~= Enum.Material.Air
end

local function infinityJump()
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoidRootPart or not humanoid then return end
    
    local moveVector = humanoid.MoveDirection
    local walkSpeed = humanoid.WalkSpeed
    
    local horizontalVelocity = moveVector * walkSpeed
    
    humanoidRootPart.AssemblyLinearVelocity = Vector3.new(
        horizontalVelocity.X,
        32,
        horizontalVelocity.Z
    )
end

local function fall()
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoidRootPart or not humanoid then return end
    
    if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
        humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
    end
    
    local moveVector = humanoid.MoveDirection
    local walkSpeed = humanoid.WalkSpeed
    
    local fastFallSpeed = -80
    
    local horizontalVelocity = moveVector * walkSpeed
    
    humanoidRootPart.AssemblyLinearVelocity = Vector3.new(
        horizontalVelocity.X,
        fastFallSpeed,
        horizontalVelocity.Z
    )
end

local infinityJumpConnection = nil
local function startInfinityJump()
    if infinityJumpConnection then return end
    infinityJumpConnection = RunService.RenderStepped:Connect(function()
        local character = player.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        keepAnimationsDisabled(character)
        
        local onGround = isOnGround(character)
        
        if isSpacePressed then
            infinityJump()
        elseif not onGround then
            fall()
        end
    end)
end

local function stopInfinityJump()
    if infinityJumpConnection then
        infinityJumpConnection:Disconnect()
        infinityJumpConnection = nil
    end
end

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

player.CharacterAdded:Connect(function(character)
    setupCharacterForFlight(character)
    
    task.wait(0.5)
    disableAllAnimations(character)
end)

if player.Character then
    setupCharacterForFlight(player.Character)
end

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
    Jump = "rbxassetid://7733708835"
}
local ESP_SETTINGS = { MaxDistance = 500, Font = Enum.Font.GothamBold, Color = Color3.fromRGB(148, 0, 211),
    BgColor = Color3.fromRGB(24, 16, 40), TxtColor = Color3.fromRGB(225, 210, 255), TextSize = 16 }
local OBJECT_EMOJIS = {['La Vacca Saturno Saturita'] = '🐮', ['Nooo My Hotspot'] = '👽', ['La Supreme Combinasion'] = '🔫',['La Taco Combinasion'] = '👒',['Mariachi Corazoni'] = '💀',['Tacorita Bicicleta'] = '🚵‍♂️',['1x1x1x1'] = '🈯️',['Cooki and Milki'] = '🍪',['Los Puggies'] = '🦮',
    ['Ketupat Kepat'] = '⚰️',['Graipuss Medussi'] = '🦑',['Torrtuginni Dragonfrutini'] = '🐢',['Tictac Sahur'] = '🕰',["Tang Tang Keletang"] = "📢",["Money Money Puggy"] = "🐶",["Los Primos"] = "🙆‍♂️",['Los Tacoritas'] = '🚴',['Guest 666'] = '㊙️',['Fragrama and Chocrama'] = '🍫',
    ['Pot Hotspot'] = ' 📱',['La Grande Combinasion'] = '❗️',['Garama and Madundung'] = '🥫',['La Spooky Grande'] = '🟧',['Spooky and Pumpky'] = '🎃',['La Casa Boo'] = '👁‍🗨',["Burrito Bandito"] = "👮‍♀️",["Capitano Moby"] = "🚢",['Los Spaghettis'] = '🚾',['Los Planitos'] = '🪐',
    ['Secret Lucky Block'] = '⬛️',['Strawberry Elephant'] = '🐘',['Nuclearo Dinossauro'] = '🦕',['Spaghetti Tualetti'] = '🚽',['Meowl'] = '🐈',['Mieteteira Bicicleteira'] = '☠️',['Headless Horseman'] = '🐴',['W or L'] = '🟩',['Fishino Clownino'] = '🤡',['Orcaledon'] = '🐳',
    ['Chicleteira Bicicleteira'] = '🚲',['Los Combinasionas'] = '⚒️',['Ketchuru and Musturu'] = '🍾',['Los Hotspotsitos'] = '☎️',['Tacorita Bicicleta'] = '🌮',["Chillin Chili"] = "🌶",["Eviledon"] = "👹",['Lavadorito Spinito'] = '📺',['W or L'] = '🟩',['Gobblino Uniciclino'] = '🕊',['Celularcini Viciosini'] = '📱',
    ['Los Nooo My Hotspotsitos'] = '🔔',['Esok Sekolah'] = '🏠',['Los Bros'] = '✊',["Tralaledon"] = "🦈",["La Extinct Grande"] = "🦴",["Las Sis"] = "👧",["Los Chicleteiras"] = "🚳",["Celularcini Viciosini"] = "📢",["Dragon Cannelloni"] = "🐉",["La Secret Combinasion"] = "❓",["Burguro And Fryuro"] = "🍔"
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
    local TOOL_NAME = 'Dark Matter Slap'
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

-- == ФУНКЦИЯ ПЕРЕТАСКИВАНИЯ GUI ==
local function makeDraggable(frame)
    local dragging = false
    local dragInput, mousePos, framePos
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)
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
    
    -- ДЕЛАЕМ GUI ПЕРЕТАСКИВАЕМЫМ
    makeDraggable(sidebar)
    
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

    -- === ПРАВИЛЬНЫЕ КНОПКИ УПРАВЛЕНИЯ (СКРЫТИЕ buttonArea) ===

    sidebar.ClipsDescendants = true

    -- Контейнер для кнопок управления
    local windowControls = Instance.new("Frame", sidebar)
    windowControls.Name = "WindowControls"
    windowControls.Size = UDim2.new(0, 70, 0, 30)
    windowControls.Position = UDim2.new(1, -75, 0, 5)
    windowControls.BackgroundTransparency = 1
    windowControls.ZIndex = 25

    -- Кнопка Minimize (желтая)
    local btnMin = Instance.new("TextButton", windowControls)
    btnMin.Name = "BtnMinimize"
    btnMin.Text = "-"
    btnMin.Font = Enum.Font.GothamBold
    btnMin.TextSize = 24
    btnMin.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnMin.BackgroundColor3 = Color3.fromRGB(255, 189, 68)
    btnMin.Size = UDim2.new(0, 28, 0, 28)
    btnMin.Position = UDim2.new(0, 0, 0, 1)
    btnMin.BorderSizePixel = 0
    btnMin.AutoButtonColor = false
    btnMin.ZIndex = 26

    Instance.new("UICorner", btnMin).CornerRadius = UDim.new(1, 0)

    -- Кнопка Close (красная)
    local btnClose = Instance.new("TextButton", windowControls)
    btnClose.Name = "BtnClose"
    btnClose.Text = "X"
    btnClose.Font = Enum.Font.GothamBold
    btnClose.TextSize = 15
    btnClose.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnClose.BackgroundColor3 = Color3.fromRGB(255, 95, 87)
    btnClose.Size = UDim2.new(0, 28, 0, 28)
    btnClose.Position = UDim2.new(0, 35, 0, 1)
    btnClose.BorderSizePixel = 0
    btnClose.AutoButtonColor = false
    btnClose.ZIndex = 26

    Instance.new("UICorner", btnClose).CornerRadius = UDim.new(1, 0)

    -- Переменные
    local isMinimized = false
    local originalSidebarSize = nil

    -- Hover Minimize
    btnMin.MouseEnter:Connect(function()
        TweenService:Create(btnMin, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(255, 210, 100)
        }):Play()
    end)

    btnMin.MouseLeave:Connect(function()
        TweenService:Create(btnMin, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(255, 189, 68)
        }):Play()
    end)

    -- Hover Close
    btnClose.MouseEnter:Connect(function()
        TweenService:Create(btnClose, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(255, 120, 110)
        }):Play()
    end)

    btnClose.MouseLeave:Connect(function()
        TweenService:Create(btnClose, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(255, 95, 87)
        }):Play()
    end)

    local buttonArea = Instance.new('Frame',sidebar)
    buttonArea.BackgroundTransparency = 1
    -- === ФУНКЦИИ СВОРАЧИВАНИЯ И ЗАКРЫТИЯ ===

    -- Сохраняем оригинальный размер ПОСЛЕ создания всего GUI
    task.spawn(function()
        task.wait(0.3)
        originalSidebarSize = sidebar.Size
        print("📏 Размер GUI сохранен:", originalSidebarSize)
    end)

    -- СВОРАЧИВАНИЕ (ПРОСТО СКРЫВАЕМ buttonArea)
    btnMin.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized

        if isMinimized then
            -- Сохраняем размер
            if not originalSidebarSize then
                originalSidebarSize = sidebar.Size
            end

            print("🔽 СВОРАЧИВАЕМ - скрываем buttonArea...")

            -- ПРОСТО СКРЫВАЕМ buttonArea
            buttonArea.Visible = false

            -- Сворачиваем sidebar до 38px
            TweenService:Create(sidebar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 220, 0, 38)
            }):Play()

            btnMin.Text = "+"
            print("✅ GUI свернут - buttonArea скрыт (Visible = false)")

        else
            print("🔼 РАЗВОРАЧИВАЕМ - показываем buttonArea...")

            -- ПОКАЗЫВАЕМ buttonArea
            buttonArea.Visible = true

            -- Разворачиваем sidebar обратно
            if originalSidebarSize then
                TweenService:Create(sidebar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = originalSidebarSize
                }):Play()
            end

            btnMin.Text = "-"
            print("✅ GUI развернут - buttonArea показан (Visible = true)")
        end
    end)

    -- ЗАКРЫТИЕ GUI
    btnClose.MouseButton1Click:Connect(function()
        print("❌ Закрываем GUI...")

        TweenService:Create(sidebar, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()

        task.wait(0.25)

        pcall(function()
            if heartbeatConnection then stopESP() end
        end)
        pcall(function()
            if FPSDevourer and FPSDevourer.running then FPSDevourer:Stop() end
        end)
        pcall(function()
            if isCameraRaised then disableFollowCamera() end
        end)

        pcall(function() uiRoot:Destroy() end)
        pcall(function() if esp3DRoot then esp3DRoot:Destroy() end end)

        print("✅ GUI полностью удален")
    end)

    buttonArea.Position = UDim2.new(0, 10, 0, 38)
    buttonArea.Size = UDim2.new(1, -20, 1, -52)
    local layout = Instance.new("UIListLayout",buttonArea)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0,8)
    btnFreeze = makeMenuButton("Freeze FPS", ICONS.Zap, false) btnFreeze.Name = "FreezeFPS"
    btnESP = makeMenuButton("ESP",ICONS.Eye,true) btnESP.Name = "ESP"
    btnCam = makeMenuButton("CameraUP (R)",ICONS.Camera,false) btnCam.Name = "CameraUP"
    btnJump = makeMenuButton("Infinity Jump",ICONS.Jump,true) btnJump.Name = "InfinityJump"
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
    btnJump.MouseButton1Click:Connect(function()
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
        
        -- ДЕЛАЕМ ПОПАП ПЕРЕТАСКИВАЕМЫМ
        makeDraggable(popup)
        
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

-- == INPUT TELEPORT BY JOBID (Key T) ==
local okTG, TeleportService = pcall(function() return game:GetService("TeleportService") end)
local LocalPlayer = player
local USE_TELEPORT_ASYNC = false
local ATTEMPT_INTERVAL = 1.5
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
    local p2, j2 = s:match("^(%d+)%s*[|,;%s]%s*([%w%-]+)$")
    if p2 and j2 and j2:match(UUID_PATTERN) then
        return tonumber(p2), j2, nil
    end
    return nil, nil, "Неверный ввод (ожидается JobId или placeId, JobId)"
end
local function teleportOnce(placeId, jobId)
    if not okTG or not TeleportService then
        return false, "TeleportService недоступен"
    end
    local ok, err = pcall(function()
        if USE_TELEPORT_ASYNC then
            local TeleportOptions = Instance.new("TeleportOptions")
            TeleportOptions.ServerInstanceId = jobId
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
local lastTeleportStatus = ""
local function setStatus(lbl, txt)
    lastTeleportStatus = txt or ""
    if lbl then lbl.Text = txt or "" end
end
if okTG and TeleportService then
    TeleportService.TeleportInitFailed:Connect(function(plr, result, msg, placeId, teleOpts)
        if plr == LocalPlayer then
            lastTeleportStatus = ("TeleportInitFailed: %s"):format(tostring(result))
        end
    end)
end
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
    
    -- ДЕЛАЕМ ОКНО ТЕЛЕПОРТА ПЕРЕТАСКИВАЕМЫМ
    makeDraggable(frame)
    
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
print("✅ GUI теперь можно перетаскивать!")

-- == ДОБАВЛЕННЫЙ ВТОРОЙ СКРИПТ ==
local RunService = game:GetService("RunService")
local highlightedObjects = {}

local function createBeautifulPurpleRemainingTime()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "RemainingTime" and obj.Parent and obj.Parent:IsA("BillboardGui") then
            local billboardGui = obj.Parent
            local remainingTimeLabel = obj
            
            if not highlightedObjects[billboardGui] then
                billboardGui.MaxDistance = math.huge
                billboardGui.AlwaysOnTop = true
                billboardGui.Size = UDim2.new(12, 0, 6, 0)
                billboardGui.StudsOffset = Vector3.new(0, 3, 0)
                billboardGui.LightInfluence = 0
                
                if remainingTimeLabel:IsA("TextLabel") then
                    remainingTimeLabel.Size = UDim2.new(1, 0, 1, 0)
                    remainingTimeLabel.BackgroundTransparency = 1
                    remainingTimeLabel.TextScaled = true
                    remainingTimeLabel.RichText = true
                    remainingTimeLabel.Font = Enum.Font.GothamBold
                    
                    remainingTimeLabel.TextColor3 = Color3.new(0.8, 0.4, 1)
                    remainingTimeLabel.TextStrokeTransparency = 0
                    remainingTimeLabel.TextStrokeColor3 = Color3.new(0.3, 0, 0.6)
                    
                    local constraint = remainingTimeLabel:FindFirstChild("UITextSizeConstraint")
                    if constraint then
                        constraint:Destroy()
                    end
                    
                    local newConstraint = Instance.new("UITextSizeConstraint")
                    newConstraint.MaxTextSize = 600
                    newConstraint.MinTextSize = 250
                    newConstraint.Parent = remainingTimeLabel
                    
                    local gradient = Instance.new("UIGradient")
                    gradient.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.new(1, 0.5, 1)),
                        ColorSequenceKeypoint.new(0.5, Color3.new(0.8, 0.3, 1)),
                        ColorSequenceKeypoint.new(1, Color3.new(0.5, 0, 0.8))
                    }
                    gradient.Rotation = 90
                    gradient.Parent = remainingTimeLabel
                end
                
                local highlight = Instance.new("Highlight")
                highlight.Name = "RemainingTimeHighlight"
                highlight.FillColor = Color3.new(0.7, 0.2, 1)
                highlight.FillTransparency = 0.4
                highlight.OutlineColor = Color3.new(1, 0.8, 1)
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Adornee = billboardGui
                highlight.Parent = billboardGui
                
                highlightedObjects[billboardGui] = true
                print("Создан красивый фиолетовый RemainingTime:", billboardGui:GetFullName())
            end
        end
    end
end

createBeautifulPurpleRemainingTime()

workspace.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "RemainingTime" then
        wait(0.2)
        createBeautifulPurpleRemainingTime()
    end
end)
