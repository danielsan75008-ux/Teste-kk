--[[
    AIChat - Roblox Luau
    Compact AI + RScripts developer GUI.

    Notes:
    - No API key, provider, profile or model is configured by default.
    - No network request is made during initialization.
    - RScripts integration follows the documented read-only REST API.
    - Returned code is never executed automatically.
    - Storage uses common executor file functions only when available.
]]

local Services = {
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    HttpService = game:GetService("HttpService"),
    CoreGui = game:GetService("CoreGui"),
}

local LocalPlayer = Services.Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")

local Icons = {
    bot = "rbxassetid://80451686744860",
    search = "rbxassetid://121018724060431",
    settings = "rbxassetid://80758916183665",
    copy = "rbxassetid://78979572434545",
    x = "rbxassetid://110786993356448",
    send = "rbxassetid://127751956873796",
}

local ServicesFolder = {}
local Config = {}
local State = {
    Profiles = {},
    ActiveProfile = nil,
    SystemPrompt = "Você é um assistente especializado em programação Lua para Roblox.
Responda em português.
Seja direto e explique os erros no código.
Nunca execute código automaticamente.Você é um especialista em LuaU Roblox",
    RScriptsAPIKey = "rsc_live_SyIJb6i8oRHyCtizUPKIpAG6b5ZaJLsU",
    Theme = {
        Accent = Color3.fromRGB(255, 132, 0),
        Transparency = 0.12,
        Scale = 1,
        FontSize = 13,
        Rounding = 6,
        Animations = true,
    },
    Models = {},
    Favorites = {},
    ChatHistory = {},
}

local UI = {}
local Connections = {}
local CurrentTab = "Chat"
local Minimized = false
local LastNormalSize = Vector2.new(520, 420)
local RequestBusy = false

local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then
        return true, result
    end
    return false, result
end

local function getRequestFunction()
    local candidates = {
        request,
        http_request,
        http and http.request,
        syn and syn.request,
        fluxus and fluxus.request,
    }
    for _, fn in ipairs(candidates) do
        if type(fn) == "function" then
            return fn
        end
    end
    return nil
end

ServicesFolder.Request = getRequestFunction()

local function jsonEncode(value)
    local ok, result = safeCall(Services.HttpService.JSONEncode, Services.HttpService, value)
    return ok and result or nil
end

local function jsonDecode(value)
    local ok, result = safeCall(Services.HttpService.JSONDecode, Services.HttpService, value)
    return ok and result or nil
end

local function hasFileAPI()
    return type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function"
end

local function ensureFolder()
    if type(makefolder) ~= "function" then
        return false
    end
    if type(isfolder) == "function" and isfolder("AIChat") then
        return true
    end
    local ok = pcall(makefolder, "AIChat")
    return ok
end

local function loadStorage()
    if not hasFileAPI() then
        return false, "Persistência não está disponível neste ambiente."
    end
    ensureFolder()
    local okRead, raw = pcall(readfile, "AIChat/config.json")
    if not okRead or type(raw) ~= "string" or raw == "" then
        return true
    end
    local decoded = jsonDecode(raw)
    if type(decoded) ~= "table" then
        return false, "config.json inválido."
    end
    if type(decoded.Profiles) == "table" then State.Profiles = decoded.Profiles end
    if type(decoded.ActiveProfile) == "string" then State.ActiveProfile = decoded.ActiveProfile end
    if type(decoded.SystemPrompt) == "string" then State.SystemPrompt = decoded.SystemPrompt end
    if type(decoded.RScriptsAPIKey) == "string" then State.RScriptsAPIKey = decoded.RScriptsAPIKey end
    if type(decoded.Theme) == "table" then
        for k, v in pairs(decoded.Theme) do
            if State.Theme[k] ~= nil and typeof(v) == typeof(State.Theme[k]) then
                State.Theme[k] = v
            end
        end
    end
    if type(decoded.Models) == "table" then State.Models = decoded.Models end
    if type(decoded.Favorites) == "table" then State.Favorites = decoded.Favorites end
    return true
end

local function saveStorage()
    if not hasFileAPI() then
        return false, "Persistência não está disponível neste ambiente."
    end
    ensureFolder()
    local payload = {
        Profiles = State.Profiles,
        ActiveProfile = State.ActiveProfile,
        SystemPrompt = State.SystemPrompt,
        RScriptsAPIKey = State.RScriptsAPIKey,
        Theme = State.Theme,
        Models = State.Models,
        Favorites = State.Favorites,
    }
    local raw = jsonEncode(payload)
    if not raw then return false, "Não foi possível serializar a configuração." end
    local ok, err = pcall(writefile, "AIChat/config.json", raw)
    return ok, err
end

local function notify(message, kind)
    if UI.Status then
        UI.Status.Text = tostring(message)
        UI.Status.TextColor3 = kind == "error" and Color3.fromRGB(255, 110, 110)
            or kind == "ok" and Color3.fromRGB(130, 220, 150)
            or Color3.fromRGB(190, 190, 190)
    end
end

local function clearChildren(parent, keepLayout)
    for _, child in ipairs(parent:GetChildren()) do
        if not keepLayout or not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UIGridLayout") then
            child:Destroy()
        end
    end
end

local function addCorner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or State.Theme.Rounding)
    c.Parent = obj
    return c
end

local function addStroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or State.Theme.Accent
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = obj
    return s
end

local function makeText(parent, text, size, color, font)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.TextColor3 = color or Color3.fromRGB(235, 235, 235)
    label.TextSize = size or State.Theme.FontSize
    label.Font = font or Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

local function makeButton(parent, text, icon, callback)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.BackgroundColor3 = State.Theme.Accent
    b.BackgroundTransparency = 0.05
    b.Text = ""
    b.Size = UDim2.fromOffset(88, 30)
    b.Parent = parent
    addCorner(b, State.Theme.Rounding)

    if icon and Icons[icon] then
        local img = Instance.new("ImageLabel")
        img.BackgroundTransparency = 1
        img.Image = Icons[icon]
        img.ImageColor3 = Color3.fromRGB(20, 20, 20)
        img.Size = UDim2.fromOffset(16, 16)
        img.Position = UDim2.new(0, 8, 0.5, -8)
        img.Parent = b
        local t = makeText(b, text, State.Theme.FontSize, Color3.fromRGB(20, 20, 20), Enum.Font.GothamMedium)
        t.Size = UDim2.new(1, -30, 1, 0)
        t.Position = UDim2.fromOffset(28, 0)
        t.TextXAlignment = Enum.TextXAlignment.Center
    else
        local t = makeText(b, text, State.Theme.FontSize, Color3.fromRGB(20, 20, 20), Enum.Font.GothamMedium)
        t.Size = UDim2.fromScale(1, 1)
        t.TextXAlignment = Enum.TextXAlignment.Center
    end

    b.MouseEnter:Connect(function()
        b.BackgroundTransparency = 0
    end)
    b.MouseLeave:Connect(function()
        b.BackgroundTransparency = 0.05
    end)
    b.Activated:Connect(function()
        if callback then
            task.spawn(callback)
        end
    end)
    return b
end

local function makeInput(parent, placeholder, multiline)
    local box = Instance.new("TextBox")
    box.ClearTextOnFocus = false
    box.MultiLine = multiline ~= false
    box.TextWrapped = true
    box.Text = ""
    box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = Color3.fromRGB(115, 115, 115)
    box.TextColor3 = Color3.fromRGB(235, 235, 235)
    box.TextSize = State.Theme.FontSize
    box.Font = Enum.Font.Code
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
    box.BackgroundTransparency = 0.05
    box.Parent = parent
    addCorner(box, State.Theme.Rounding)
    addStroke(box, Color3.fromRGB(65, 65, 68), 1, 0.2)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 7)
    pad.PaddingBottom = UDim.new(0, 7)
    pad.Parent = box
    return box
end

local function makeScroll(parent)
    local s = Instance.new("ScrollingFrame")
    s.BackgroundTransparency = 1
    s.BorderSizePixel = 0
    s.ScrollBarThickness = 4
    s.ScrollBarImageColor3 = State.Theme.Accent
    s.CanvasSize = UDim2.new()
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    s.ScrollingDirection = Enum.ScrollingDirection.Y
    s.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = s
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 4)
    pad.Parent = s
    return s
end

local function setTab(name)
    CurrentTab = name
    for tabName, frame in pairs(UI.TabFrames or {}) do
        frame.Visible = tabName == name
    end
    for tabName, button in pairs(UI.TabButtons or {}) do
        button.BackgroundTransparency = tabName == name and 0 or 0.65
        button.TextColor3 = tabName == name and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(210, 210, 210)
    end
end

local function getActiveProfile()
    if type(State.ActiveProfile) ~= "string" then return nil end
    return State.Profiles[State.ActiveProfile]
end

local function profileIsValid(profile)
    return type(profile) == "table"
        and type(profile.API_URL) == "string" and profile.API_URL ~= ""
        and type(profile.API_KEY) == "string" and profile.API_KEY ~= ""
        and type(profile.MODEL) == "string" and profile.MODEL ~= ""
end

local function normalizeChatURL(url)
    url = tostring(url or ""):gsub("%s+", "")
    if url == "" then return nil end
    return url
end

local function doRequest(options)
    local req = ServicesFolder.Request
    if not req then
        return nil, "HTTP não disponível neste ambiente."
    end
    local ok, result = pcall(req, options)
    if not ok or type(result) ~= "table" then
        return nil, "Erro de conexão."
    end
    local status = tonumber(result.StatusCode or result.status_code or result.Status or 0) or 0
    local body = result.Body or result.body or ""
    return {StatusCode = status, Body = body, Headers = result.Headers or result.headers or {}}, nil
end

local function parseAPIError(response)
    local code = response.StatusCode
    if code == 401 then return "401: API Key inválida ou ausente." end
    if code == 403 then return "403: acesso negado pela API." end
    if code == 404 then return "404: endpoint, modelo ou recurso não encontrado." end
    if code == 429 then return "429: limite de requisições atingido." end
    if code >= 500 then return tostring(code) .. ": serviço remoto indisponível." end
    local decoded = jsonDecode(response.Body)
    if type(decoded) == "table" and type(decoded.error) == "table" then
        local msg = decoded.error.message or decoded.error.code
        if msg then return tostring(code) .. ": " .. tostring(msg) end
    end
    return tostring(code) .. ": resposta inválida da API."
end

local function callAI(profile, messages)
    if not profileIsValid(profile) then
        return nil, "Configure a IA que você vai usar nas configurações."
    end
    local url = normalizeChatURL(profile.API_URL)
    if not url then return nil, "API URL inválida." end
    local body = {model = profile.MODEL, messages = messages}
    local raw = jsonEncode(body)
    if not raw then return nil, "Falha ao montar a requisição." end
    local response, err = doRequest({
        Url = url,
        Method = "POST",
        Headers = {
            ["Authorization"] = "Bearer " .. profile.API_KEY,
            ["Content-Type"] = "application/json",
        },
        Body = raw,
    })
    if not response then return nil, err end
    if response.StatusCode < 200 or response.StatusCode >= 300 then
        return nil, parseAPIError(response)
    end
    local decoded = jsonDecode(response.Body)
    if type(decoded) ~= "table" then return nil, "Resposta JSON inválida." end
    if type(decoded.choices) ~= "table" or not decoded.choices[1] then return nil, "Resposta sem choices." end
    local choice = decoded.choices[1]
    if type(choice.message) ~= "table" then return nil, "Resposta sem message." end
    if type(choice.message.content) ~= "string" or choice.message.content == "" then return nil, "Resposta sem content." end
    return choice.message.content
end

local function appendChat(role, content)
    table.insert(State.ChatHistory, {role = role, content = content})
    if not UI.ChatHistory then return end
    local card = Instance.new("Frame")
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Size = UDim2.new(1, -8, 0, 0)
    card.BackgroundColor3 = role == "user" and Color3.fromRGB(31, 27, 22) or Color3.fromRGB(25, 25, 27)
    card.BackgroundTransparency = 0.04
    card.Parent = UI.ChatHistory
    addCorner(card, State.Theme.Rounding)
    addStroke(card, role == "user" and State.Theme.Accent or Color3.fromRGB(60, 60, 64), 1, 0.35)

    local title = makeText(card, role == "user" and "Usuário" or "IA", 11, role == "user" and State.Theme.Accent or Color3.fromRGB(190, 190, 190), Enum.Font.GothamMedium)
    title.Position = UDim2.fromOffset(9, 6)
    title.Size = UDim2.new(1, -18, 0, 18)

    local body = makeText(card, content, State.Theme.FontSize, Color3.fromRGB(225, 225, 225), Enum.Font.Code)
    body.TextWrapped = true
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Position = UDim2.fromOffset(9, 28)
    body.Size = UDim2.new(1, -18, 0, 0)

    if role == "assistant" then
        local copy = makeButton(card, "Copiar", "copy", function()
            if type(setclipboard) == "function" then
                pcall(setclipboard, content)
                notify("Resposta copiada.", "ok")
            else
                notify("setclipboard não está disponível neste ambiente.", "error")
            end
        end)
        copy.AnchorPoint = Vector2.new(1, 0)
        copy.Position = UDim2.new(1, -8, 0, 6)
        copy.Size = UDim2.fromOffset(72, 24)
        title.Size = UDim2.new(1, -90, 0, 18)
        body.Size = UDim2.new(1, -18, 0, 0)
    end

    task.defer(function()
        if UI.ChatHistory then
            UI.ChatHistory.CanvasPosition = Vector2.new(0, math.max(0, UI.ChatHistory.AbsoluteCanvasSize.Y))
        end
    end)
end

local function clearChat()
    State.ChatHistory = {}
    if UI.ChatHistory then clearChildren(UI.ChatHistory, true) end
    notify("Histórico limpo.", "ok")
end

local function buildChatMessages(userText)
    local messages = {}
    local profile = getActiveProfile()
    if profile and type(profile.SystemPrompt) == "string" and profile.SystemPrompt ~= "" then
        table.insert(messages, {role = "system", content = profile.SystemPrompt})
    elseif State.SystemPrompt ~= "" then
        table.insert(messages, {role = "system", content = State.SystemPrompt})
    end
    for _, item in ipairs(State.ChatHistory) do
        if (item.role == "user" or item.role == "assistant") and type(item.content) == "string" then
            table.insert(messages, {role = item.role, content = item.content})
        end
    end
    table.insert(messages, {role = "user", content = userText})
    return messages
end

local function sendChat()
    if RequestBusy then return end
    local profile = getActiveProfile()
    if not profileIsValid(profile) then
        notify("Configure a IA que você vai usar nas configurações.", "error")
        setTab("Configurações")
        return
    end
    if not UI.ChatInput or UI.ChatInput.Text:gsub("%s+", "") == "" then return end
    local text = UI.ChatInput.Text
    UI.ChatInput.Text = ""
    appendChat("user", text)
    RequestBusy = true
    if UI.SendButton then UI.SendButton.Active = false UI.SendButton.AutoButtonColor = false end
    notify("Enviando...", "busy")
    local answer, err = callAI(profile, buildChatMessages(text))
    RequestBusy = false
    if UI.SendButton then UI.SendButton.Active = true end
    if answer then
        appendChat("assistant", answer)
        notify("Pronto.", "ok")
    else
        notify(err or "Falha na requisição.", "error")
    end
end

local function getRScriptsBase()
    return "https://api.rscripts.net"
end

local function rscriptsRequest(path)
    if State.RScriptsAPIKey == "" then
        return nil, "Configure a RScripts API Key nas configurações."
    end
    local response, err = doRequest({
        Url = getRScriptsBase() .. path,
        Method = "GET",
        Headers = {
            ["Authorization"] = "Bearer " .. State.RScriptsAPIKey,
            ["Content-Type"] = "application/json",
        },
    })
    if not response then return nil, err end
    if response.StatusCode < 200 or response.StatusCode >= 300 then
        return nil, parseAPIError(response)
    end
    local decoded = jsonDecode(response.Body)
    if type(decoded) ~= "table" then return nil, "Resposta RScripts inválida." end
    if decoded.success == false then
        local e = decoded.error
        return nil, type(e) == "table" and (e.message or e.code) or "Erro da API RScripts."
    end
    return decoded
end

local function urlEncode(s)
    s = tostring(s or "")
    return s:gsub("[^%w%-_%.~]", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

local function showScriptCard(item)
    local card = Instance.new("Frame")
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Size = UDim2.new(1, -8, 0, 0)
    card.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
    card.Parent = UI.RScriptsResults
    addCorner(card, State.Theme.Rounding)
    addStroke(card, Color3.fromRGB(65, 65, 68), 1, 0.2)

    local title = makeText(card, tostring(item.title or "Sem título"), 13, Color3.fromRGB(240, 240, 240), Enum.Font.GothamMedium)
    title.Position = UDim2.fromOffset(9, 7)
    title.Size = UDim2.new(1, -18, 0, 20)

    local meta = {}
    if item.slug then table.insert(meta, "slug: " .. tostring(item.slug)) end
    if item.creator and item.creator.username then table.insert(meta, "autor: " .. tostring(item.creator.username)) end
    if item.likes ~= nil then table.insert(meta, "likes: " .. tostring(item.likes)) end
    if item.views ~= nil then table.insert(meta, "views: " .. tostring(item.views)) end
    if item.risk then table.insert(meta, "risco: " .. tostring(item.risk.level or "Unknown") .. " / " .. tostring(item.risk.score or "?")) end
    table.insert(meta, "Key System: " .. ((item.isKeySystem and "Sim") or "Não"))
    table.insert(meta, "Gratuito: " .. ((item.isPaid and "Não") or "Sim"))

    local info = makeText(card, table.concat(meta, "  |  "), 10, Color3.fromRGB(165, 165, 170), Enum.Font.Code)
    info.TextWrapped = true
    info.AutomaticSize = Enum.AutomaticSize.Y
    info.Position = UDim2.fromOffset(9, 29)
    info.Size = UDim2.new(1, -18, 0, 0)

    local desc = makeText(card, tostring(item.description or "Sem descrição."), 11, Color3.fromRGB(195, 195, 198), Enum.Font.Gotham)
    desc.TextWrapped = true
    desc.AutomaticSize = Enum.AutomaticSize.Y
    desc.Position = UDim2.fromOffset(9, 50)
    desc.Size = UDim2.new(1, -18, 0, 0)

    local copy = makeButton(card, "Copiar", "copy", function()
        if not item.slug then notify("Slug não disponível.", "error") return end
        notify("Buscando código...", "busy")
        local detail, err = rscriptsRequest("/v1/scripts/" .. urlEncode(item.slug))
        if not detail then notify(err, "error") return end
        local data = detail.data
        if type(data) ~= "table" or type(data.script) ~= "string" then
            notify("O script não possui código disponível.", "error")
            return
        end
        if type(setclipboard) ~= "function" then
            notify("setclipboard não está disponível neste ambiente.", "error")
            return
        end
        pcall(setclipboard, data.script)
        notify("Script copiado.", "ok")
    end)
    copy.Position = UDim2.fromOffset(9, 82)
    copy.Size = UDim2.fromOffset(78, 25)

    local sendAI = makeButton(card, "Enviar à IA", "send", function()
        if not item.slug then notify("Slug não disponível.", "error") return end
        if not profileIsValid(getActiveProfile()) then
            notify("Configure a IA que você vai usar nas configurações.", "error")
            setTab("Configurações")
            return
        end
        notify("Buscando código...", "busy")
        local detail, err = rscriptsRequest("/v1/scripts/" .. urlEncode(item.slug))
        if not detail then notify(err, "error") return end
        local data = detail.data
        if type(data) ~= "table" or type(data.script) ~= "string" then
            notify("O script não possui código disponível.", "error")
            return
        end
        local prompt = "Analise este script do RScripts. Explique o que ele faz, identifique riscos e descreva as partes importantes. Não execute nada automaticamente:\n\n" .. data.script
        setTab("Chat")
        UI.ChatInput.Text = prompt
        notify("Script preparado para análise.", "ok")
    end)
    sendAI.Position = UDim2.fromOffset(93, 82)
    sendAI.Size = UDim2.fromOffset(100, 25)

    card:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        local h = 115 + info.AbsoluteSize.Y + desc.AbsoluteSize.Y
        card.Size = UDim2.new(1, -8, 0, math.max(120, h))
    end)
end

local function performSearch(path)
    if not UI.RScriptsResults then return end
    clearChildren(UI.RScriptsResults, true)
    notify("Pesquisando RScripts...", "busy")
    local data, err = rscriptsRequest(path)
    if not data then notify(err, "error") return end
    local list = data.data
    if type(list) == "table" and type(list.scripts) == "table" then list = list.scripts end
    if type(list) ~= "table" then
        notify("Nenhum resultado encontrado.", "error")
        return
    end
    local count = 0
    for _, item in ipairs(list) do
        if type(item) == "table" then
            showScriptCard(item)
            count += 1
        end
    end
    notify(tostring(count) .. " resultado(s).", "ok")
end

local function currentPlaceId()
    local id = tonumber(game.PlaceId)
    if id and id > 0 then return tostring(id) end
    return nil
end

local function searchCurrentGame(easy)
    local placeId = currentPlaceId()
    if not placeId then
        notify("Não foi possível identificar o jogo atual.", "error")
        return
    end
    UI.PlaceIdLabel.Text = "PlaceId: " .. placeId
    local params = "?placeId=" .. urlEncode(placeId) .. "&limit=20"
    if easy then
        params ..= "&noKeySystem=true&freeOnly=true&sort=most-likes"
    else
        params ..= "&sort=recommended"
    end
    performSearch("/v1/scripts" .. params)
end

local function searchRScripts()
    local q = UI.RScriptsSearch and UI.RScriptsSearch.Text or ""
    if q:gsub("%s+", "") == "" then
        notify("Digite algo para pesquisar.", "error")
        return
    end
    performSearch("/v1/search?q=" .. urlEncode(q) .. "&index=scripts&limit=20")
end

local function fetchModels(profile)
    if not profile then
        notify("Selecione ou crie um perfil primeiro.", "error")
        return
    end
    if type(profile.API_URL) ~= "string" or profile.API_URL == "" or type(profile.API_KEY) ~= "string" or profile.API_KEY == "" then
        notify("Configure API URL e API Key antes de atualizar modelos.", "error")
        return
    end
    local base = profile.API_URL:gsub("/chat/completions/?$", "")
    local modelsURL = base .. "/models"
    local provider = tostring(profile.Provider or ""):lower()
    if provider == "openrouter" then
        modelsURL = "https://openrouter.ai/api/v1/models"
    end
    notify("Atualizando modelos...", "busy")
    local response, err = doRequest({
        Url = modelsURL,
        Method = "GET",
        Headers = {
            ["Authorization"] = "Bearer " .. profile.API_KEY,
            ["Content-Type"] = "application/json",
        },
    })
    if not response then notify(err, "error") return end
    if response.StatusCode < 200 or response.StatusCode >= 300 then
        notify(parseAPIError(response), "error")
        return
    end
    local decoded = jsonDecode(response.Body)
    if type(decoded) ~= "table" or type(decoded.data) ~= "table" then
        notify("A API não retornou uma lista de modelos.", "error")
        return
    end
    local found = 0
    for _, model in ipairs(decoded.data) do
        if type(model) == "table" and type(model.id) == "string" and model.id ~= "" then
            local id = model.id
            local price = "Unknown"
            if type(model.pricing) == "table" then
                local prompt = tonumber(model.pricing.prompt)
                local completion = tonumber(model.pricing.completion)
                if prompt == 0 and completion == 0 then price = "Free" else price = "Paid" end
            end
            State.Models[id] = {
                ID = id,
                Name = tostring(model.name or id),
                Provider = profile.Provider or "Other",
                Price = price,
                Custom = false,
            }
            found += 1
        end
    end
    saveStorage()
    refreshModelSelector()
    notify("" .. tostring(found) .. " modelo(s) atualizado(s).", "ok")
end

local function modelMatches(model, query)
    if query == "" then return true end
    local q = query:lower()
    return tostring(model.Name or ""):lower():find(q, 1, true) ~= nil
        or tostring(model.ID or ""):lower():find(q, 1, true) ~= nil
        or tostring(model.Provider or ""):lower():find(q, 1, true) ~= nil
end

local function refreshModelSelector()
    if not UI.ModelList then return end
    clearChildren(UI.ModelList, true)
    local query = UI.ModelSearch and UI.ModelSearch.Text or ""
    local profile = getActiveProfile()
    local provider = profile and tostring(profile.Provider or "") or ""
    local models = {}
    for id, model in pairs(State.Models) do
        if type(model) == "table" and modelMatches(model, query) then
            if provider == "" or model.Provider == provider or model.Custom then
                table.insert(models, model)
            end
        end
    end
    table.sort(models, function(a, b)
        local af = State.Favorites[a.ID] and 0 or 1
        local bf = State.Favorites[b.ID] and 0 or 1
        if af ~= bf then return af < bf end
        local ap = tostring(a.Price or "Unknown")
        local bp = tostring(b.Price or "Unknown")
        local order = {Free = 1, Paid = 2, Unknown = 3}
        if (order[ap] or 3) ~= (order[bp] or 3) then return (order[ap] or 3) < (order[bp] or 3) end
        return tostring(a.Name) < tostring(b.Name)
    end)
    if #models == 0 then
        local empty = makeText(UI.ModelList, "Nenhum modelo. Use 'Atualizar modelos' ou '+ Modelo personalizado'.", 11, Color3.fromRGB(130,130,135), Enum.Font.Gotham)
        empty.Size = UDim2.new(1, -8, 0, 32)
        return
    end
    for _, model in ipairs(models) do
        local row = Instance.new("TextButton")
        row.Text = ""
        row.AutoButtonColor = false
        row.Size = UDim2.new(1, -8, 0, 42)
        row.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
        row.Parent = UI.ModelList
        addCorner(row, State.Theme.Rounding)
        local name = makeText(row, (State.Favorites[model.ID] and "[★] " or "") .. tostring(model.Name), 11, Color3.fromRGB(225,225,225), Enum.Font.GothamMedium)
        name.Position = UDim2.fromOffset(8, 2)
        name.Size = UDim2.new(1, -100, 0, 19)
        local sub = makeText(row, tostring(model.ID) .. "  |  " .. tostring(model.Price or "Unknown"), 9, Color3.fromRGB(140,140,145), Enum.Font.Code)
        sub.Position = UDim2.fromOffset(8, 21)
        sub.Size = UDim2.new(1, -100, 0, 16)
        local fav = makeText(row, State.Favorites[model.ID] and "★" or "☆", 17, State.Theme.Accent, Enum.Font.Gotham)
        fav.TextXAlignment = Enum.TextXAlignment.Center
        fav.Position = UDim2.new(1, -52, 0, 5)
        fav.Size = UDim2.fromOffset(30, 30)
        fav.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                State.Favorites[model.ID] = not State.Favorites[model.ID]
                if not State.Favorites[model.ID] then State.Favorites[model.ID] = nil end
                saveStorage()
                refreshModelSelector()
            end
        end)
        row.Activated:Connect(function()
            if profile then
                profile.MODEL = model.ID
                UI.ModelCurrent.Text = model.Name .. "  |  " .. model.ID
                saveStorage()
                refreshProfileEditor()
                notify("Modelo selecionado.", "ok")
            end
        end)
    end
end

local function refreshProfileList()
    if not UI.ProfileList then return end
    clearChildren(UI.ProfileList, true)
    local names = {}
    for name in pairs(State.Profiles) do table.insert(names, name) end
    table.sort(names)
    if #names == 0 then
        local empty = makeText(UI.ProfileList, "Nenhum perfil configurado.", 11, Color3.fromRGB(135,135,140), Enum.Font.Gotham)
        empty.Size = UDim2.new(1, -8, 0, 30)
        return
    end
    for _, name in ipairs(names) do
        local b = Instance.new("TextButton")
        b.Text = ""
        b.AutoButtonColor = false
        b.Size = UDim2.new(1, -8, 0, 32)
        b.BackgroundColor3 = name == State.ActiveProfile and Color3.fromRGB(50, 38, 24) or Color3.fromRGB(27,27,29)
        b.Parent = UI.ProfileList
        addCorner(b, State.Theme.Rounding)
        local label = makeText(b, name, 11, name == State.ActiveProfile and State.Theme.Accent or Color3.fromRGB(220,220,220), Enum.Font.GothamMedium)
        label.Position = UDim2.fromOffset(9, 0)
        label.Size = UDim2.new(1, -18, 1, 0)
        b.Activated:Connect(function()
            State.ActiveProfile = name
            refreshProfileList()
            refreshProfileEditor()
            refreshChatProfile()
            saveStorage()
            notify("Perfil ativo: " .. name, "ok")
        end)
    end
end

function refreshProfileEditor()
    local profile = getActiveProfile()
    if not profile then
        if UI.ProfileName then UI.ProfileName.Text = "" end
        if UI.Provider then UI.Provider.Text = "" end
        if UI.APIURL then UI.APIURL.Text = "" end
        if UI.APIKey then UI.APIKey.Text = "" end
        if UI.ModelCurrent then UI.ModelCurrent.Text = "Selecione um modelo" end
        refreshModelSelector()
        return
    end
    UI.ProfileName.Text = State.ActiveProfile or ""
    UI.Provider.Text = tostring(profile.Provider or "")
    UI.APIURL.Text = tostring(profile.API_URL or "")
    UI.APIKey.Text = tostring(profile.API_KEY or "")
    UI.ModelCurrent.Text = profile.MODEL ~= "" and profile.MODEL or "Selecione um modelo"
    refreshModelSelector()
end

function refreshChatProfile()
    if not UI.ChatProfile then return end
    UI.ChatProfile.Text = State.ActiveProfile and ("IA: " .. State.ActiveProfile) or "IA: nenhuma configurada"
end

local function saveEditedProfile()
    local name = UI.ProfileName.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then notify("Informe um nome para o perfil.", "error") return end
    if State.ActiveProfile and State.ActiveProfile ~= name and State.Profiles[State.ActiveProfile] then
        State.Profiles[name] = State.Profiles[State.ActiveProfile]
        State.Profiles[State.ActiveProfile] = nil
        State.ActiveProfile = name
    end
    State.Profiles[name] = State.Profiles[name] or {
        Name = name,
        Provider = "",
        API_URL = "",
        API_KEY = "",
        MODEL = "",
    }
    local p = State.Profiles[name]
    p.Name = name
    p.Provider = UI.Provider.Text
    p.API_URL = UI.APIURL.Text
    p.API_KEY = UI.APIKey.Text
    p.MODEL = p.MODEL or ""
    State.ActiveProfile = name
    refreshProfileList()
    refreshProfileEditor()
    refreshChatProfile()
    saveStorage()
    notify("Perfil salvo.", "ok")
end

local function newProfile()
    local base = "Novo perfil"
    local n = base
    local i = 2
    while State.Profiles[n] do n = base .. " " .. i i += 1 end
    State.Profiles[n] = {Name = n, Provider = "", API_URL = "", API_KEY = "", MODEL = ""}
    State.ActiveProfile = n
    refreshProfileList()
    refreshProfileEditor()
    refreshChatProfile()
    saveStorage()
end

local function deleteProfile()
    if not State.ActiveProfile or not State.Profiles[State.ActiveProfile] then return end
    local name = State.ActiveProfile
    State.Profiles[name] = nil
    State.ActiveProfile = nil
    refreshProfileList()
    refreshProfileEditor()
    refreshChatProfile()
    saveStorage()
    notify("Perfil excluído.", "ok")
end

local function addCustomModel()
    local id = UI.CustomModelID.Text:gsub("%s+", "")
    local name = UI.CustomModelName.Text
    local provider = UI.CustomModelProvider.Text
    if id == "" then notify("Informe o Model ID.", "error") return end
    if name == "" then name = id end
    State.Models[id] = {
        ID = id,
        Name = name,
        Provider = provider ~= "" and provider or "Other",
        Price = UI.CustomModelPrice.Text ~= "" and UI.CustomModelPrice.Text or "Unknown",
        Custom = true,
    }
    saveStorage()
    UI.CustomModelID.Text = ""
    UI.CustomModelName.Text = ""
    UI.CustomModelProvider.Text = ""
    refreshModelSelector()
    notify("Modelo personalizado adicionado.", "ok")
end

local function applyVisualSettings()
    if not UI.Main then return end
    UI.Main.BackgroundTransparency = math.clamp(State.Theme.Transparency, 0, 0.9)
    if UI.MainStroke then UI.MainStroke.Color = State.Theme.Accent end
    if UI.ResizeHandle then UI.ResizeHandle.BackgroundColor3 = State.Theme.Accent end
end

local function createUI()
    local old = Services.CoreGui:FindFirstChild("AIChat")
    if old then old:Destroy() end
    if PlayerGui then
        local old2 = PlayerGui:FindFirstChild("AIChat")
        if old2 then old2:Destroy() end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "AIChat"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = Services.CoreGui
    UI.Gui = gui

    local main = Instance.new("Frame")
    main.Name = "AIChat"
    main.Size = UDim2.fromOffset(520, 420)
    main.Position = UDim2.new(0.5, -260, 0.5, -210)
    main.BackgroundColor3 = Color3.fromRGB(12,12,14)
    main.BackgroundTransparency = State.Theme.Transparency
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = gui
    addCorner(main, State.Theme.Rounding)
    UI.Main = main
    UI.MainStroke = addStroke(main, State.Theme.Accent, 1, 0.05)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1,0,0,36)
    top.BackgroundColor3 = Color3.fromRGB(18,18,20)
    top.BackgroundTransparency = 0.04
    top.BorderSizePixel = 0
    top.Parent = main
    UI.TopBar = top

    local icon = Instance.new("ImageLabel")
    icon.BackgroundTransparency = 1
    icon.Image = Icons.bot
    icon.ImageColor3 = State.Theme.Accent
    icon.Size = UDim2.fromOffset(18,18)
    icon.Position = UDim2.fromOffset(10,9)
    icon.Parent = top

    local title = makeText(top, "AIChat", 14, Color3.fromRGB(240,240,240), Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(34,0)
    title.Size = UDim2.new(1,-120,1,0)

    local min = makeButton(top, "", nil, function()
        Minimized = not Minimized
        if Minimized then
            LastNormalSize = Vector2.new(main.AbsoluteSize.X, main.AbsoluteSize.Y)
            main.Size = UDim2.fromOffset(520,36)
        else
            main.Size = UDim2.fromOffset(LastNormalSize.X, LastNormalSize.Y)
        end
        if UI.Body then UI.Body.Visible = not Minimized end
        if UI.ResizeHandle then UI.ResizeHandle.Visible = not Minimized end
    end)
    min.Size = UDim2.fromOffset(30,26)
    min.Position = UDim2.new(1,-68,0,5)
    min.BackgroundColor3 = Color3.fromRGB(40,40,43)
    local minText = makeText(min, "_", 14, Color3.fromRGB(220,220,220), Enum.Font.GothamBold)
    minText.Size = UDim2.fromScale(1,1)
    minText.TextXAlignment = Enum.TextXAlignment.Center

    local close = makeButton(top, "", "x", function()
        gui:Destroy()
    end)
    close.Size = UDim2.fromOffset(30,26)
    close.Position = UDim2.new(1,-34,0,5)
    close.BackgroundColor3 = Color3.fromRGB(45,30,25)
    close:FindFirstChildWhichIsA("ImageLabel").ImageColor3 = Color3.fromRGB(235,180,160)

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.new(1,0,1,-36)
    body.Position = UDim2.fromOffset(0,36)
    body.BackgroundTransparency = 1
    body.Parent = main
    UI.Body = body

    local tabs = Instance.new("Frame")
    tabs.Size = UDim2.new(1, -16, 0, 32)
    tabs.Position = UDim2.fromOffset(8,5)
    tabs.BackgroundTransparency = 1
    tabs.Parent = body

    UI.TabButtons = {}
    UI.TabFrames = {}
    for i, name in ipairs({"Chat","RScripts","Configurações"}) do
        local b = makeButton(tabs, name, name == "Configurações" and "settings" or name == "RScripts" and "search" or "bot", function() setTab(name) end)
        b.Size = UDim2.new(1/3, -5, 1, 0)
        b.Position = UDim2.new((i-1)/3, (i-1)*3, 0, 0)
        UI.TabButtons[name] = b
    end

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1,-16,1,-48)
    content.Position = UDim2.fromOffset(8,43)
    content.BackgroundTransparency = 1
    content.Parent = body

    local chat = Instance.new("Frame")
    chat.Size = UDim2.fromScale(1,1)
    chat.BackgroundTransparency = 1
    chat.Parent = content
    UI.TabFrames.Chat = chat

    local chatProfile = makeText(chat, "IA: nenhuma configurada", 11, Color3.fromRGB(165,165,170), Enum.Font.GothamMedium)
    chatProfile.Size = UDim2.new(1,-100,0,24)
    chatProfile.Position = UDim2.fromOffset(2,0)
    UI.ChatProfile = chatProfile

    local openSettings = makeButton(chat, "Configurar", "settings", function() setTab("Configurações") end)
    openSettings.Size = UDim2.fromOffset(96,25)
    openSettings.Position = UDim2.new(1,-96,0,0)

    local chatHist = makeScroll(chat)
    chatHist.Position = UDim2.fromOffset(0,28)
    chatHist.Size = UDim2.new(1,0,1,-118)
    UI.ChatHistory = chatHist

    local input = makeInput(chat, "Escreva uma mensagem...", true)
    input.Position = UDim2.new(0,0,1,-84)
    input.Size = UDim2.new(1,-88,0,76)
    UI.ChatInput = input

    local send = makeButton(chat, "Enviar", "send", sendChat)
    send.Size = UDim2.fromOffset(80,34)
    send.Position = UDim2.new(1,-80,1,-84)
    UI.SendButton = send

    local clear = makeButton(chat, "Limpar", nil, clearChat)
    clear.Size = UDim2.fromOffset(80,28)
    clear.Position = UDim2.new(1,-80,1,-46)

    local status = makeText(chat, "Pronto.", 10, Color3.fromRGB(150,150,155), Enum.Font.Gotham)
    status.Size = UDim2.new(1,-90,0,24)
    status.Position = UDim2.fromOffset(2,1)
    status.Visible = false
    UI.Status = status

    local rs = Instance.new("Frame")
    rs.Size = UDim2.fromScale(1,1)
    rs.BackgroundTransparency = 1
    rs.Visible = false
    rs.Parent = content
    UI.TabFrames.RScripts = rs

    local searchBox = makeInput(rs, "Pesquisar scripts...", false)
    searchBox.Position = UDim2.fromOffset(0,0)
    searchBox.Size = UDim2.new(1,-86,0,30)
    UI.RScriptsSearch = searchBox
    local searchBtn = makeButton(rs, "Pesquisar", "search", searchRScripts)
    searchBtn.Position = UDim2.new(1,-82,0,0)
    searchBtn.Size = UDim2.fromOffset(82,30)

    local current = makeButton(rs, "Jogo atual", nil, function() searchCurrentGame(false) end)
    current.Position = UDim2.fromOffset(0,36)
    current.Size = UDim2.fromOffset(92,28)
    local easy = makeButton(rs, "Mais fáceis", nil, function() searchCurrentGame(true) end)
    easy.Position = UDim2.fromOffset(98,36)
    easy.Size = UDim2.fromOffset(92,28)
    local place = makeText(rs, "PlaceId: " .. tostring(game.PlaceId), 10, Color3.fromRGB(150,150,155), Enum.Font.Code)
    place.Position = UDim2.new(1,-190,0,36)
    place.Size = UDim2.fromOffset(190,28)
    place.TextXAlignment = Enum.TextXAlignment.Right
    UI.PlaceIdLabel = place

    local results = makeScroll(rs)
    results.Position = UDim2.fromOffset(0,70)
    results.Size = UDim2.new(1,0,1,-98)
    UI.RScriptsResults = results
    local credit = makeText(rs, "Powered by Rscripts.net", 9, Color3.fromRGB(105,105,110), Enum.Font.Gotham)
    credit.Position = UDim2.new(0,0,1,-22)
    credit.Size = UDim2.new(1,0,0,18)

    local settings = Instance.new("ScrollingFrame")
    settings.Size = UDim2.fromScale(1,1)
    settings.BackgroundTransparency = 1
    settings.BorderSizePixel = 0
    settings.ScrollBarThickness = 4
    settings.ScrollBarImageColor3 = State.Theme.Accent
    settings.AutomaticCanvasSize = Enum.AutomaticSize.Y
    settings.CanvasSize = UDim2.new()
    settings.Visible = false
    settings.Parent = content
    UI.TabFrames.Configurações = settings
    local sl = Instance.new("UIListLayout")
    sl.Padding = UDim.new(0,6)
    sl.Parent = settings
    local sp = Instance.new("UIPadding")
    sp.PaddingTop = UDim.new(0,3) sp.PaddingBottom = UDim.new(0,10) sp.PaddingLeft = UDim.new(0,3) sp.PaddingRight = UDim.new(0,3)
    sp.Parent = settings

    local sec = makeText(settings, "Perfis de IA", 12, State.Theme.Accent, Enum.Font.GothamBold)
    sec.Size = UDim2.new(1,-8,0,22)

    local profileList = makeScroll(settings)
    profileList.Size = UDim2.new(1,-8,0,80)
    UI.ProfileList = profileList

    local profileActions = Instance.new("Frame")
    profileActions.Size = UDim2.new(1,-8,0,30)
    profileActions.BackgroundTransparency = 1
    profileActions.Parent = settings
    local newB = makeButton(profileActions,"Novo",nil,newProfile) newB.Size=UDim2.fromOffset(70,28)
    local saveB = makeButton(profileActions,"Salvar",nil,saveEditedProfile) saveB.Size=UDim2.fromOffset(75,28) saveB.Position=UDim2.fromOffset(76,0)
    local delB = makeButton(profileActions,"Excluir",nil,deleteProfile) delB.Size=UDim2.fromOffset(75,28) delB.Position=UDim2.fromOffset(157,0)

    local function labeledInput(labelText, placeholder, secret)
        local wrap = Instance.new("Frame") wrap.Size=UDim2.new(1,-8,0,52) wrap.BackgroundTransparency=1 wrap.Parent=settings
        local lab=makeText(wrap,labelText,10,Color3.fromRGB(155,155,160),Enum.Font.GothamMedium) lab.Size=UDim2.new(1,0,0,18)
        local box=makeInput(wrap,placeholder,false) box.Position=UDim2.fromOffset(0,19) box.Size=UDim2.new(1,0,0,30)
        if secret then box.TextXAlignment=Enum.TextXAlignment.Left end
        return box
    end

    UI.ProfileName = labeledInput("Nome", "Nome do perfil", false)
    UI.Provider = labeledInput("Provedor / família", "OpenAI, Gemini, DeepSeek, OpenRouter, etc.", false)
    UI.APIURL = labeledInput("API URL", "Endpoint Chat Completions", false)
    UI.APIKey = labeledInput("API Key", "Bearer key", true)

    local modelLabel=makeText(settings,"Modelo",10,Color3.fromRGB(155,155,160),Enum.Font.GothamMedium) modelLabel.Size=UDim2.new(1,-8,0,18)
    UI.ModelCurrent=makeText(settings,"Selecione um modelo",11,Color3.fromRGB(220,220,220),Enum.Font.Code) UI.ModelCurrent.Size=UDim2.new(1,-8,0,28)

    local modelSearch=makeInput(settings,"Pesquisar modelo...",false) modelSearch.Size=UDim2.new(1,-8,0,30) UI.ModelSearch=modelSearch
    modelSearch:GetPropertyChangedSignal("Text"):Connect(refreshModelSelector)
    local modelBtns=Instance.new("Frame") modelBtns.Size=UDim2.new(1,-8,0,30) modelBtns.BackgroundTransparency=1 modelBtns.Parent=settings
    local update=makeButton(modelBtns,"Atualizar modelos",nil,function() fetchModels(getActiveProfile()) end) update.Size=UDim2.fromOffset(130,28)
    local custom=makeButton(modelBtns,"+ Modelo personalizado",nil,function() UI.CustomPanel.Visible=not UI.CustomPanel.Visible end) custom.Size=UDim2.fromOffset(150,28) custom.Position=UDim2.fromOffset(136,0)
    local modelList=makeScroll(settings) modelList.Size=UDim2.new(1,-8,0,115) UI.ModelList=modelList

    local customPanel=Instance.new("Frame") customPanel.Size=UDim2.new(1,-8,0,155) customPanel.BackgroundColor3=Color3.fromRGB(20,20,22) customPanel.Visible=false customPanel.Parent=settings addCorner(customPanel,State.Theme.Rounding)
    UI.CustomPanel=customPanel
    local cp=Instance.new("UIListLayout") cp.Padding=UDim.new(0,4) cp.Parent=customPanel
    local cpad=Instance.new("UIPadding") cpad.PaddingTop=UDim.new(0,6) cpad.PaddingLeft=UDim.new(0,6) cpad.PaddingRight=UDim.new(0,6) cpad.Parent=customPanel
    UI.CustomModelName=labeledInput -- overwritten below
    local c1=makeInput(customPanel,"Nome",false) c1.Size=UDim2.new(1,0,0,27) UI.CustomModelName=c1
    local c2=makeInput(customPanel,"Model ID",false) c2.Size=UDim2.new(1,0,0,27) UI.CustomModelID=c2
    local c3=makeInput(customPanel,"Provedor",false) c3.Size=UDim2.new(1,0,0,27) UI.CustomModelProvider=c3
    local c4=makeInput(customPanel,"Preço: Free / Paid / Unknown",false) c4.Size=UDim2.new(1,0,0,27) UI.CustomModelPrice=c4
    local cadd=makeButton(customPanel,"Adicionar",nil,addCustomModel) cadd.Size=UDim2.fromOffset(90,28)

    local promptLabel=makeText(settings,"System Prompt",10,Color3.fromRGB(155,155,160),Enum.Font.GothamMedium) promptLabel.Size=UDim2.new(1,-8,0,18)
    local prompt=makeInput(settings,"Vazio = não enviar mensagem system",true) prompt.Size=UDim2.new(1,-8,0,72) prompt.Text=State.SystemPrompt UI.SystemPrompt=prompt
    prompt.FocusLost:Connect(function() State.SystemPrompt=prompt.Text saveStorage() end)

    local rsKey=labeledInput("RScripts API Key","rsc_live_...",true) rsKey.Text=State.RScriptsAPIKey UI.RScriptsKey=rsKey
    rsKey.FocusLost:Connect(function() State.RScriptsAPIKey=rsKey.Text saveStorage() end)

    local notice=makeText(settings,"API Keys colocadas em um script local podem ser extraídas pelo ambiente de execução. Não compartilhe suas chaves.",10,Color3.fromRGB(210,150,120),Enum.Font.Gotham) notice.TextWrapped=true notice.AutomaticSize=Enum.AutomaticSize.Y notice.Size=UDim2.new(1,-8,0,0)
    local storage=makeText(settings,hasFileAPI() and "Persistência: disponível" or "Persistência: não disponível neste ambiente",10,Color3.fromRGB(140,140,145),Enum.Font.Gotham) storage.Size=UDim2.new(1,-8,0,22)

    setTab("Chat")
    refreshProfileList()
    refreshProfileEditor()
    refreshChatProfile()
    applyVisualSettings()

    -- Drag: mouse + touch.
    local dragging=false local dragStart=nil local startPos=nil
    local function beginDrag(input)
        dragging=true dragStart=input.Position startPos=main.Position
        local conn; conn=input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then dragging=false if conn then conn:Disconnect() end end
        end)
    end
    top.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then beginDrag(input) end
    end)
    Services.UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
            local delta=input.Position-dragStart
            main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)

    -- Resize handle.
    local rh=Instance.new("TextButton") rh.Text="" rh.AutoButtonColor=false rh.Size=UDim2.fromOffset(16,16) rh.Position=UDim2.new(1,-16,1,-16) rh.BackgroundColor3=State.Theme.Accent rh.BackgroundTransparency=.35 rh.Parent=main UI.ResizeHandle=rh
    local resizing=false local resizeStart=nil local resizeSize=nil
    rh.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            resizing=true resizeStart=input.Position resizeSize=main.AbsoluteSize
        end
    end)
    Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then resizing=false end
    end)
    Services.UserInputService.InputChanged:Connect(function(input)
        if not resizing then return end
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
            local delta=input.Position-resizeStart
            local w=math.max(360,resizeSize.X+delta.X)
            local h=math.max(300,resizeSize.Y+delta.Y)
            main.Size=UDim2.fromOffset(w,h)
            LastNormalSize=Vector2.new(w,h)
        end
    end)

    UI.Gui.Destroying:Connect(function()
        for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    end)
end

-- Initialization deliberately performs no network request.
loadStorage()
createUI()
notify("Pronto.", "ok")

-- Keep selected profile/model state coherent without performing network work.
task.spawn(function()
    while UI.Gui and UI.Gui.Parent do
        task.wait(2)
        if UI.ChatProfile then refreshChatProfile() end
    end
end)
