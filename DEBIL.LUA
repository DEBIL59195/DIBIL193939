local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local HttpService = game:GetService('HttpService')

local INCOME_THRESHOLD = 50_000_000
local DISCORD_WEBHOOK_URL = 'https://discord.com/api/webhooks/1447635318089191555/bECsY5k2x6H8BqLwInok1FwGqZOolgKySzsZ8kkGICumh4GmjfOpk1vmvx7kdh3p1U9S'

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
    ['La Secret Combinasion'] = { emoji = '❓', important = true },
    ['La Kark56656erkar Combinasion'] = { emoji = '🥊', important = false },
    ['Los Bros'] = { emoji = '📱', important = true },
    ['Tralaledon'] = { emoji = '🦈', important = true },
    ['La Extinct Grande'] = { emoji = '🩻', important = true },
    ['Los Hotspotitos'] = { emoji = '📱', important = true },
    ['Las Sis'] = { emoji = '👧', important = true },
    ['Tacorita Bicicleta'] = { emoji = '📱', important = true },
    ['Tictac Sahur'] = { emoji = '🕰️', important = true },
    ['Celularcini Viciosini'] = { emoji = '📞', important = true },
    ['Los Primos'] = { emoji = '🙆‍♂️', important = true },
    ['Tang Tang Keletang'] = { emoji = '📢', important = true },
    ['Money Money Puggy'] = { emoji = '🐶', important = true },
    ['Burguro And Fryuro'] = { emoji = '🍔', important = true },
    ['Chillin Chili'] = { emoji = '🌶', important = true },
    ['Eviledon'] = { emoji = '👹', important = true },
    ['La Spooky Grande'] = { emoji = '🟧', important = true },
    ['Los Mobilis'] = { emoji = '🧕', important = true },
    ['Spooky and Pumpky'] = { emoji = '🎃', important = true, },
    ['Mieteteira Bicicleteira'] = { emoji = '☠️', important = true },
    ['Meowl'] = { emoji = '🐈', important = true },
    ['Chipso and Queso'] = { emoji = '🧀', important = true },
    ['Chipso And Queso'] = { emoji = '🧀', important = true },
    ['La Casa Boo'] = { emoji = '👁‍🗨', important = true },
    ['Headless Horseman'] = { emoji = '🐴', important = true },
    ['Mariachi Corazoni'] = { emoji = '💀', important = true },
    ['La Taco Combinasion'] = { emoji = '👒', important = true },
    ['Capitano Moby'] = { emoji = '🚢', important = true },
    ['Guest 666'] = { emoji = '㊙️', important = true },
    ['Cooki and Milki'] = { emoji = '🍪', important = true },
    ['Los Puggies'] = { emoji = '🦮', important = true },
    ['Fragrama and Chocrama'] = { emoji = '🍫', important = true },
    ['Los Spaghettis'] = { emoji = '🚾', important = true },
    ['Los Tacoritas'] = { emoji = '🚴', important = true },
    ['Orcaledon'] = { emoji = '🐡', important = true },
    ['Lavadorito Spinito'] = { emoji = '📺', important = true },
    ['Los Planitos'] = { emoji = '🪐', important = true },
    ['W or L'] = { emoji = '🟩', important = true },
    ['Fishino Clownino'] = { emoji = '🤡', important = true },
    ['La Ginger Sekolah'] = { emoji = '🎄', important = true },
    ['Christmas Chicleteira'] = { emoji = '🛷', important = true },
    ['La Jolly Grande'] = { emoji = '☃️', important = true },
    ['Ginger'] = { emoji = '🧸', important = true },
}

local ALWAYS_IMPORTANT = {}
for name, cfg in pairs(OBJECTS) do
    if cfg.important then
        ALWAYS_IMPORTANT[name] = true
    end
end

local function parseGenerationText(s)
    if type(s) ~= 'string' or s == '' then
        return nil
    end
    local norm = s:gsub('%$', ''):gsub(',', ''):gsub('%s+', '')
    local num, suffix = norm:match('^([%-%d%.]+)([KkMmBb]?)/s$')
    if not num then
        return nil
    end
    local val = tonumber(num)
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
        return (v % 1 == 0 and string.format('%dB/s', v) or string.format(
            '%.1fB/s',
            v
        )):gsub('%.0B/s', 'B/s')
    elseif n >= 1e6 then
        local v = n / 1e6
        return (v % 1 == 0 and string.format('%dM/s', v) or string.format(
            '%.1fM/s',
            v
        )):gsub('%.0M/s', 'M/s')
    elseif n >= 1e3 then
        local v = n / 1e3
        return (v % 1 == 0 and string.format('%dK/s', v) or string.format(
            '%.1fK/s',
            v
        )):gsub('%.0K/s', 'K/s')
    else
        return string.format('%d/s', n)
    end
end

local function grabText(inst)
    if not inst then
        return nil
    end
    if
        inst:IsA('TextLabel')
        or inst:IsA('TextButton')
        or inst:IsA('TextBox')
    then
        local ok, ct = pcall(function()
            return inst.ContentText
        end)
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
            if
                child:IsA('TextLabel')
                or child:IsA('TextButton')
                or child:IsA('TextBox')
            then
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
                local Overhead = Attachment
                    and Attachment:FindFirstChild('AnimalOverhead')
                if Overhead then
                    local name, genText = getOverheadInfo(Overhead)
                    local genNum = genText and parseGenerationText(genText)
                        or nil
                    if name and genNum then
                        table.insert(
                            results,
                            { name = name, gen = genNum, location = 'Plot' }
                        )
                    end
                end
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
                local genNum = genText and parseGenerationText(genText) or nil
                if name and genNum then
                    table.insert(
                        results,
                        { name = name, gen = genNum, location = 'Runway' }
                    )
                end
            end
        end
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
                local genNum = genText and parseGenerationText(genText) or nil
                if name and genNum then
                    table.insert(
                        results,
                        { name = name, gen = genNum, location = 'World' }
                    )
                end
            end
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
                local name, genText = getOverheadInfo(child)
                local genNum = genText and parseGenerationText(genText) or nil
                if name and genNum then
                    table.insert(
                        results,
                        { name = name, gen = genNum, location = 'GUI' }
                    )
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

local function collectAll(timeoutSec)
    local t0 = os.clock()
    local collected = {}

    repeat
        collected = {}
        local allSources = {
            scanPlots(),
            scanRunway(),
            scanAllOverheads(),
            scanPlayerGui(),
        }

        for _, source in ipairs(allSources) do
            for _, item in ipairs(source) do
                table.insert(collected, item)
            end
        end
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
        return
    end

    local jobId = game.JobId
    local placeId = game.PlaceId

    if #filteredObjects == 0 then
        return
    end

    local important, regular = {}, {}
    for _, obj in ipairs(filteredObjects) do
        if ALWAYS_IMPORTANT[obj.name] then
            table.insert(important, obj)
        else
            table.insert(regular, obj)
        end
    end

    table.sort(important, function(a, b)
        return a.gen > b.gen
    end)
    table.sort(regular, function(a, b)
        return a.gen > b.gen
    end)

    local sorted = {}
    for _, obj in ipairs(important) do
        table.insert(sorted, obj)
    end
    for _, obj in ipairs(regular) do
        table.insert(sorted, obj)
    end

    local objectsList = {}
    for i = 1, math.min(10, #sorted) do
        local obj = sorted[i]
        local emoji = OBJECTS[obj.name].emoji or '💰'
        local mark = ALWAYS_IMPORTANT[obj.name] and '⭐ ' or ''
        table.insert(
            objectsList,
            string.format(
                '%s%s **%s** (%s)',
                mark,
                emoji,
                obj.name,
                formatIncomeNumber(obj.gen)
            )
        )
    end
    local objectsText = table.concat(objectsList, '\n')

    local teleportText = string.format(
        "`local ts = game:GetService('TeleportService'); ts:TeleportToPlaceInstance(%d, '%s')`",
        placeId,
        jobId
    )

    local payload = {
        username = '🎯 Brainrot Scanner',
        embeds = {
            {
                title = '💎 Найдены ценные объекты в Steal a brainrot!',
                color = 0x2f3136,
                fields = {
                    {
                        name = '🆔 Сервер (Job ID)',
                        value = string.format('``````', jobId),
                        inline = false,
                    },
                    {
                        name = '💰 Важные объекты:',
                        value = objectsText,
                        inline = false,
                    },
                    {
                        name = '🚀 Телепорт:',
                        value = teleportText,
                        inline = false,
                    },
                },
                footer = {
                    text = string.format(
                        'Найдено: %d важных • %s',
                        #filteredObjects,
                        os.date('%H:%M:%S')
                    ),
                },
                timestamp = DateTime.now():ToIsoDate(),
            },
        },
    }

    pcall(function()
        return req({
            Url = DISCORD_WEBHOOK_URL,
            Method = 'POST',
            Headers = { ['Content-Type'] = 'application/json' },
            Body = HttpService:JSONEncode(payload),
        })
    end)
end

local function scanAndNotify()
    local allFound = collectAll(8.0)
    local filtered = {}
    for _, obj in ipairs(allFound) do
        if OBJECTS[obj.name] and shouldShow(obj.name, obj.gen) then
            table.insert(filtered, obj)
        end
    end

    if #filtered > 0 then
        sendDiscordNotification(filtered)
    end
end

scanAndNotify()
