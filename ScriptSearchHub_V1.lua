-- Script Search Hub V1
-- ScriptBlox + RScripts
-- Mobile / Luau
--
-- Configure CONFIG.RScriptsAPIKey before using RScripts.
-- This version provides search, game/universal modes, source tabs,
-- metadata tags, details, RAW viewing/copying, pagination-ready state,
-- cache, and independent API error handling.

local CONFIG = {
    RScriptsAPIKey = "COLOQUE_SUA_API_KEY_AQUI",
    ScriptBloxBase = "https://scriptblox.com/api",
    RScriptsBase = "https://api.rscripts.net",
    RequestTimeout = 15,
    ResultsPerPage = 10,
    CacheEnabled = true,
    CacheTime = 30
}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function GetRequestFunction()
    if typeof(request) == "function" then return request end
    if typeof(http_request) == "function" then return http_request end
    if syn and typeof(syn.request) == "function" then return syn.request end
    return nil
end

local RequestFunction = GetRequestFunction()

local function HTTPRequest(url, method, headers)
    if not RequestFunction then
        return false, "Nenhuma função HTTP disponível."
    end

    local ok, result = pcall(function()
        return RequestFunction({
            Url = url,
            Method = method or "GET",
            Headers = headers or {}
        })
    end)

    if not ok then return false, tostring(result) end
    if not result then return false, "Resposta vazia." end

    local status = tonumber(result.StatusCode) or 0
    if status < 200 or status >= 300 then
        return false, "HTTP " .. tostring(status) .. ": " ..
            tostring(result.StatusMessage or "")
    end

    return true, result.Body
end

local function DecodeJSON(body)
    local ok, result = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if not ok then return false, "JSON inválido." end
    return true, result
end

local function Encode(value)
    return HttpService:UrlEncode(tostring(value))
end

local Cache = {}

local function GetCache(key)
    if not CONFIG.CacheEnabled then return nil end
    local item = Cache[key]
    if not item then return nil end

    if os.clock() - item.time > CONFIG.CacheTime then
        Cache[key] = nil
        return nil
    end

    return item.data
end

local function SetCache(key, data)
    if not CONFIG.CacheEnabled then return end
    Cache[key] = { time = os.clock(), data = data }
end

local function ClearCache()
    table.clear(Cache)
end

local function NormalizeScript(source, data)
    local result = {
        Source = source,
        Id = data.id,
        Title = data.title or "Sem título",
        Slug = data.slug,
        Description = data.description,
        Game = "",
        PlaceId = nil,
        Universal = nil,
        Key = "Unknown",
        Verified = nil,
        Patched = nil,
        MobileReady = nil,
        Paid = nil,
        Views = tonumber(data.views) or 0,
        Likes = tonumber(data.likes) or 0,
        Dislikes = tonumber(data.dislikes) or 0,
        RawURL = data.rawScript,
        Code = data.script,
        ScriptURL = nil,
        Risk = nil,
        Creator = nil,
        Executors = data.executors
    }

    if data.game then
        result.Game = data.game.title or ""
        result.PlaceId = tonumber(data.game.placeId) or data.game.placeId
        result.GameURL = data.game.robloxUrl
        result.Thumbnail = data.game.thumbnailUrl
        result.Logo = data.game.logoUrl
    end

    if data.isUniversal ~= nil then
        result.Universal = data.isUniversal
    end

    if data.isKeySystem ~= nil then
        result.Key = data.isKeySystem and "Yes" or "No"
    elseif data.key ~= nil then
        result.Key = data.key and "Yes" or "No"
    end

    if data.verified ~= nil then
        result.Verified = data.verified
    elseif data.creator and data.creator.isVerified ~= nil then
        result.Verified = data.creator.isVerified
    end

    if data.isPatched ~= nil then result.Patched = data.isPatched end
    if data.isMobileReady ~= nil then result.MobileReady = data.isMobileReady end
    if data.isPaid ~= nil then result.Paid = data.isPaid end

    if data.risk then
        result.Risk = {
            Score = data.risk.score,
            Level = data.risk.level,
            Obfuscated = data.risk.isObfuscated
        }
    end

    if data.creator then
        result.Creator = {
            Username = data.creator.username,
            Verified = data.creator.isVerified,
            Pro = data.creator.isPro
        }
    end

    return result
end

local ScriptBlox = {}

function ScriptBlox.Search(query, page)
    page = page or 1
    local cacheKey = "SB_SEARCH|" .. query .. "|" .. page
    local cached = GetCache(cacheKey)
    if cached then return true, cached end

    local url = CONFIG.ScriptBloxBase .. "/script/search?q=" ..
        Encode(query) .. "&page=" .. tostring(page)

    local ok, body = HTTPRequest(url)
    if not ok then return false, body end

    local decoded, data = DecodeJSON(body)
    if not decoded then return false, data end

    local results = {}
    local scripts = {}

    if data.result and data.result.scripts then
        scripts = data.result.scripts
    elseif data.scripts then
        scripts = data.scripts
    end

    for _, scriptData in ipairs(scripts) do
        table.insert(results, NormalizeScript("ScriptBlox", scriptData))
    end

    local output = { Results = results, Raw = data }
    SetCache(cacheKey, output)
    return true, output
end

function ScriptBlox.SearchPlace(placeId, page)
    page = page or 1
    local cacheKey = "SB_PLACE|" .. tostring(placeId) .. "|" .. tostring(page)
    local cached = GetCache(cacheKey)
    if cached then return true, cached end

    local url = CONFIG.ScriptBloxBase .. "/script/search?placeId=" ..
        Encode(placeId) .. "&page=" .. tostring(page)

    local ok, body = HTTPRequest(url)
    if not ok then return false, body end

    local decoded, data = DecodeJSON(body)
    if not decoded then return false, data end

    local results = {}
    local scripts = data.result and data.result.scripts or {}

    for _, scriptData in ipairs(scripts) do
        table.insert(results, NormalizeScript("ScriptBlox", scriptData))
    end

    local output = { Results = results, Raw = data }
    SetCache(cacheKey, output)
    return true, output
end

function ScriptBlox.SearchUniversal(page)
    page = page or 1
    local cacheKey = "SB_UNIVERSAL|" .. tostring(page)
    local cached = GetCache(cacheKey)
    if cached then return true, cached end

    local url = CONFIG.ScriptBloxBase .. "/script/fetch?universal=1&page=" ..
        tostring(page)

    local ok, body = HTTPRequest(url)
    if not ok then return false, body end

    local decoded, data = DecodeJSON(body)
    if not decoded then return false, data end

    local results = {}
    local scripts = {}

    if data.result and data.result.scripts then
        scripts = data.result.scripts
    elseif data.scripts then
        scripts = data.scripts
    end

    for _, scriptData in ipairs(scripts) do
        table.insert(results, NormalizeScript("ScriptBlox", scriptData))
    end

    local output = { Results = results, Raw = data }
    SetCache(cacheKey, output)
    return true, output
end

local RScripts = {}

local function RScriptsHeaders()
    return {
        ["Authorization"] = "Bearer " .. tostring(CONFIG.RScriptsAPIKey),
        ["Accept"] = "application/json"
    }
end

local function HasRScriptsKey()
    return CONFIG.RScriptsAPIKey ~= "" and
        CONFIG.RScriptsAPIKey ~= "COLOQUE_SUA_API_KEY_AQUI"
end

function RScripts.Search(query, page)
    page = page or 1
    if not HasRScriptsKey() then
        return false, "Configure a API Key do RScripts."
    end

    local cacheKey = "RS_SEARCH|" .. query .. "|" .. tostring(page)
    local cached = GetCache(cacheKey)
    if cached then return true, cached end

    local url = CONFIG.RScriptsBase .. "/v1/search?q=" ..
        Encode(query) .. "&index=scripts&limit=" ..
        tostring(CONFIG.ResultsPerPage) .. "&page=" .. tostring(page)

    local ok, body = HTTPRequest(url, "GET", RScriptsHeaders())
    if not ok then return false, body end

    local decoded, data = DecodeJSON(body)
    if not decoded then return false, data end

    if data.success == false then
        return false, data.error and data.error.message or
            "Erro da API RScripts."
    end

    local results = {}
    local scripts = data.data and data.data.scripts or {}

    for _, scriptData in ipairs(scripts) do
        table.insert(results, NormalizeScript("RScripts", scriptData))
    end

    local output = { Results = results, Raw = data }
    SetCache(cacheKey, output)
    return true, output
end

function RScripts.SearchPlace(placeId, page)
    page = page or 1
    if not HasRScriptsKey() then
        return false, "Configure a API Key do RScripts."
    end

    local cacheKey = "RS_PLACE|" .. tostring(placeId) .. "|" .. tostring(page)
    local cached = GetCache(cacheKey)
    if cached then return true, cached end

    local url = CONFIG.RScriptsBase .. "/v1/scripts?placeId=" ..
        Encode(placeId) .. "&limit=" ..
        tostring(CONFIG.ResultsPerPage) .. "&page=" .. tostring(page)

    local ok, body = HTTPRequest(url, "GET", RScriptsHeaders())
    if not ok then return false, body end

    local decoded, data = DecodeJSON(body)
    if not decoded then return false, data end

    if data.success == false then
        return false, data.error and data.error.message or
            "Erro da API RScripts."
    end

    local results = {}
    local scripts = data.data or {}

    for _, scriptData in ipairs(scripts) do
        table.insert(results, NormalizeScript("RScripts", scriptData))
    end

    local output = { Results = results, Raw = data }
    SetCache(cacheKey, output)
    return true, output
end

function RScripts.SearchUniversal(page)
    return RScripts.Search("universal", page)
end

function RScripts.GetDetails(slug)
    if not HasRScriptsKey() then
        return false, "Configure a API Key do RScripts."
    end

    local url = CONFIG.RScriptsBase .. "/v1/scripts/" .. Encode(slug)
    local ok, body = HTTPRequest(url, "GET", RScriptsHeaders())
    if not ok then return false, body end

    local decoded, data = DecodeJSON(body)
    if not decoded then return false, data end

    if data.success == false then
        return false, data.error and data.error.message or
            "Erro ao obter detalhes."
    end

    if data.data then
        return true, NormalizeScript("RScripts", data.data)
    end

    return false, "Dados do script não encontrados."
end

local function New(class, properties)
    local object = Instance.new(class)
    for property, value in pairs(properties or {}) do
        pcall(function() object[property] = value end)
    end
    return object
end

local function AddCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = object
    return corner
end

local function AddStroke(object)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Transparency = 0.75
    stroke.Parent = object
    return stroke
end

local Existing = CoreGui:FindFirstChild("ScriptSearchHub")
if Existing then Existing:Destroy() end

local ScreenGui = New("ScreenGui", {
    Name = "ScriptSearchHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Main = New("Frame", {
    Parent = ScreenGui,
    Size = UDim2.fromOffset(380, 500),
    Position = UDim2.new(0.5, -190, 0.5, -250),
    BackgroundColor3 = Color3.fromRGB(13, 13, 16),
    BorderSizePixel = 0
})
AddCorner(Main, 12)
AddStroke(Main)

local Top = New("Frame", {
    Parent = Main,
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = Color3.fromRGB(19, 19, 23),
    BorderSizePixel = 0
})
AddCorner(Top, 12)

New("TextLabel", {
    Parent = Top,
    Size = UDim2.new(1, -60, 1, 0),
    Position = UDim2.fromOffset(14, 0),
    BackgroundTransparency = 1,
    Text = "🔎 Script Search Hub",
    TextColor3 = Color3.fromRGB(240, 240, 245),
    TextSize = 17,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
})

local Close = New("TextButton", {
    Parent = Top,
    Size = UDim2.fromOffset(38, 32),
    Position = UDim2.new(1, -44, 0, 8),
    BackgroundColor3 = Color3.fromRGB(35, 35, 40),
    Text = "×",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0
})
AddCorner(Close, 8)

local SearchBox = New("TextBox", {
    Parent = Main,
    Size = UDim2.new(1, -100, 0, 38),
    Position = UDim2.fromOffset(14, 60),
    BackgroundColor3 = Color3.fromRGB(24, 24, 29),
    BorderSizePixel = 0,
    PlaceholderText = "Pesquisar script ou jogo...",
    PlaceholderColor3 = Color3.fromRGB(130, 130, 140),
    Text = "",
    TextColor3 = Color3.fromRGB(240, 240, 245),
    TextSize = 14,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false
})
AddCorner(SearchBox, 8)

local SearchButton = New("TextButton", {
    Parent = Main,
    Size = UDim2.fromOffset(70, 34),
    Position = UDim2.new(1, -84, 0, 62),
    BackgroundColor3 = Color3.fromRGB(255, 120, 35),
    BorderSizePixel = 0,
    Text = "BUSCAR",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 11,
    Font = Enum.Font.GothamBold
})
AddCorner(SearchButton, 7)

local CurrentGameButton = New("TextButton", {
    Parent = Main,
    Size = UDim2.new(0.5, -18, 0, 32),
    Position = UDim2.fromOffset(14, 106),
    BackgroundColor3 = Color3.fromRGB(28, 28, 34),
    BorderSizePixel = 0,
    Text = "🎮 JOGO ATUAL",
    TextColor3 = Color3.fromRGB(225, 225, 230),
    TextSize = 11,
    Font = Enum.Font.GothamBold
})
AddCorner(CurrentGameButton, 7)

local UniversalButton = New("TextButton", {
    Parent = Main,
    Size = UDim2.new(0.5, -18, 0, 32),
    Position = UDim2.new(0.5, 4, 0, 106),
    BackgroundColor3 = Color3.fromRGB(28, 28, 34),
    BorderSizePixel = 0,
    Text = "🌐 UNIVERSAL",
    TextColor3 = Color3.fromRGB(225, 225, 230),
    TextSize = 11,
    Font = Enum.Font.GothamBold
})
AddCorner(UniversalButton, 7)

local ScriptBloxTab = New("TextButton", {
    Parent = Main,
    Size = UDim2.new(0.5, -18, 0, 34),
    Position = UDim2.fromOffset(14, 148),
    BackgroundColor3 = Color3.fromRGB(255, 120, 35),
    BorderSizePixel = 0,
    Text = "📜 ScriptBlox",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 12,
    Font = Enum.Font.GothamBold
})
AddCorner(ScriptBloxTab, 7)

local RScriptsTab = New("TextButton", {
    Parent = Main,
    Size = UDim2.new(0.5, -18, 0, 34),
    Position = UDim2.new(0.5, 4, 0, 148),
    BackgroundColor3 = Color3.fromRGB(28, 28, 34),
    BorderSizePixel = 0,
    Text = "⚡ RScripts",
    TextColor3 = Color3.fromRGB(225, 225, 230),
    TextSize = 12,
    Font = Enum.Font.GothamBold
})
AddCorner(RScriptsTab, 7)

local Status = New("TextLabel", {
    Parent = Main,
    Size = UDim2.new(1, -28, 0, 24),
    Position = UDim2.fromOffset(14, 188),
    BackgroundTransparency = 1,
    Text = "Pronto.",
    TextColor3 = Color3.fromRGB(145, 145, 155),
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
})

local Results = New("ScrollingFrame", {
    Parent = Main,
    Size = UDim2.new(1, -28, 1, -262),
    Position = UDim2.fromOffset(14, 212),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ScrollingDirection = Enum.ScrollingDirection.Y
})

New("UIListLayout", {
    Parent = Results,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder
})

local CurrentSource = "ScriptBlox"
local CurrentPage = 1
local CurrentResults = {}

local function ClearResults()
    for _, child in ipairs(Results:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

local function CreateTag(parent, text)
    local tag = New("TextLabel", {
        Parent = parent,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 20),
        BackgroundColor3 = Color3.fromRGB(31, 31, 37),
        BorderSizePixel = 0,
        Text = " " .. text .. " ",
        TextColor3 = Color3.fromRGB(215, 215, 220),
        TextSize = 9,
        Font = Enum.Font.GothamBold
    })
    AddCorner(tag, 5)
    return tag
end

local function ShowDetails(scriptData)
    local Popup = New("Frame", {
        Parent = ScreenGui,
        Size = UDim2.new(0.9, 0, 0.75, 0),
        Position = UDim2.new(0.05, 0, 0.125, 0),
        BackgroundColor3 = Color3.fromRGB(15, 15, 18),
        BorderSizePixel = 0,
        ZIndex = 20
    })
    AddCorner(Popup, 12)
    AddStroke(Popup)

    New("TextLabel", {
        Parent = Popup,
        Size = UDim2.new(1, -50, 0, 42),
        Position = UDim2.fromOffset(14, 4),
        BackgroundTransparency = 1,
        Text = scriptData.Title,
        TextColor3 = Color3.fromRGB(245, 245, 250),
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21
    })

    local X = New("TextButton", {
        Parent = Popup,
        Size = UDim2.fromOffset(32, 30),
        Position = UDim2.new(1, -40, 0, 8),
        BackgroundColor3 = Color3.fromRGB(35, 35, 40),
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        ZIndex = 21
    })
    AddCorner(X, 7)
    X.MouseButton1Click:Connect(function() Popup:Destroy() end)

    local Info = New("ScrollingFrame", {
        Parent = Popup,
        Size = UDim2.new(1, -28, 1, -60),
        Position = UDim2.fromOffset(14, 52),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 21
    })

    New("UIListLayout", {
        Parent = Info,
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local function AddInfo(text)
        local label = New("TextLabel", {
            Parent = Info,
            Size = UDim2.new(1, -4, 0, 24),
            BackgroundColor3 = Color3.fromRGB(23, 23, 28),
            BorderSizePixel = 0,
            Text = "  " .. text,
            TextColor3 = Color3.fromRGB(215, 215, 220),
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 22
        })
        AddCorner(label, 6)
    end

    AddInfo("Fonte: " .. tostring(scriptData.Source))
    AddInfo("Jogo: " .. tostring(scriptData.Game or "Unknown"))
    AddInfo("PlaceId: " .. tostring(scriptData.PlaceId or "Unknown"))
    AddInfo("Universal: " .. tostring(scriptData.Universal))
    AddInfo("Key: " .. tostring(scriptData.Key))
    AddInfo("Verified: " .. tostring(scriptData.Verified))
    AddInfo("Patched: " .. tostring(scriptData.Patched))
    AddInfo("Mobile: " .. tostring(scriptData.MobileReady))
    AddInfo("Paid: " .. tostring(scriptData.Paid))
    AddInfo("Views: " .. tostring(scriptData.Views))
    AddInfo("Likes: " .. tostring(scriptData.Likes))

    if scriptData.Risk then
        AddInfo("Risk: " .. tostring(scriptData.Risk.Score) ..
            "/10 - " .. tostring(scriptData.Risk.Level))
        AddInfo("Obfuscated: " ..
            tostring(scriptData.Risk.Obfuscated))
    end

    if scriptData.Creator then
        AddInfo("Creator: " ..
            tostring(scriptData.Creator.Username))
    end
end

local function ShowRaw(code, title)
    if not code or code == "" then
        Status.Text = "❌ RAW indisponível."
        return
    end

    local Popup = New("Frame", {
        Parent = ScreenGui,
        Size = UDim2.new(0.94, 0, 0.82, 0),
        Position = UDim2.new(0.03, 0, 0.09, 0),
        BackgroundColor3 = Color3.fromRGB(10, 10, 12),
        BorderSizePixel = 0,
        ZIndex = 30
    })
    AddCorner(Popup, 12)
    AddStroke(Popup)

    New("TextLabel", {
        Parent = Popup,
        Size = UDim2.new(1, -100, 0, 42),
        Position = UDim2.fromOffset(14, 4),
        BackgroundTransparency = 1,
        Text = "RAW • " .. tostring(title),
        TextColor3 = Color3.fromRGB(245, 245, 250),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 31
    })

    local Copy = New("TextButton", {
        Parent = Popup,
        Size = UDim2.fromOffset(65, 30),
        Position = UDim2.new(1, -105, 0, 8),
        BackgroundColor3 = Color3.fromRGB(255, 120, 35),
        BorderSizePixel = 0,
        Text = "COPIAR",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        ZIndex = 31
    })
    AddCorner(Copy, 7)

    local CloseRaw = New("TextButton", {
        Parent = Popup,
        Size = UDim2.fromOffset(32, 30),
        Position = UDim2.new(1, -40, 0, 8),
        BackgroundColor3 = Color3.fromRGB(35, 35, 40),
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        ZIndex = 31
    })
    AddCorner(CloseRaw, 7)
    CloseRaw.MouseButton1Click:Connect(function() Popup:Destroy() end)

    Copy.MouseButton1Click:Connect(function()
        if typeof(setclipboard) == "function" then
            pcall(function() setclipboard(code) end)
            Copy.Text = "COPIADO"
            task.delay(1.2, function()
                if Copy and Copy.Parent then Copy.Text = "COPIAR" end
            end)
        else
            Copy.Text = "N/D"
        end
    end)

    local CodeBox = New("TextBox", {
        Parent = Popup,
        Size = UDim2.new(1, -28, 1, -64),
        Position = UDim2.fromOffset(14, 52),
        BackgroundColor3 = Color3.fromRGB(17, 17, 20),
        BorderSizePixel = 0,
        Text = code,
        TextColor3 = Color3.fromRGB(220, 220, 225),
        TextSize = 11,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        MultiLine = true,
        ClearTextOnFocus = false,
        TextEditable = false,
        TextWrapped = false,
        ZIndex = 31
    })
    AddCorner(CodeBox, 8)
end

local function GetRaw(scriptData)
    if scriptData.Code and scriptData.Code ~= "" then
        return true, scriptData.Code
    end

    if not scriptData.RawURL then
        return false, "RAW não disponível."
    end

    local ok, body = HTTPRequest(scriptData.RawURL)
    if not ok then return false, body end
    return true, body
end

local function CreateCard(scriptData)
    local Card = New("Frame", {
        Parent = Results,
        Size = UDim2.new(1, -4, 0, 145),
        BackgroundColor3 = Color3.fromRGB(20, 20, 24),
        BorderSizePixel = 0
    })
    AddCorner(Card, 9)
    AddStroke(Card)

    New("TextLabel", {
        Parent = Card,
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.fromOffset(10, 8),
        BackgroundTransparency = 1,
        Text = scriptData.Title,
        TextColor3 = Color3.fromRGB(240, 240, 245),
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    New("TextLabel", {
        Parent = Card,
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.fromOffset(10, 32),
        BackgroundTransparency = 1,
        Text = "🎮 " .. tostring(scriptData.Game or "Unknown"),
        TextColor3 = Color3.fromRGB(145, 145, 155),
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local Tags = New("Frame", {
        Parent = Card,
        Size = UDim2.new(1, -20, 0, 23),
        Position = UDim2.fromOffset(10, 52),
        BackgroundTransparency = 1
    })

    New("UIListLayout", {
        Parent = Tags,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 5)
    })

    if scriptData.Key == "Yes" then
        CreateTag(Tags, "🔑 KEY")
    elseif scriptData.Key == "No" then
        CreateTag(Tags, "🔓 NO KEY")
    else
        CreateTag(Tags, "❓ UNKNOWN")
    end

    if scriptData.Verified == true then
        CreateTag(Tags, "✅ VERIFIED")
    elseif scriptData.Verified == false then
        CreateTag(Tags, "❌ UNVERIFIED")
    end

    if scriptData.Patched == true then
        CreateTag(Tags, "🩹 PATCHED")
    elseif scriptData.Patched == false then
        CreateTag(Tags, "🟢 WORKING")
    end

    if scriptData.Universal == true then
        CreateTag(Tags, "🌐 UNIVERSAL")
    end

    if scriptData.MobileReady == true then
        CreateTag(Tags, "📱 MOBILE")
    end

    if scriptData.Paid == true then
        CreateTag(Tags, "💰 PAID")
    elseif scriptData.Paid == false then
        CreateTag(Tags, "FREE")
    end

    New("TextLabel", {
        Parent = Card,
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.fromOffset(10, 78),
        BackgroundTransparency = 1,
        Text = "👁 " .. tostring(scriptData.Views) ..
            "    ❤️ " .. tostring(scriptData.Likes),
        TextColor3 = Color3.fromRGB(130, 130, 140),
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    if scriptData.Risk then
        New("TextLabel", {
            Parent = Card,
            Size = UDim2.fromOffset(130, 20),
            Position = UDim2.new(1, -140, 0, 78),
            BackgroundTransparency = 1,
            Text = "🛡️ " .. tostring(scriptData.Risk.Score) ..
                "/10 " .. tostring(scriptData.Risk.Level),
            TextColor3 = Color3.fromRGB(170, 170, 180),
            TextSize = 9,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Right
        })
    end

    local View = New("TextButton", {
        Parent = Card,
        Size = UDim2.fromOffset(72, 30),
        Position = UDim2.fromOffset(10, 108),
        BackgroundColor3 = Color3.fromRGB(32, 32, 38),
        BorderSizePixel = 0,
        Text = "👁 VER",
        TextColor3 = Color3.fromRGB(235, 235, 240),
        TextSize = 10,
        Font = Enum.Font.GothamBold
    })
    AddCorner(View, 6)
    View.MouseButton1Click:Connect(function()
        ShowDetails(scriptData)
    end)

    local Raw = New("TextButton", {
        Parent = Card,
        Size = UDim2.fromOffset(72, 30),
        Position = UDim2.fromOffset(88, 108),
        BackgroundColor3 = Color3.fromRGB(32, 32, 38),
        BorderSizePixel = 0,
        Text = "📄 RAW",
        TextColor3 = Color3.fromRGB(235, 235, 240),
        TextSize = 10,
        Font = Enum.Font.GothamBold
    })
    AddCorner(Raw, 6)

    Raw.MouseButton1Click:Connect(function()
        Status.Text = "⏳ Obtendo RAW..."
        task.spawn(function()
            local ok, code = GetRaw(scriptData)
            if ok then
                ShowRaw(code, scriptData.Title)
                Status.Text = "RAW carregado."
            else
                Status.Text = "❌ " .. tostring(code)
            end
        end)
    end)
end

local function RenderResults()
    ClearResults()

    if #CurrentResults == 0 then
        New("TextLabel", {
            Parent = Results,
            Size = UDim2.new(1, -4, 0, 50),
            BackgroundTransparency = 1,
            Text = "🔍 Nenhum resultado encontrado.",
            TextColor3 = Color3.fromRGB(140, 140, 150),
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Center
        })
        return
    end

    for _, scriptData in ipairs(CurrentResults) do
        CreateCard(scriptData)
    end
end

local function SearchNormal(query)
    Status.Text = "⏳ Pesquisando " .. CurrentSource .. "..."

    task.spawn(function()
        local ok, data

        if CurrentSource == "ScriptBlox" then
            ok, data = ScriptBlox.Search(query, CurrentPage)
        else
            ok, data = RScripts.Search(query, CurrentPage)
        end

        if not ok then
            CurrentResults = {}
            RenderResults()
            Status.Text = "❌ " .. tostring(data)
            return
        end

        CurrentResults = data.Results or {}
        RenderResults()
        Status.Text = "✅ " .. tostring(#CurrentResults) .. " resultado(s)."
    end)
end

local function SearchCurrentGame()
    local placeId = game.PlaceId
    Status.Text = "⏳ Procurando scripts para PlaceId " .. tostring(placeId) .. "..."

    task.spawn(function()
        local ok, data

        if CurrentSource == "ScriptBlox" then
            ok, data = ScriptBlox.SearchPlace(placeId, CurrentPage)
        else
            ok, data = RScripts.SearchPlace(placeId, CurrentPage)
        end

        if not ok then
            CurrentResults = {}
            RenderResults()
            Status.Text = "❌ " .. tostring(data)
            return
        end

        CurrentResults = data.Results or {}
        RenderResults()
        Status.Text = "🎮 " .. tostring(#CurrentResults) .. " script(s) encontrados."
    end)
end

local function SearchUniversal()
    Status.Text = "⏳ Procurando scripts universais..."

    task.spawn(function()
        local ok, data

        if CurrentSource == "ScriptBlox" then
            ok, data = ScriptBlox.SearchUniversal(CurrentPage)
        else
            ok, data = RScripts.SearchUniversal(CurrentPage)
        end

        if not ok then
            CurrentResults = {}
            RenderResults()
            Status.Text = "❌ " .. tostring(data)
            return
        end

        CurrentResults = data.Results or {}
        RenderResults()
        Status.Text = "🌐 " .. tostring(#CurrentResults) .. " resultado(s)."
    end)
end

SearchButton.MouseButton1Click:Connect(function()
    local query = SearchBox.Text
    if query == "" then
        Status.Text = "Digite alguma coisa para pesquisar."
        return
    end
    CurrentPage = 1
    SearchNormal(query)
end)

SearchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and SearchBox.Text ~= "" then
        CurrentPage = 1
        SearchNormal(SearchBox.Text)
    end
end)

CurrentGameButton.MouseButton1Click:Connect(function()
    CurrentPage = 1
    SearchCurrentGame()
end)

UniversalButton.MouseButton1Click:Connect(function()
    CurrentPage = 1
    SearchUniversal()
end)

ScriptBloxTab.MouseButton1Click:Connect(function()
    CurrentSource = "ScriptBlox"
    ScriptBloxTab.BackgroundColor3 = Color3.fromRGB(255, 120, 35)
    RScriptsTab.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    Status.Text = "Fonte selecionada: ScriptBlox"
end)

RScriptsTab.MouseButton1Click:Connect(function()
    CurrentSource = "RScripts"
    RScriptsTab.BackgroundColor3 = Color3.fromRGB(255, 120, 35)
    ScriptBloxTab.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    Status.Text = "Fonte selecionada: RScripts"
end)

local OpenButton = New("TextButton", {
    Parent = ScreenGui,
    Size = UDim2.fromOffset(52, 52),
    Position = UDim2.new(0, 15, 0.5, -26),
    BackgroundColor3 = Color3.fromRGB(255, 120, 35),
    BorderSizePixel = 0,
    Text = "🔎",
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    Visible = false
})
AddCorner(OpenButton, 26)

Close.MouseButton1Click:Connect(function()
    Main.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()
    Main.Visible = true
    OpenButton.Visible = false
end)

local UIS = game:GetService("UserInputService")
local dragging = false
local dragStart
local startPosition

Top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if not dragging then return end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart

    Main.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

New("TextLabel", {
    Parent = Main,
    Size = UDim2.new(1, -28, 0, 18),
    Position = UDim2.new(0, 14, 1, -21),
    BackgroundTransparency = 1,
    Text = "Powered by ScriptBlox.com + RScripts.net",
    TextColor3 = Color3.fromRGB(90, 90, 100),
    TextSize = 8,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Center
})

if not RequestFunction then
    Status.Text = "⚠️ HTTP request não disponível neste ambiente."
else
    Status.Text = "Pronto. Pesquise um script ou use Jogo Atual."
end
