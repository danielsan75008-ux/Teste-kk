-- AIChat - Roblox Luau - GUI compacta preta/laranja + Chat + RScripts + Configurações
-- Atende ao prompt completo: sem IA padrão, sem modelo padrão, sem chave real, sem requisição automática, arrastável, minimizável, redimensionável, perfis múltiplos, catálogo por provedor, etc.
-- Usa apenas endpoints oficiais RScripts: https://api.rscripts.net/docs/api
-- Compatível com executores (request, setclipboard, isfolder, etc) mas não quebra sem eles.

--==================================================
-- 1. Services
--==================================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- 2. Config
--==================================================
local Config = {}
Config.Window = {
    InitialSize = Vector2.new(520, 420),
    MinSize = Vector2.new(360, 300),
    DefaultAccent = Color3.fromRGB(255, 132, 0),
    Background = Color3.fromRGB(15, 15, 15),
    Background2 = Color3.fromRGB(22, 22, 22),
    Background3 = Color3.fromRGB(30, 30, 30),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(160, 160, 160),
}
Config.Providers = {"OpenAI","Google Gemini","DeepSeek","Anthropic","Qwen","Mistral","Meta / Llama","xAI / Grok","OpenRouter","Outros"}
Config.ProviderAPIUrls = {
    ["OpenAI"] = "https://api.openai.com/v1/chat/completions",
    ["Google Gemini"] = "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
    ["DeepSeek"] = "https://api.deepseek.com/chat/completions",
    ["Anthropic"] = "https://api.anthropic.com/v1/messages",
    ["Qwen"] = "https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions",
    ["Mistral"] = "https://api.mistral.ai/v1/chat/completions",
    ["Meta / Llama"] = "https://api.llama.com/compat/v1/chat/completions",
    ["xAI / Grok"] = "https://api.x.ai/v1/chat/completions",
    ["OpenRouter"] = "https://openrouter.ai/api/v1/chat/completions",
    ["Outros"] = "",
}
Config.ModelsCatalog = {
    ["OpenAI"] = {
        {id="gpt-4o", name="GPT-4o", price="Paid"},
        {id="gpt-4o-mini", name="GPT-4o Mini", price="Paid"},
        {id="gpt-4-turbo", name="GPT-4 Turbo", price="Paid"},
        {id="gpt-4", name="GPT-4", price="Paid"},
        {id="gpt-3.5-turbo", name="GPT-3.5 Turbo", price="Paid"},
        {id="o1", name="o1", price="Paid"},
        {id="o1-mini", name="o1 Mini", price="Paid"},
        {id="o3-mini", name="o3 Mini", price="Paid"},
        {id="o4-mini", name="o4 Mini", price="Paid"},
    },
    ["Google Gemini"] = {
        {id="gemini-2.0-flash", name="Gemini 2.0 Flash", price="Paid"},
        {id="gemini-2.0-flash-lite", name="Gemini 2.0 Flash Lite", price="Paid"},
        {id="gemini-1.5-pro", name="Gemini 1.5 Pro", price="Paid"},
        {id="gemini-1.5-flash", name="Gemini 1.5 Flash", price="Paid"},
        {id="gemini-2.5-pro-preview-05-06", name="Gemini 2.5 Pro Preview", price="Paid"},
        {id="gemini-2.5-flash-preview-04-17", name="Gemini 2.5 Flash Preview", price="Paid"},
        {id="gemma-3-27b-it", name="Gemma 3 27B IT", price="Unknown"},
    },
    ["DeepSeek"] = {
        {id="deepseek-chat", name="DeepSeek Chat V3", price="Paid"},
        {id="deepseek-reasoner", name="DeepSeek Reasoner R1", price="Paid"},
    },
    ["Anthropic"] = {
        {id="claude-3-5-sonnet-20241022", name="Claude 3.5 Sonnet", price="Paid"},
        {id="claude-3-5-haiku-20241022", name="Claude 3.5 Haiku", price="Paid"},
        {id="claude-3-opus-20240229", name="Claude 3 Opus", price="Paid"},
        {id="claude-3-sonnet-20240229", name="Claude 3 Sonnet", price="Paid"},
        {id="claude-3-haiku-20240307", name="Claude 3 Haiku", price="Paid"},
    },
    ["Qwen"] = {
        {id="qwen-max", name="Qwen Max", price="Paid"},
        {id="qwen-plus", name="Qwen Plus", price="Paid"},
        {id="qwen-turbo", name="Qwen Turbo", price="Paid"},
        {id="qwen2.5-72b-instruct", name="Qwen 2.5 72B", price="Paid"},
        {id="qwen2.5-32b-instruct", name="Qwen 2.5 32B", price="Paid"},
    },
    ["Mistral"] = {
        {id="mistral-large-latest", name="Mistral Large", price="Paid"},
        {id="mistral-small-latest", name="Mistral Small", price="Paid"},
        {id="codestral-latest", name="Codestral", price="Paid"},
        {id="open-mixtral-8x22b", name="Mixtral 8x22B", price="Paid"},
        {id="open-mistral-7b", name="Mistral 7B", price="Paid"},
    },
    ["Meta / Llama"] = {
        {id="meta-llama/Llama-3.3-70B-Instruct", name="Llama 3.3 70B", price="Paid"},
        {id="meta-llama/Llama-3.1-405B-Instruct", name="Llama 3.1 405B", price="Paid"},
        {id="llama-3.3-70b-versatile", name="Llama 3.3 70B Versatile", price="Paid"},
        {id="llama-3.1-8b-instant", name="Llama 3.1 8B Instant", price="Paid"},
    },
    ["xAI / Grok"] = {
        {id="grok-2-latest", name="Grok 2", price="Paid"},
        {id="grok-3", name="Grok 3", price="Paid"},
        {id="grok-3-mini", name="Grok 3 Mini", price="Paid"},
        {id="grok-beta", name="Grok Beta", price="Paid"},
    },
    ["OpenRouter"] = {},
    ["Outros"] = {},
}
Config.RScripts = {
    BaseUrl = "https://api.rscripts.net",
    SearchEndpoint = "/v1/search",
    ListEndpoint = "/v1/scripts",
    DetailEndpoint = "/v1/scripts/%s",
}
Config.Icons = {
    search = "rbxassetid://121018724060431",
    settings = "rbxassetid://80758916183665",
    message = "rbxassetid://127255077587058",
    code = "rbxassetid://107380207681249",
    copy = "rbxassetid://78979572434545",
    send = "rbxassetid://127751956873796",
    close = "rbxassetid://110786993356448",
    minus = "rbxassetid://118026365011536",
    star = "rbxassetid://136141469398409",
    trash = "rbxassetid://106723740584310",
    edit = "rbxassetid://120239476110475",
    plus = "rbxassetid://111774323017047",
    check = "rbxassetid://93898873302694",
    alert = "rbxassetid://83898160590116",
    gamepad = "rbxassetid://121607283959010",
    filter = "rbxassetid://103321376129527",
    bot = "rbxassetid://80451686744860",
}

--==================================================
-- 3. State
--==================================================
local State = {
    profiles = {}, -- {id, Name, Provider, API_URL, API_KEY, MODEL, SystemPrompt? per profile? We'll use global system prompt but allow per profile override}
    activeProfileId = nil,
    systemPrompt = "Você é um assistente especializado em programação Lua para Roblox.
Responda em português.
Seja direto e explique os erros no código.
Nunca execute código automaticamente.Você é um especialista em LuaU Roblox",
    rscriptsApiKey = "rsc_live_SyIJb6i8oRHyCtizUPKIpAG6b5ZaJLsU",
    favorites = {}, -- modelId -> true
    customModels = {}, -- list of {id, name, provider, price, apiUrl}
    chatHistory = {}, -- {role, content}
    visual = {
        accent = Config.Window.DefaultAccent,
        transparency = 0.15,
        scale = 1,
        fontSize = 14,
        rounding = 6,
        animations = true,
    },
    isMinimized = false,
    previousSize = nil,
    persistenceAvailable = false,
    httpAvailable = false,
    clipboardAvailable = false,
}

--==================================================
-- 4. Storage
--==================================================
local Storage = {}
Storage.Folder = "AIChat"
Storage.File = "AIChat/config.json"

function Storage:hasFuncs()
    local ok1 = pcall(function() return typeof(isfolder) == "function" end)
    local ok2 = pcall(function() return typeof(isfile) == "function" end)
    local ok3 = pcall(function() return typeof(readfile) == "function" end)
    local ok4 = pcall(function() return typeof(writefile) == "function" end)
    if not ok1 or not ok2 or not ok3 or not ok4 then return false end
    local s1,s2,s3,s4 = false,false,false,false
    pcall(function() s1 = typeof(isfolder)=="function" end)
    pcall(function() s2 = typeof(isfile)=="function" end)
    pcall(function() s3 = typeof(readfile)=="function" end)
    pcall(function() s4 = typeof(writefile)=="function" end)
    return s1 and s2 and s3 and s4
end

function Storage:ensureFolder()
    if not self:hasFuncs() then return false end
    local ok, res = pcall(function()
        if not isfolder(self.Folder) then
            makefolder(self.Folder)
        end
        return true
    end)
    return ok and res
end

function Storage:load()
    if not self:hasFuncs() then
        State.persistenceAvailable = false
        return nil, "persistencia nao disponivel"
    end
    local ok, exists = pcall(function() return isfile(self.File) end)
    if not ok or not exists then
        State.persistenceAvailable = true
        return nil, "arquivo nao existe"
    end
    local ok2, content = pcall(function() return readfile(self.File) end)
    if not ok2 then
        State.persistenceAvailable = false
        return nil, "falha leitura"
    end
    local ok3, decoded = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok3 then
        return nil, "json invalido"
    end
    State.persistenceAvailable = true
    -- merge
    if decoded.profiles then State.profiles = decoded.profiles end
    if decoded.activeProfileId then State.activeProfileId = decoded.activeProfileId end
    if decoded.systemPrompt ~= nil then State.systemPrompt = decoded.systemPrompt end
    if decoded.rscriptsApiKey ~= nil then State.rscriptsApiKey = decoded.rscriptsApiKey end
    if decoded.favorites then State.favorites = decoded.favorites end
    if decoded.customModels then State.customModels = decoded.customModels end
    if decoded.visual then
        if decoded.visual.accent and typeof(decoded.visual.accent)=="table" then
            local c = decoded.visual.accent
            if c.r and c.g and c.b then
                State.visual.accent = Color3.fromRGB(c.r, c.g, c.b)
            end
        elseif decoded.visual.accentHex then
            -- hex support
            local hex = decoded.visual.accentHex
            pcall(function()
                local r = tonumber(string.sub(hex,1,2),16)
                local g = tonumber(string.sub(hex,3,4),16)
                local b = tonumber(string.sub(hex,5,6),16)
                if r and g and b then State.visual.accent = Color3.fromRGB(r,g,b) end
            end)
        end
        if decoded.visual.transparency ~= nil then State.visual.transparency = decoded.visual.transparency end
        if decoded.visual.scale ~= nil then State.visual.scale = decoded.visual.scale end
        if decoded.visual.fontSize ~= nil then State.visual.fontSize = decoded.visual.fontSize end
        if decoded.visual.rounding ~= nil then State.visual.rounding = decoded.visual.rounding end
        if decoded.visual.animations ~= nil then State.visual.animations = decoded.visual.animations end
    end
    return decoded
end

function Storage:save()
    if not self:hasFuncs() then
        State.persistenceAvailable = false
        return false
    end
    self:ensureFolder()
    local toSave = {
        profiles = State.profiles,
        activeProfileId = State.activeProfileId,
        systemPrompt = State.systemPrompt,
        rscriptsApiKey = State.rscriptsApiKey,
        favorites = State.favorites,
        customModels = State.customModels,
        visual = {
            accent = {r = math.floor(State.visual.accent.R*255), g = math.floor(State.visual.accent.G*255), b = math.floor(State.visual.accent.B*255)},
            transparency = State.visual.transparency,
            scale = State.visual.scale,
            fontSize = State.visual.fontSize,
            rounding = State.visual.rounding,
            animations = State.visual.animations,
        }
    }
    local ok, json = pcall(function() return HttpService:JSONEncode(toSave) end)
    if not ok then return false end
    local ok2 = pcall(function() writefile(self.File, json) end)
    if ok2 then State.persistenceAvailable = true end
    return ok2
end

--==================================================
-- 5. HTTP Client
--==================================================
local HTTP = {}
HTTP.requestFunc = nil
HTTP.available = false

function HTTP:detect()
    local candidates = {}
    pcall(function() if typeof(request)=="function" then table.insert(candidates, request) end end)
    pcall(function() if typeof(http_request)=="function" then table.insert(candidates, http_request) end end)
    pcall(function() if typeof(syn)=="table" and typeof(syn.request)=="function" then table.insert(candidates, syn.request) end end)
    pcall(function() if typeof(http)=="table" and typeof(http.request)=="function" then table.insert(candidates, http.request) end end)
    pcall(function() if typeof(fluxus)=="table" and typeof(fluxus.request)=="function" then table.insert(candidates, fluxus.request) end end)
    pcall(function() 
        local genv = getgenv and getgenv()
        if genv and typeof(genv.request)=="function" then table.insert(candidates, genv.request) end
    end)
    if #candidates>0 then
        self.requestFunc = candidates[1]
        self.available = true
        State.httpAvailable = true
        return true
    end
    -- fallback to HttpService RequestAsync if available (may work for GET)
    local ok = pcall(function() return HttpService.RequestAsync end)
    if ok then
        self.available = true
        State.httpAvailable = true
        return true
    end
    self.available = false
    State.httpAvailable = false
    return false
end

function HTTP:request(opts)
    -- opts: Url, Method, Headers, Body
    if self.requestFunc then
        local ok, res = pcall(function() return self.requestFunc(opts) end)
        if ok and res then
            -- normalize
            if typeof(res)=="string" then
                return {Success=true, StatusCode=200, Body=res, Headers={}}
            end
            if res.Body then
                return {Success=res.Success~=false, StatusCode=res.StatusCode or 200, Body=res.Body, Headers=res.Headers or {}}
            end
            return {Success=false, StatusCode=0, Body="", Headers={}}
        else
            return {Success=false, StatusCode=0, Body=tostring(res), Headers={}}
        end
    else
        -- try RequestAsync
        local ok, res = pcall(function()
            return HttpService:RequestAsync({
                Url = opts.Url,
                Method = opts.Method or "GET",
                Headers = opts.Headers or {},
                Body = opts.Body
            })
        end)
        if ok and res then
            return {Success=res.Success, StatusCode=res.StatusCode, Body=res.Body, Headers=res.Headers}
        end
        return {Success=false, StatusCode=0, Body="HTTP não disponível neste ambiente.", Headers={}}
    end
end

function HTTP:getClipboardFunc()
    local funcs = {}
    pcall(function() if typeof(setclipboard)=="function" then table.insert(funcs, setclipboard) end end)
    pcall(function() if typeof(toclipboard)=="function" then table.insert(funcs, toclipboard) end end)
    pcall(function() if typeof(set_clipboard)=="function" then table.insert(funcs, set_clipboard) end end)
    pcall(function() 
        local genv = getgenv and getgenv()
        if genv and typeof(genv.setclipboard)=="function" then table.insert(funcs, genv.setclipboard) end
    end)
    if #funcs>0 then
        State.clipboardAvailable = true
        return funcs[1]
    end
    State.clipboardAvailable = false
    return nil
end

HTTP:detect()
local setClipboardFunc = HTTP:getClipboardFunc()

--==================================================
-- 6. AI Client
--==================================================
local AI = {}

function AI:getActiveProfile()
    if not State.activeProfileId then return nil end
    for _, p in ipairs(State.profiles) do
        if p.id == State.activeProfileId then
            return p
        end
    end
    return nil
end

function AI:validateProfile(profile)
    if not profile then return false, "Configure a IA que você vai usar nas configurações." end
    if not profile.API_URL or profile.API_URL=="" then return false, "Configure a IA que você vai usar nas configurações." end
    if not profile.API_KEY or profile.API_KEY=="" then return false, "Configure a IA que você vai usar nas configurações." end
    if not profile.MODEL or profile.MODEL=="" then return false, "Selecione um modelo nas configurações." end
    return true
end

function AI:buildMessages()
    local msgs = {}
    if State.systemPrompt and State.systemPrompt~="" then
        table.insert(msgs, {role="system", content=State.systemPrompt})
    end
    for _, m in ipairs(State.chatHistory) do
        table.insert(msgs, {role=m.role, content=m.content})
    end
    return msgs
end

function AI:send(profile, onResult)
    local valid, errMsg = self:validateProfile(profile)
    if not valid then
        onResult(false, errMsg)
        return
    end
    if not HTTP.available then
        onResult(false, "HTTP não disponível neste ambiente.")
        return
    end
    local messages = self:buildMessages()
    local bodyTable = {
        model = profile.MODEL,
        messages = messages,
    }
    local okBody, bodyJson = pcall(function() return HttpService:JSONEncode(bodyTable) end)
    if not okBody then
        onResult(false, "Erro ao codificar requisição.")
        return
    end
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer "..profile.API_KEY,
    }
    local opts = {
        Url = profile.API_URL,
        Method = "POST",
        Headers = headers,
        Body = bodyJson,
    }
    local res = HTTP:request(opts)
    if not res.Success then
        -- map status
        local code = res.StatusCode or 0
        local msg = res.Body or ""
        if code==401 then
            onResult(false, "API Key inválida ou não autorizada (401). Verifique sua chave.")
        elseif code==403 then
            onResult(false, "Acesso negado (403). Verifique permissões da chave.")
        elseif code==404 then
            onResult(false, "Endpoint ou modelo não encontrado (404). Verifique API URL e modelo.")
        elseif code==429 then
            onResult(false, "Limite de requisições atingido (429). Tente novamente em breve.")
        elseif code==0 then
            onResult(false, "Erro de conexão ou HTTP indisponível. "..tostring(msg):sub(1,200))
        else
            -- try parse error message without leaking key
            local parsedOk, parsed = pcall(function() return HttpService:JSONDecode(msg) end)
            if parsedOk and parsed and parsed.error and parsed.error.message then
                local safeMsg = tostring(parsed.error.message)
                -- remove key if appears
                if profile.API_KEY and safeMsg:find(profile.API_KEY) then
                    safeMsg = safeMsg:gsub(profile.API_KEY, "[REDACTED]")
                end
                onResult(false, "Erro API ("..code.."): "..safeMsg:sub(1,300))
            else
                onResult(false, "Erro HTTP ("..code.."): "..tostring(msg):sub(1,300))
            end
        end
        return
    end
    local okParse, decoded = pcall(function() return HttpService:JSONDecode(res.Body) end)
    if not okParse then
        onResult(false, "Resposta inválida da API (JSON inválido).")
        return
    end
    if not decoded.choices or #decoded.choices==0 then
        -- check anthropic format? anthropic uses content
        if decoded.content and type(decoded.content)=="table" and decoded.content[1] and decoded.content[1].text then
            onResult(true, decoded.content[1].text)
            return
        end
        onResult(false, "Resposta sem choices.")
        return
    end
    local choice = decoded.choices[1]
    if not choice.message then
        onResult(false, "Resposta sem message.")
        return
    end
    if not choice.message.content or choice.message.content=="" then
        -- some apis use delta?
        if choice.message.content==nil then
            onResult(false, "Resposta sem content.")
            return
        end
    end
    onResult(true, choice.message.content)
end

--==================================================
-- 7. RScripts Client (only official endpoints)
--==================================================
local RScripts = {}

function RScripts:ensureKey()
    if not State.rscriptsApiKey or State.rscriptsApiKey=="" then
        return false, "Configure sua RScripts API Key nas configurações."
    end
    return true
end

function RScripts:buildUrl(endpoint, params)
    local url = Config.RScripts.BaseUrl..endpoint
    if params and next(params) then
        local qs = {}
        for k,v in pairs(params) do
            if v~=nil and v~="" then
                table.insert(qs, HttpService:UrlEncode(tostring(k)).."="..HttpService:UrlEncode(tostring(v)))
            end
        end
        if #qs>0 then
            url = url.."?"..table.concat(qs,"&")
        end
    end
    return url
end

function RScripts:request(endpoint, params, method)
    local okKey, errKey = self:ensureKey()
    if not okKey then return false, errKey end
    if not HTTP.available then return false, "HTTP não disponível neste ambiente." end
    local url = self:buildUrl(endpoint, params)
    local headers = {
        ["Authorization"] = "Bearer "..State.rscriptsApiKey,
    }
    local opts = {
        Url = url,
        Method = method or "GET",
        Headers = headers,
    }
    local res = HTTP:request(opts)
    if not res.Success then
        local code = res.StatusCode or 0
        if code==401 then return false, "RScripts API Key inválida (401)." end
        if code==403 then return false, "Acesso negado RScripts (403)." end
        if code==404 then return false, "Recurso não encontrado RScripts (404)." end
        if code==429 then return false, "Rate limit RScripts (429). Aguarde." end
        return false, "Erro RScripts HTTP ("..code.."): "..tostring(res.Body):sub(1,300)
    end
    local okParse, decoded = pcall(function() return HttpService:JSONDecode(res.Body) end)
    if not okParse then return false, "Resposta RScripts inválida (JSON)." end
    if decoded.success==false then
        local msg = decoded.error and decoded.error.message or "erro desconhecido"
        return false, "RScripts erro: "..tostring(msg)
    end
    return true, decoded
end

function RScripts:search(query, limit)
    limit = limit or 10
    return self:request(Config.RScripts.SearchEndpoint, {q=query, index="scripts", limit=limit})
end

function RScripts:listByPlaceId(placeId, filters)
    filters = filters or {}
    local params = {placeId=tostring(placeId), page=filters.page or 1, limit=filters.limit or 20, sort=filters.sort or "recommended"}
    if filters.noKeySystem then params.noKeySystem = "true" end
    if filters.freeOnly then params.freeOnly = "true" end
    if filters.q and filters.q~="" then params.q = filters.q end
    return self:request(Config.RScripts.ListEndpoint, params)
end

function RScripts:getDetail(slug)
    local endpoint = string.format(Config.RScripts.DetailEndpoint, HttpService:UrlEncode(slug))
    return self:request(endpoint, {})
end

function RScripts:fetchRawScript(rawUrl)
    if not HTTP.available then return false, "HTTP não disponível" end
    local opts = {Url=rawUrl, Method="GET"}
    local res = HTTP:request(opts)
    if not res.Success then return false, "Falha ao buscar código raw: "..tostring(res.StatusCode) end
    return true, res.Body
end

function RScripts:getCodeFromDetailData(data)
    -- data is decoded.data from detail endpoint
    if not data then return false, "dados vazios" end
    if data.script and data.script~="" then
        return true, data.script
    end
    if data.rawScript and data.rawScript~="" then
        return self:fetchRawScript(data.rawScript)
    end
    return false, "Código não disponível"
end

--==================================================
-- 8. GUI Helpers
--==================================================
local GUI = {}
GUI.elements = {}

function GUI:createCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or State.visual.rounding or 6)
    c.Parent = parent
    return c
end

function GUI:createStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or State.visual.accent
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

function GUI:createButton(parent, text, size, bgColor)
    local b = Instance.new("TextButton")
    b.Size = size or UDim2.new(0, 80, 0, 28)
    b.BackgroundColor3 = bgColor or State.visual.accent
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = State.visual.fontSize
    b.Font = Enum.Font.GothamSemibold
    b.AutoButtonColor = true
    b.Parent = parent
    self:createCorner(b, 6)
    return b
end

function GUI:createTextLabel(parent, text, size, textSize, color, align)
    local l = Instance.new("TextLabel")
    l.Size = size or UDim2.new(1,0,0,20)
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextColor3 = color or Config.Window.Text
    l.TextSize = textSize or State.visual.fontSize
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.Parent = parent
    return l
end

function GUI:createTextBox(parent, placeholder, size, multi)
    local tb = Instance.new("TextBox")
    tb.Size = size or UDim2.new(1,0,0,28)
    tb.BackgroundColor3 = Config.Window.Background3
    tb.Text = ""
    tb.PlaceholderText = placeholder or ""
    tb.TextColor3 = Config.Window.Text
    tb.PlaceholderColor3 = Config.Window.TextDim
    tb.TextSize = State.visual.fontSize
    tb.Font = Enum.Font.Gotham
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.ClearTextOnFocus = false
    tb.TextWrapped = multi and true or false
    tb.MultiLine = multi and true or false
    tb.Parent = parent
    self:createCorner(tb, 6)
    self:createStroke(tb, Config.Window.Background3, 1)
    return tb
end

function GUI:truncate(s, n)
    if not s then return "" end
    if #s <= n then return s end
    return string.sub(s,1,n).."..."
end

function GUI:safeSetClipboard(text)
    if not setClipboardFunc then
        return false, "setclipboard não está disponível neste ambiente."
    end
    local ok, err = pcall(function() setClipboardFunc(text) end)
    if ok then return true end
    return false, tostring(err)
end

--==================================================
-- 9. Main GUI Construction
--==================================================
local MainGui = {}
MainGui.connections = {}

function MainGui:destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

function MainGui:create()
    -- parent detection
    local parentGui = nil
    local okHui, hui = pcall(function() return gethui and gethui() or (get_hidden_gui and get_hidden_gui()) end)
    if okHui and hui then
        parentGui = hui
    else
        local okCore, core = pcall(function() return CoreGui end)
        if okCore then
            -- try CoreGui, may fail in some executors
            local okTest = pcall(function() local sg = Instance.new("ScreenGui") sg.Parent = core sg:Destroy() end)
            if okTest then parentGui = core end
        end
    end
    if not parentGui and LocalPlayer then
        local okPg, pg = pcall(function() return LocalPlayer:WaitForChild("PlayerGui") end)
        if okPg then parentGui = pg end
    end
    if not parentGui then
        parentGui = CoreGui -- last attempt
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "AIChat"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true
    sg.Parent = parentGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, Config.Window.InitialSize.X, 0, Config.Window.InitialSize.Y)
    mainFrame.Position = UDim2.new(0.5, -Config.Window.InitialSize.X/2, 0.5, -Config.Window.InitialSize.Y/2)
    mainFrame.BackgroundColor3 = Config.Window.Background
    mainFrame.BackgroundTransparency = State.visual.transparency
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = false
    mainFrame.Parent = sg

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = State.visual.scale
    uiScale.Parent = mainFrame

    GUI:createCorner(mainFrame, State.visual.rounding+2)
    local mainStroke = GUI:createStroke(mainFrame, State.visual.accent, 1.2, 0)
    mainStroke.Name = "AccentStroke"

    -- TopBar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1,0,0,32)
    topBar.BackgroundColor3 = Config.Window.Background2
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame
    GUI:createCorner(topBar, State.visual.rounding)
    -- fix corner bottom
    local topFix = Instance.new("Frame")
    topFix.Size = UDim2.new(1,0,0,10)
    topFix.Position = UDim2.new(0,0,1,-10)
    topFix.BackgroundColor3 = Config.Window.Background2
    topFix.BorderSizePixel = 0
    topFix.Parent = topBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1,-100,1,0)
    titleLabel.Position = UDim2.new(0,12,0,0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "AIChat"
    titleLabel.TextColor3 = Config.Window.Text
    titleLabel.TextSize = 15
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = topBar

    local btnMin = Instance.new("TextButton")
    btnMin.Name = "Minimize"
    btnMin.Size = UDim2.new(0,28,0,22)
    btnMin.Position = UDim2.new(1,-62,0,5)
    btnMin.BackgroundColor3 = Config.Window.Background3
    btnMin.Text = "-"
    btnMin.TextColor3 = Config.Window.Text
    btnMin.TextSize = 16
    btnMin.Font = Enum.Font.GothamBold
    btnMin.Parent = topBar
    GUI:createCorner(btnMin, 4)

    local btnClose = Instance.new("TextButton")
    btnClose.Name = "Close"
    btnClose.Size = UDim2.new(0,28,0,22)
    btnClose.Position = UDim2.new(1,-30,0,5)
    btnClose.BackgroundColor3 = Color3.fromRGB(180,40,40)
    btnClose.Text = "X"
    btnClose.TextColor3 = Color3.new(1,1,1)
    btnClose.TextSize = 12
    btnClose.Font = Enum.Font.GothamBold
    btnClose.Parent = topBar
    GUI:createCorner(btnClose, 4)

    -- Tabs bar
    local tabsBar = Instance.new("Frame")
    tabsBar.Name = "TabsBar"
    tabsBar.Size = UDim2.new(1,0,0,32)
    tabsBar.Position = UDim2.new(0,0,0,32)
    tabsBar.BackgroundColor3 = Config.Window.Background2
    tabsBar.BorderSizePixel = 0
    tabsBar.Parent = mainFrame

    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.FillDirection = Enum.FillDirection.Horizontal
    tabsLayout.Padding = UDim.new(0,4)
    tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabsLayout.Parent = tabsBar

    local tabsPadding = Instance.new("UIPadding")
    tabsPadding.PaddingLeft = UDim.new(0,6)
    tabsPadding.PaddingTop = UDim.new(0,4)
    tabsPadding.PaddingBottom = UDim.new(0,4)
    tabsPadding.Parent = tabsBar

    local function createTab(name, layoutOrder)
        local btn = Instance.new("TextButton")
        btn.Name = name.."Tab"
        btn.Size = UDim2.new(0, 90, 1, 0)
        btn.BackgroundColor3 = Config.Window.Background3
        btn.Text = name
        btn.TextColor3 = Config.Window.TextDim
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamSemibold
        btn.LayoutOrder = layoutOrder
        btn.Parent = tabsBar
        GUI:createCorner(btn, 5)
        return btn
    end

    local tabChatBtn = createTab("Chat",1)
    local tabRScriptsBtn = createTab("RScripts",2)
    local tabSettingsBtn = createTab("Configurações",3)
    tabSettingsBtn.Size = UDim2.new(0,110,1,0)

    -- Content
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1,-12,1,-32-32-12)
    contentFrame.Position = UDim2.new(0,6,0,32+32+6)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    -- Pages
    local pageChat = Instance.new("Frame")
    pageChat.Name = "PageChat"
    pageChat.Size = UDim2.new(1,0,1,0)
    pageChat.BackgroundTransparency = 1
    pageChat.Visible = true
    pageChat.Parent = contentFrame

    local pageRScripts = Instance.new("Frame")
    pageRScripts.Name = "PageRScripts"
    pageRScripts.Size = UDim2.new(1,0,1,0)
    pageRScripts.BackgroundTransparency = 1
    pageRScripts.Visible = false
    pageRScripts.Parent = contentFrame

    local pageSettings = Instance.new("Frame")
    pageSettings.Name = "PageSettings"
    pageSettings.Size = UDim2.new(1,0,1,0)
    pageSettings.BackgroundTransparency = 1
    pageSettings.Visible = false
    pageSettings.Parent = contentFrame

    -- Resize handle
    local resizeHandle = Instance.new("TextButton")
    resizeHandle.Name = "ResizeHandle"
    resizeHandle.Size = UDim2.new(0,20,0,20)
    resizeHandle.Position = UDim2.new(1,-20,1,-20)
    resizeHandle.BackgroundTransparency = 1
    resizeHandle.Text = "◢"
    resizeHandle.TextColor3 = Config.Window.TextDim
    resizeHandle.TextSize = 14
    resizeHandle.Font = Enum.Font.GothamBold
    resizeHandle.ZIndex = 10
    resizeHandle.Parent = mainFrame

    -- store refs
    self.ScreenGui = sg
    self.MainFrame = mainFrame
    self.UIScale = uiScale
    self.TopBar = topBar
    self.TabsBar = tabsBar
    self.Content = contentFrame
    self.Pages = {Chat=pageChat, RScripts=pageRScripts, Settings=pageSettings}
    self.TabButtons = {Chat=tabChatBtn, RScripts=tabRScriptsBtn, Settings=tabSettingsBtn}
    self.ResizeHandle = resizeHandle
    self.MainStroke = mainStroke
    self.BtnMin = btnMin
    self.BtnClose = btnClose

    -- close logic
    btnClose.MouseButton1Click:Connect(function()
        sg:Destroy()
    end)

    -- tab switching
    local function setActiveTab(name)
        for k,v in pairs(self.Pages) do
            v.Visible = (k==name)
        end
        for k,btn in pairs(self.TabButtons) do
            if k==name then
                btn.BackgroundColor3 = State.visual.accent
                btn.TextColor3 = Color3.new(1,1,1)
            else
                btn.BackgroundColor3 = Config.Window.Background3
                btn.TextColor3 = Config.Window.TextDim
            end
        end
    end
    tabChatBtn.MouseButton1Click:Connect(function() setActiveTab("Chat") end)
    tabRScriptsBtn.MouseButton1Click:Connect(function() setActiveTab("RScripts") end)
    tabSettingsBtn.MouseButton1Click:Connect(function() setActiveTab("Settings") end)

    self.setActiveTab = setActiveTab

    -- minimize logic
    local minimized = false
    local prevSize = mainFrame.Size
    local function setMinimized(state)
        minimized = state
        State.isMinimized = state
        if state then
            prevSize = mainFrame.Size
            State.previousSize = prevSize
            local targetSize = UDim2.new(prevSize.X.Scale, prevSize.X.Offset, 0, topBar.Size.Y.Offset)
            if State.visual.animations then
                local tween = TweenService:Create(mainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size=targetSize})
                tween:Play()
            else
                mainFrame.Size = targetSize
            end
            tabsBar.Visible = false
            contentFrame.Visible = false
            resizeHandle.Visible = false
        else
            local targetSize = State.previousSize or UDim2.new(0, Config.Window.InitialSize.X, 0, Config.Window.InitialSize.Y)
            if State.visual.animations then
                local tween = TweenService:Create(mainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size=targetSize})
                tween:Play()
                tween.Completed:Connect(function()
                    tabsBar.Visible = true
                    contentFrame.Visible = true
                    resizeHandle.Visible = true
                end)
            else
                mainFrame.Size = targetSize
                tabsBar.Visible = true
                contentFrame.Visible = true
                resizeHandle.Visible = true
            end
        end
    end
    btnMin.MouseButton1Click:Connect(function()
        setMinimized(not minimized)
    end)
    self.setMinimized = setMinimized

    -- drag logic
    do
        local dragging = false
        local dragStart, startPos
        topBar.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = mainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState==Enum.UserInputState.End then dragging=false end
                end)
            end
        end)
        topBar.InputChanged:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
                if dragging then
                    local delta = input.Position - dragStart
                    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
                end
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
            end
        end)
    end

    -- resize logic
    do
        local resizing=false
        local resizeStart, startSize
        resizeHandle.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                resizing=true
                resizeStart=input.Position
                startSize=mainFrame.Size
                input.Changed:Connect(function()
                    if input.UserInputState==Enum.UserInputState.End then resizing=false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if resizing and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
                local delta = input.Position - resizeStart
                local newX = math.max(Config.Window.MinSize.X, startSize.X.Offset + delta.X)
                local newY = math.max(Config.Window.MinSize.Y, startSize.Y.Offset + delta.Y)
                mainFrame.Size = UDim2.new(0, newX, 0, newY)
            end
        end)
    end

    return self
end

--==================================================
-- 10. Chat Tab
--==================================================
local ChatTab = {}
function ChatTab:setup(mainGui)
    local page = mainGui.Pages.Chat
    -- Top selector row
    local selectorRow = Instance.new("Frame")
    selectorRow.Name = "SelectorRow"
    selectorRow.Size = UDim2.new(1,0,0,32)
    selectorRow.BackgroundTransparency = 1
    selectorRow.Parent = page

    local selectorLayout = Instance.new("UIListLayout")
    selectorLayout.FillDirection = Enum.FillDirection.Horizontal
    selectorLayout.Padding = UDim.new(0,6)
    selectorLayout.Parent = selectorRow

    local profileLabel = GUI:createTextLabel(selectorRow, "IA:", UDim2.new(0,30,1,0), 12, Config.Window.TextDim, Enum.TextXAlignment.Left)

    local profileDropdownBtn = GUI:createButton(selectorRow, "Nenhum perfil", UDim2.new(0,140,0,28), Config.Window.Background3)
    profileDropdownBtn.Name = "ProfileDropdown"
    profileDropdownBtn.TextSize = 12

    local modelLabel = GUI:createTextLabel(selectorRow, "Modelo:", UDim2.new(0,50,1,0), 12, Config.Window.TextDim, Enum.TextXAlignment.Left)
    local modelDisplay = GUI:createTextLabel(selectorRow, "Selecione um modelo", UDim2.new(0,160,1,0), 12, Config.Window.Text, Enum.TextXAlignment.Left)
    modelDisplay.Name = "ModelDisplay"

    -- History
    local historyFrame = Instance.new("ScrollingFrame")
    historyFrame.Name = "History"
    historyFrame.Size = UDim2.new(1,0,1,-32-70-8)
    historyFrame.Position = UDim2.new(0,0,0,32+4)
    historyFrame.BackgroundColor3 = Config.Window.Background2
    historyFrame.BackgroundTransparency = 0.2
    historyFrame.BorderSizePixel = 0
    historyFrame.CanvasSize = UDim2.new(0,0,0,0)
    historyFrame.ScrollBarThickness = 4
    historyFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    historyFrame.Parent = page
    GUI:createCorner(historyFrame, 6)
    GUI:createStroke(historyFrame, Config.Window.Background3, 1)

    local historyLayout = Instance.new("UIListLayout")
    historyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    historyLayout.Padding = UDim.new(0,6)
    historyLayout.Parent = historyFrame

    local historyPadding = Instance.new("UIPadding")
    historyPadding.PaddingAll = UDim.new(0,6)
    historyPadding.Parent = historyFrame

    -- Input area
    local inputArea = Instance.new("Frame")
    inputArea.Name = "InputArea"
    inputArea.Size = UDim2.new(1,0,0,70)
    inputArea.Position = UDim2.new(0,0,1,-70)
    inputArea.BackgroundTransparency = 1
    inputArea.Parent = page

    local inputBox = GUI:createTextBox(inputArea, "Digite sua mensagem...", UDim2.new(1,-90,0,48), true)
    inputBox.Name = "InputBox"
    inputBox.Position = UDim2.new(0,0,0,0)
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.TextYAlignment = Enum.TextYAlignment.Top

    local btnSend = GUI:createButton(inputArea, "Enviar", UDim2.new(0,80,0,28), State.visual.accent)
    btnSend.Name = "Send"
    btnSend.Position = UDim2.new(1,-80,0,0)

    local btnClear = GUI:createButton(inputArea, "Limpar", UDim2.new(0,80,0,28), Config.Window.Background3)
    btnClear.Name = "Clear"
    btnClear.Position = UDim2.new(1,-80,0,32)

    local statusLabel = GUI:createTextLabel(inputArea, "", UDim2.new(1,-90,0,18), 11, Config.Window.TextDim, Enum.TextXAlignment.Left)
    statusLabel.Position = UDim2.new(0,0,0,50)
    statusLabel.Name = "Status"

    -- profile dropdown list (popup)
    local dropdownList = Instance.new("ScrollingFrame")
    dropdownList.Name = "DropdownList"
    dropdownList.Size = UDim2.new(0,200,0,150)
    dropdownList.Position = UDim2.new(0,40,0,28)
    dropdownList.BackgroundColor3 = Config.Window.Background3
    dropdownList.BorderSizePixel = 0
    dropdownList.Visible = false
    dropdownList.ZIndex = 20
    dropdownList.CanvasSize = UDim2.new(0,0,0,0)
    dropdownList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    dropdownList.ScrollBarThickness = 4
    dropdownList.Parent = selectorRow
    GUI:createCorner(dropdownList, 6)
    GUI:createStroke(dropdownList, State.visual.accent, 1)

    local ddLayout = Instance.new("UIListLayout")
    ddLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ddLayout.Padding = UDim.new(0,2)
    ddLayout.Parent = dropdownList

    local function refreshProfileDropdown()
        for _,c in ipairs(dropdownList:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _,p in ipairs(State.profiles) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1,-4,0,24)
            btn.BackgroundColor3 = Config.Window.Background2
            btn.Text = p.Name.." ("..(p.Provider or "?")..")"
            btn.TextColor3 = Config.Window.Text
            btn.TextSize = 12
            btn.Font = Enum.Font.Gotham
            btn.Parent = dropdownList
            GUI:createCorner(btn,4)
            btn.MouseButton1Click:Connect(function()
                State.activeProfileId = p.id
                profileDropdownBtn.Text = p.Name
                modelDisplay.Text = p.MODEL or "Selecione um modelo"
                dropdownList.Visible = false
                Storage:save()
            end)
        end
        if #State.profiles==0 then
            local lbl = GUI:createTextLabel(dropdownList, "Nenhum perfil criado", UDim2.new(1,0,0,24), 12, Config.Window.TextDim)
        end
    end

    profileDropdownBtn.MouseButton1Click:Connect(function()
        refreshProfileDropdown()
        dropdownList.Visible = not dropdownList.Visible
    end)

    -- add message function
    local function addMessage(role, content, isError)
        local msgFrame = Instance.new("Frame")
        msgFrame.Size = UDim2.new(1,-6,0,0)
        msgFrame.AutomaticSize = Enum.AutomaticSize.Y
        msgFrame.BackgroundColor3 = (role=="user") and Color3.fromRGB(28,28,28) or Color3.fromRGB(20,20,20)
        if isError then msgFrame.BackgroundColor3 = Color3.fromRGB(60,20,20) end
        msgFrame.BorderSizePixel = 0
        msgFrame.Parent = historyFrame
        GUI:createCorner(msgFrame, 6)
        GUI:createStroke(msgFrame, (role=="user") and Config.Window.Background3 or State.visual.accent, 1, 0.5)

        local roleLabel = GUI:createTextLabel(msgFrame, (role=="user" and "Usuario" or (isError and "Sistema" or "IA"))..":", UDim2.new(1,-10,0,18), 11, (role=="user" and Config.Window.TextDim or State.visual.accent), Enum.TextXAlignment.Left)
        roleLabel.Position = UDim2.new(0,6,0,2)
        roleLabel.Font = Enum.Font.GothamBold

        local contentLabel = GUI:createTextLabel(msgFrame, content, UDim2.new(1,-12,0,0), State.visual.fontSize, Config.Window.Text, Enum.TextXAlignment.Left)
        contentLabel.Name = "Content"
        contentLabel.Position = UDim2.new(0,6,0,20)
        contentLabel.AutomaticSize = Enum.AutomaticSize.Y
        contentLabel.TextWrapped = true
        -- calculate height via TextService? AutomaticSize will handle

        -- copy button for IA
        if role~="user" then
            local copyBtn = GUI:createButton(msgFrame, "Copiar", UDim2.new(0,50,0,20), Config.Window.Background3)
            copyBtn.Position = UDim2.new(1,-56,0,2)
            copyBtn.TextSize = 11
            copyBtn.MouseButton1Click:Connect(function()
                local ok, err = GUI:safeSetClipboard(content)
                if not ok then
                    statusLabel.Text = err
                else
                    statusLabel.Text = "Copiado!"
                    task.delay(2, function() if statusLabel then statusLabel.Text="" end end)
                end
            end)
        end

        -- if error is config message, add button Abrir configurações
        if isError and content:find("Configure a IA") then
            local openBtn = GUI:createButton(msgFrame, "Abrir configurações", UDim2.new(0,140,0,24), State.visual.accent)
            openBtn.Position = UDim2.new(0,6,1,-28)
            openBtn.TextSize = 12
            openBtn.MouseButton1Click:Connect(function()
                mainGui.setActiveTab("Settings")
            end)
            -- need extra padding
            local pad = Instance.new("Frame")
            pad.Size = UDim2.new(1,0,0,30)
            pad.BackgroundTransparency = 1
            pad.Parent = msgFrame
        end

        task.wait()
        historyFrame.CanvasPosition = Vector2.new(0, historyFrame.AbsoluteCanvasSize.Y)
    end

    local function clearHistory()
        for _,c in ipairs(historyFrame:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        State.chatHistory = {}
    end

    local function setStatus(txt)
        statusLabel.Text = txt or ""
    end

    local sending = false
    local function onSend()
        if sending then return end
        local text = inputBox.Text
        if not text or text:gsub("%s","")=="" then return end
        local profile = AI:getActiveProfile()
        local valid, errMsg = AI:validateProfile(profile)
        if not valid then
            addMessage("system", errMsg, true)
            return
        end
        -- add user to history
        addMessage("user", text)
        table.insert(State.chatHistory, {role="user", content=text})
        inputBox.Text = ""
        sending = true
        btnSend.Text = "..."
        btnSend.AutoButtonColor = false
        setStatus("Enviando...")
        task.spawn(function()
            AI:send(profile, function(success, result)
                sending = false
                btnSend.Text = "Enviar"
                btnSend.AutoButtonColor = true
                setStatus("")
                if success then
                    addMessage("assistant", result)
                    table.insert(State.chatHistory, {role="assistant", content=result})
                else
                    addMessage("system", result, true)
                end
            end)
        end)
    end

    btnSend.MouseButton1Click:Connect(onSend)
    inputBox.FocusLost:Connect(function(enter)
        if enter then onSend() end
    end)
    btnClear.MouseButton1Click:Connect(function()
        clearHistory()
    end)

    -- public API for external (RScripts send to IA)
    local api = {}
    api.addMessage = addMessage
    api.clearHistory = clearHistory
    api.setStatus = setStatus
    api.refreshProfileDropdown = refreshProfileDropdown
    api.profileDropdownBtn = profileDropdownBtn
    api.modelDisplay = modelDisplay
    api.inputBox = inputBox
    api.historyFrame = historyFrame

    function api:updateActiveProfileDisplay()
        local p = AI:getActiveProfile()
        if p then
            profileDropdownBtn.Text = p.Name
            modelDisplay.Text = p.MODEL or "Selecione um modelo"
        else
            profileDropdownBtn.Text = "Nenhum perfil"
            modelDisplay.Text = "Selecione um modelo"
        end
    end

    function api:prepareAnalysisPrompt(code, title)
        local prompt = string.format("Analise este script do RScripts. Explique o que ele faz, identifique riscos e descreva as partes importantes. Não execute nada automaticamente:\n\n-- %s\n\n%s", title or "Script", code)
        inputBox.Text = prompt
        mainGui.setActiveTab("Chat")
        addMessage("system", "Script carregado para análise. Clique Enviar para enviar à IA.", false)
    end

    -- initial refresh
    refreshProfileDropdown()
    api:updateActiveProfileDisplay()

    self.api = api
    return api
end

--==================================================
-- 11. RScripts Tab
--==================================================
local RScriptsTab = {}
function RScriptsTab:setup(mainGui, chatApi)
    local page = mainGui.Pages.RScripts

    local searchRow = Instance.new("Frame")
    searchRow.Size = UDim2.new(1,0,0,32)
    searchRow.BackgroundTransparency = 1
    searchRow.Parent = page

    local searchBox = GUI:createTextBox(searchRow, "Pesquisar scripts...", UDim2.new(1,-86,0,28), false)
    searchBox.Name = "SearchBox"
    searchBox.Position = UDim2.new(0,0,0,0)

    local btnSearch = GUI:createButton(searchRow, "Pesquisar", UDim2.new(0,80,0,28), State.visual.accent)
    btnSearch.Position = UDim2.new(1,-80,0,0)

    local filterRow = Instance.new("Frame")
    filterRow.Size = UDim2.new(1,0,0,28)
    filterRow.Position = UDim2.new(0,0,0,36)
    filterRow.BackgroundTransparency = 1
    filterRow.Parent = page

    local filterLayout = Instance.new("UIListLayout")
    filterLayout.FillDirection = Enum.FillDirection.Horizontal
    filterLayout.Padding = UDim.new(0,6)
    filterLayout.Parent = filterRow

    local btnCurrent = GUI:createButton(filterRow, "Jogo atual", UDim2.new(0,90,0,24), Config.Window.Background3)
    btnCurrent.TextSize = 12
    local btnEasy = GUI:createButton(filterRow, "Mais fáceis", UDim2.new(0,90,0,24), Config.Window.Background3)
    btnEasy.TextSize = 12

    local placeLabel = GUI:createTextLabel(filterRow, "PlaceId: "..tostring(game.PlaceId or 0), UDim2.new(0,160,0,24), 11, Config.Window.TextDim)

    local creditLabel = GUI:createTextLabel(page, "Powered by Rscripts.net - https://rscripts.net/docs/api", UDim2.new(1,0,0,16), 10, Config.Window.TextDim, Enum.TextXAlignment.Left)
    creditLabel.Position = UDim2.new(0,0,1,-16)

    local resultsFrame = Instance.new("ScrollingFrame")
    resultsFrame.Name = "Results"
    resultsFrame.Size = UDim2.new(1,0,1,-36-28-20)
    resultsFrame.Position = UDim2.new(0,0,0,68)
    resultsFrame.BackgroundColor3 = Config.Window.Background2
    resultsFrame.BackgroundTransparency = 0.2
    resultsFrame.BorderSizePixel = 0
    resultsFrame.CanvasSize = UDim2.new(0,0,0,0)
    resultsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    resultsFrame.ScrollBarThickness = 4
    resultsFrame.Parent = page
    GUI:createCorner(resultsFrame, 6)
    GUI:createStroke(resultsFrame, Config.Window.Background3, 1)

    local resultsLayout = Instance.new("UIListLayout")
    resultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    resultsLayout.Padding = UDim.new(0,6)
    resultsLayout.Parent = resultsFrame

    local resultsPadding = Instance.new("UIPadding")
    resultsPadding.PaddingAll = UDim.new(0,6)
    resultsPadding.Parent = resultsFrame

    local statusLabel = GUI:createTextLabel(page, "", UDim2.new(1,0,0,18), 11, Config.Window.TextDim)
    statusLabel.Position = UDim2.new(0,0,0,0)
    statusLabel.Visible = false -- we will use as overlay? Actually place inside results top

    local function clearResults()
        for _,c in ipairs(resultsFrame:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
    end

    local function createCard(scriptData)
        -- scriptData from API: title, slug, description, views, likes, risk, game, creator, isKeySystem, isPaid etc
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1,-6,0,0)
        card.AutomaticSize = Enum.AutomaticSize.Y
        card.BackgroundColor3 = Config.Window.Background3
        card.BorderSizePixel = 0
        card.Parent = resultsFrame
        GUI:createCorner(card, 6)
        GUI:createStroke(card, Config.Window.Background2, 1)

        local title = GUI:createTextLabel(card, scriptData.title or "Sem título", UDim2.new(1,-12,0,20), 13, Config.Window.Text, Enum.TextXAlignment.Left)
        title.Position = UDim2.new(0,6,0,4)
        title.Font = Enum.Font.GothamBold

        local slugLbl = GUI:createTextLabel(card, "slug: "..(scriptData.slug or "?"), UDim2.new(1,-12,0,14), 10, Config.Window.TextDim)
        slugLbl.Position = UDim2.new(0,6,0,24)

        local author = scriptData.creator and scriptData.creator.username or scriptData.author or "?"
        local authorLbl = GUI:createTextLabel(card, "Autor: "..author, UDim2.new(1,-12,0,14), 10, Config.Window.TextDim)
        authorLbl.Position = UDim2.new(0,6,0,38)

        local desc = GUI:createTextLabel(card, GUI:truncate(scriptData.description or "", 180), UDim2.new(1,-12,0,0), 11, Config.Window.Text)
        desc.Position = UDim2.new(0,6,0,52)
        desc.AutomaticSize = Enum.AutomaticSize.Y
        desc.TextWrapped = true

        local statsText = ""
        if scriptData.views then statsText = statsText.."Views: "..scriptData.views.." " end
        if scriptData.likes then statsText = statsText.."Likes: "..scriptData.likes.." " end
        if scriptData.risk then
            local score = scriptData.risk.score or "?"
            local level = scriptData.risk.level or "?"
            statsText = statsText.."Risk: "..tostring(score).." ("..level..") "
        end
        if scriptData.isKeySystem ~= nil then
            statsText = statsText.."Key: "..(scriptData.isKeySystem and "Sim" or "Nao").." "
        elseif scriptData.isKeySystem == nil and scriptData.keySystem ~= nil then
            statsText = statsText.."Key: "..tostring(scriptData.keySystem).." "
        end
        if scriptData.isPaid ~= nil then
            statsText = statsText..(scriptData.isPaid and "Pago" or "Gratuito").." "
        end
        local statsLbl = GUI:createTextLabel(card, statsText, UDim2.new(1,-12,0,0), 10, Config.Window.TextDim)
        statsLbl.Position = UDim2.new(0,6,0,0)
        statsLbl.AutomaticSize = Enum.AutomaticSize.Y
        statsLbl.TextWrapped = true
        -- need to position after desc, we will use layout
        -- use UIListLayout for card? Simpler manual: set layout
        -- Let's add UIListLayout to card for auto
        -- Instead recreate with layout
        -- Quick fix: destroy and use list layout
        -- For simplicity keep but adjust positions dynamically via task
        task.spawn(function()
            task.wait()
            local y = 4
            title.Position = UDim2.new(0,6,0,y) y = y + 20
            slugLbl.Position = UDim2.new(0,6,0,y) y = y + 14
            authorLbl.Position = UDim2.new(0,6,0,y) y = y + 14
            desc.Position = UDim2.new(0,6,0,y)
            task.wait()
            y = y + desc.TextBounds.Y + 4
            statsLbl.Position = UDim2.new(0,6,0,y)
            y = y + statsLbl.TextBounds.Y + 30
            card.Size = UDim2.new(1,-6,0,y)
        end)

        local btnRow = Instance.new("Frame")
        btnRow.Size = UDim2.new(1,-12,0,26)
        btnRow.Position = UDim2.new(0,6,1,-28)
        btnRow.BackgroundTransparency = 1
        btnRow.Parent = card

        local btnCopy = GUI:createButton(btnRow, "Copiar", UDim2.new(0,60,0,22), Config.Window.Background2)
        btnCopy.Position = UDim2.new(0,0,0,0)
        btnCopy.TextSize = 11

        local btnSendIA = GUI:createButton(btnRow, "Enviar à IA", UDim2.new(0,90,0,22), State.visual.accent)
        btnSendIA.Position = UDim2.new(0,66,0,0)
        btnSendIA.TextSize = 11

        -- copy logic
        btnCopy.MouseButton1Click:Connect(function()
            btnCopy.Text = "..."
            task.spawn(function()
                local ok, data = RScripts:getDetail(scriptData.slug)
                if not ok then
                    btnCopy.Text = "Erro"
                    task.wait(1.5)
                    btnCopy.Text = "Copiar"
                    return
                end
                local okCode, code = RScripts:getCodeFromDetailData(data.data)
                if not okCode then
                    btnCopy.Text = "Sem código"
                    task.wait(1.5)
                    btnCopy.Text = "Copiar"
                    return
                end
                local okClip, err = GUI:safeSetClipboard(code)
                if okClip then
                    btnCopy.Text = "Copiado!"
                else
                    btnCopy.Text = "Sem clipboard"
                    -- show message in chat?
                    chatApi.addMessage("system", err, true)
                end
                task.wait(1.5)
                btnCopy.Text = "Copiar"
            end)
        end)

        btnSendIA.MouseButton1Click:Connect(function()
            btnSendIA.Text = "..."
            task.spawn(function()
                local ok, data = RScripts:getDetail(scriptData.slug)
                if not ok then
                    btnSendIA.Text = "Erro"
                    task.wait(1)
                    btnSendIA.Text = "Enviar à IA"
                    chatApi.addMessage("system", "Falha ao obter script: "..tostring(data), true)
                    return
                end
                local okCode, code = RScripts:getCodeFromDetailData(data.data)
                if not okCode then
                    btnSendIA.Text = "Sem código"
                    task.wait(1)
                    btnSendIA.Text = "Enviar à IA"
                    return
                end
                -- check IA configured
                local profile = AI:getActiveProfile()
                local valid, errMsg = AI:validateProfile(profile)
                if not valid then
                    chatApi.addMessage("system", errMsg, true)
                    mainGui.setActiveTab("Chat")
                    btnSendIA.Text = "Enviar à IA"
                    return
                end
                chatApi:prepareAnalysisPrompt(code, scriptData.title)
                btnSendIA.Text = "Enviado"
                task.wait(1)
                btnSendIA.Text = "Enviar à IA"
            end)
        end)

        -- add extra bottom padding frame for auto size calc
        local bottomPad = Instance.new("Frame")
        bottomPad.Size = UDim2.new(1,0,0,28)
        bottomPad.BackgroundTransparency = 1
        bottomPad.Parent = card
    end

    local function showStatus(txt)
        -- create temporary label inside results
        clearResults()
        local lbl = GUI:createTextLabel(resultsFrame, txt, UDim2.new(1,0,0,24), 12, Config.Window.TextDim)
    end

    local function handleSearchResults(success, data)
        btnSearch.Text = "Pesquisar"
        btnSearch.AutoButtonColor = true
        if not success then
            showStatus("Erro: "..tostring(data))
            return
        end
        local scripts = {}
        if data.data then
            if data.data.scripts and type(data.data.scripts)=="table" then
                scripts = data.data.scripts
            elseif type(data.data)=="table" and data.data[1] then
                scripts = data.data
            end
        end
        if #scripts==0 then
            showStatus("Nenhum resultado encontrado.")
            return
        end
        clearResults()
        for _, s in ipairs(scripts) do
            createCard(s)
        end
    end

    btnSearch.MouseButton1Click:Connect(function()
        local q = searchBox.Text
        if not q or q:gsub("%s","")=="" then
            showStatus("Digite algo para pesquisar.")
            return
        end
        btnSearch.Text = "..."
        btnSearch.AutoButtonColor = false
        task.spawn(function()
            local ok, res = RScripts:search(q, 12)
            handleSearchResults(ok, res)
        end)
    end)

    searchBox.FocusLost:Connect(function(enter)
        if enter then
            btnSearch:Activate()
        end
    end)

    btnCurrent.MouseButton1Click:Connect(function()
        local pid = game.PlaceId
        if not pid or pid==0 then
            showStatus("Não foi possível identificar o jogo atual.")
            return
        end
        placeLabel.Text = "PlaceId: "..tostring(pid)
        btnCurrent.Text = "..."
        task.spawn(function()
            local ok, res = RScripts:listByPlaceId(pid, {limit=20, sort="most-likes"})
            btnCurrent.Text = "Jogo atual"
            handleSearchResults(ok, res)
        end)
    end)

    btnEasy.MouseButton1Click:Connect(function()
        local pid = game.PlaceId
        if not pid or pid==0 then
            showStatus("Não foi possível identificar o jogo atual.")
            return
        end
        placeLabel.Text = "PlaceId: "..tostring(pid)
        btnEasy.Text = "..."
        task.spawn(function()
            local ok, res = RScripts:listByPlaceId(pid, {limit=20, sort="most-likes", noKeySystem=true, freeOnly=true})
            btnEasy.Text = "Mais fáceis"
            handleSearchResults(ok, res)
        end)
    end)

    -- initial placeId display
    pcall(function()
        placeLabel.Text = "PlaceId: "..tostring(game.PlaceId)
    end)

    return {
        clearResults = clearResults,
        createCard = createCard,
    }
end

--==================================================
-- 12. Settings Tab (Profiles, Models, System Prompt, RScripts Key, Visual)
--==================================================
local SettingsTab = {}
function SettingsTab:setup(mainGui, chatApi)
    local page = mainGui.Pages.Settings

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,0)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 4
    scroll.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,8)
    layout.Parent = scroll

    local padding = Instance.new("UIPadding")
    padding.PaddingAll = UDim.new(0,6)
    padding.Parent = scroll

    -- Security warning
    local warnFrame = Instance.new("Frame")
    warnFrame.Size = UDim2.new(1,-6,0,40)
    warnFrame.BackgroundColor3 = Color3.fromRGB(50,30,0)
    warnFrame.LayoutOrder = 1
    warnFrame.Parent = scroll
    GUI:createCorner(warnFrame,6)
    GUI:createStroke(warnFrame, State.visual.accent,1,0.5)
    local warnLabel = GUI:createTextLabel(warnFrame, "API Keys colocadas em um script local podem ser extraídas pelo ambiente de execução. Não compartilhe suas chaves.", UDim2.new(1,-10,1,-10), 11, Color3.fromRGB(255,200,100))
    warnLabel.Position = UDim2.new(0,5,0,5)

    -- Persistence status
    local persistLabel = GUI:createTextLabel(scroll, "", UDim2.new(1,0,0,20), 11, Config.Window.TextDim)
    persistLabel.LayoutOrder = 2
    persistLabel.Name = "PersistLabel"

    local function updatePersistLabel()
        if State.persistenceAvailable then
            persistLabel.Text = "Persistência: disponível ("..Storage.File..")"
        else
            persistLabel.Text = "Persistência: não disponível neste ambiente. Configurações ficarão apenas nesta sessão."
        end
    end
    updatePersistLabel()

    -- RScripts API Key section
    local rsec = Instance.new("Frame")
    rsec.Size = UDim2.new(1,-6,0,70)
    rsec.BackgroundColor3 = Config.Window.Background2
    rsec.LayoutOrder = 3
    rsec.Parent = scroll
    GUI:createCorner(rsec,6)
    local rsecLayout = Instance.new("UIListLayout")
    rsecLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rsecLayout.Padding = UDim.new(0,4)
    rsecLayout.Parent = rsec
    local rsecPad = Instance.new("UIPadding")
    rsecPad.PaddingAll = UDim.new(0,6)
    rsecPad.Parent = rsec
    local rTitle = GUI:createTextLabel(rsec, "RScripts API Key", UDim2.new(1,0,0,18), 12, Config.Window.Text, Enum.TextXAlignment.Left)
    rTitle.Font = Enum.Font.GothamBold
    local rBox = GUI:createTextBox(rsec, "rsc_live_...", UDim2.new(1,0,0,28), false)
    rBox.Text = State.rscriptsApiKey or ""
    -- mask logic
    local isMasked = true
    local function maskKey(k)
        if not k or k=="" then return "" end
        if #k<=8 then return "****" end
        return string.sub(k,1,8).."****"..string.sub(k,#k-3)
    end
    local function applyMask()
        if isMasked and rBox.Text~="" and not rBox:IsFocused() then
            -- show masked version in placeholder? We keep actual in State, but display masked
            -- To avoid losing key, we store actual in State and show masked
            rBox.Text = maskKey(State.rscriptsApiKey)
        end
    end
    rBox.Focused:Connect(function()
        isMasked=false
        rBox.Text = State.rscriptsApiKey or ""
    end)
    rBox.FocusLost:Connect(function()
        State.rscriptsApiKey = rBox.Text
        isMasked=true
        Storage:save()
        applyMask()
    end)
    task.spawn(function() task.wait(0.5) applyMask() end)

    -- System Prompt section
    local sysSec = Instance.new("Frame")
    sysSec.Size = UDim2.new(1,-6,0,110)
    sysSec.BackgroundColor3 = Config.Window.Background2
    sysSec.LayoutOrder = 4
    sysSec.Parent = scroll
    GUI:createCorner(sysSec,6)
    local sysLayout = Instance.new("UIListLayout")
    sysLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sysLayout.Padding = UDim.new(0,4)
    sysLayout.Parent = sysSec
    local sysPad = Instance.new("UIPadding")
    sysPad.PaddingAll = UDim.new(0,6)
    sysPad.Parent = sysSec
    local sysTitle = GUI:createTextLabel(sysSec, "System Prompt", UDim2.new(1,0,0,18), 12, Config.Window.Text, Enum.TextXAlignment.Left)
    sysTitle.Font = Enum.Font.GothamBold
    local sysBox = GUI:createTextBox(sysSec, "Instruções para a IA...", UDim2.new(1,0,0,70), true)
    sysBox.Text = State.systemPrompt or ""
    sysBox.TextYAlignment = Enum.TextYAlignment.Top
    sysBox.FocusLost:Connect(function()
        State.systemPrompt = sysBox.Text
        Storage:save()
    end)

    -- Visual settings section
    local visSec = Instance.new("Frame")
    visSec.Size = UDim2.new(1,-6,0,180)
    visSec.BackgroundColor3 = Config.Window.Background2
    visSec.LayoutOrder = 5
    visSec.AutomaticSize = Enum.AutomaticSize.Y
    visSec.Parent = scroll
    GUI:createCorner(visSec,6)
    local visLayout = Instance.new("UIListLayout")
    visLayout.SortOrder = Enum.SortOrder.LayoutOrder
    visLayout.Padding = UDim.new(0,4)
    visLayout.Parent = visSec
    local visPad = Instance.new("UIPadding")
    visPad.PaddingAll = UDim.new(0,6)
    visPad.Parent = visSec
    local visTitle = GUI:createTextLabel(visSec, "Configurações Visuais", UDim2.new(1,0,0,18), 12, Config.Window.Text, Enum.TextXAlignment.Left)
    visTitle.Font = Enum.Font.GothamBold

    local function createVisRow(labelText, placeholder, defaultVal)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,0,0,28)
        row.BackgroundTransparency = 1
        row.Parent = visSec
        local lbl = GUI:createTextLabel(row, labelText, UDim2.new(0,110,1,0), 11, Config.Window.TextDim)
        local tb = GUI:createTextBox(row, placeholder, UDim2.new(1,-116,1,0), false)
        tb.Position = UDim2.new(0,116,0,0)
        tb.Text = tostring(defaultVal or "")
        return row, tb
    end

    local _, transBox = createVisRow("Transparência (0-1):", "0.15", State.visual.transparency)
    local _, scaleBox = createVisRow("Escala (0.8-1.5):", "1", State.visual.scale)
    local _, fontBox = createVisRow("Fonte (12-20):", "14", State.visual.fontSize)
    local _, roundBox = createVisRow("Arredondamento:", "6", State.visual.rounding)
    local _, colorBox = createVisRow("Cor destaque (hex):", "FF8400", string.format("%02X%02X%02X", State.visual.accent.R*255, State.visual.accent.G*255, State.visual.accent.B*255))

    local animBtn = GUI:createButton(visSec, "Animações: "..(State.visual.animations and "ON" or "OFF"), UDim2.new(1,0,0,26), Config.Window.Background3)
    animBtn.TextSize = 12

    local function applyVisual()
        local mainFrame = mainGui.MainFrame
        local stroke = mainGui.MainStroke
        if stroke then stroke.Color = State.visual.accent end
        for _,btn in pairs(mainGui.TabButtons) do
            if btn.BackgroundColor3 == State.visual.accent or btn.TextColor3==Color3.new(1,1,1) then
                -- keep active
            end
        end
        -- update all orange buttons
        local function updateOrange(parent)
            for _,c in ipairs(parent:GetDescendants()) do
                if c:IsA("TextButton") and c.BackgroundColor3 and (c.Name=="Send" or c.Text=="Enviar" or c.Text=="Enviar à IA" or c.Text=="Pesquisar" or c.Text=="Abrir configurações") then
                    c.BackgroundColor3 = State.visual.accent
                end
            end
        end
        pcall(updateOrange, mainGui.ScreenGui)
        if mainFrame then
            mainFrame.BackgroundTransparency = State.visual.transparency
        end
        if mainGui.UIScale then
            mainGui.UIScale.Scale = State.visual.scale
        end
        -- rounding update
        for _,c in ipairs(mainGui.ScreenGui:GetDescendants()) do
            if c:IsA("UICorner") then
                c.CornerRadius = UDim.new(0, State.visual.rounding)
            end
        end
    end

    transBox.FocusLost:Connect(function()
        local v = tonumber(transBox.Text)
        if v and v>=0 and v<=1 then
            State.visual.transparency = v
            applyVisual()
            Storage:save()
        end
    end)
    scaleBox.FocusLost:Connect(function()
        local v = tonumber(scaleBox.Text)
        if v and v>=0.5 and v<=2 then
            State.visual.scale = v
            applyVisual()
            Storage:save()
        end
    end)
    fontBox.FocusLost:Connect(function()
        local v = tonumber(fontBox.Text)
        if v and v>=10 and v<=24 then
            State.visual.fontSize = v
            Storage:save()
        end
    end)
    roundBox.FocusLost:Connect(function()
        local v = tonumber(roundBox.Text)
        if v and v>=0 and v<=20 then
            State.visual.rounding = v
            applyVisual()
            Storage:save()
        end
    end)
    colorBox.FocusLost:Connect(function()
        local hex = colorBox.Text:gsub("#","")
        if #hex==6 then
            local r = tonumber(hex:sub(1,2),16)
            local g = tonumber(hex:sub(3,4),16)
            local b = tonumber(hex:sub(5,6),16)
            if r and g and b then
                State.visual.accent = Color3.fromRGB(r,g,b)
                applyVisual()
                Storage:save()
            end
        end
    end)
    animBtn.MouseButton1Click:Connect(function()
        State.visual.animations = not State.visual.animations
        animBtn.Text = "Animações: "..(State.visual.animations and "ON" or "OFF")
        Storage:save()
    end)

    -- Profiles section (most complex)
    local profSec = Instance.new("Frame")
    profSec.Size = UDim2.new(1,-6,0,0)
    profSec.AutomaticSize = Enum.AutomaticSize.Y
    profSec.BackgroundColor3 = Config.Window.Background2
    profSec.LayoutOrder = 6
    profSec.Parent = scroll
    GUI:createCorner(profSec,6)
    local profLayout = Instance.new("UIListLayout")
    profLayout.SortOrder = Enum.SortOrder.LayoutOrder
    profLayout.Padding = UDim.new(0,6)
    profLayout.Parent = profSec
    local profPad = Instance.new("UIPadding")
    profPad.PaddingAll = UDim.new(0,6)
    profPad.Parent = profSec
    local profTitle = GUI:createTextLabel(profSec, "Perfis de IA", UDim2.new(1,0,0,18), 12, Config.Window.Text, Enum.TextXAlignment.Left)
    profTitle.Font = Enum.Font.GothamBold
    profTitle.LayoutOrder = 1

    local profilesListFrame = Instance.new("Frame")
    profilesListFrame.Size = UDim2.new(1,0,0,0)
    profilesListFrame.AutomaticSize = Enum.AutomaticSize.Y
    profilesListFrame.BackgroundTransparency = 1
    profilesListFrame.LayoutOrder = 2
    profilesListFrame.Parent = profSec
    local profListLayout = Instance.new("UIListLayout")
    profListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    profListLayout.Padding = UDim.new(0,4)
    profListLayout.Parent = profilesListFrame

    local btnCreateProfile = GUI:createButton(profSec, "+ Criar Perfil", UDim2.new(1,0,0,28), State.visual.accent)
    btnCreateProfile.LayoutOrder = 3
    btnCreateProfile.TextSize = 12

    -- Profile form (hidden initially)
    local formFrame = Instance.new("Frame")
    formFrame.Size = UDim2.new(1,0,0,0)
    formFrame.AutomaticSize = Enum.AutomaticSize.Y
    formFrame.BackgroundColor3 = Config.Window.Background3
    formFrame.Visible = false
    formFrame.LayoutOrder = 4
    formFrame.Parent = profSec
    GUI:createCorner(formFrame,6)
    GUI:createStroke(formFrame, State.visual.accent,1)
    local formLayout = Instance.new("UIListLayout")
    formLayout.SortOrder = Enum.SortOrder.LayoutOrder
    formLayout.Padding = UDim.new(0,4)
    formLayout.Parent = formFrame
    local formPad = Instance.new("UIPadding")
    formPad.PaddingAll = UDim.new(0,6)
    formPad.Parent = formFrame

    local formTitle = GUI:createTextLabel(formFrame, "Novo Perfil", UDim2.new(1,0,0,18), 12, Config.Window.Text, Enum.TextXAlignment.Left)
    formTitle.Font = Enum.Font.GothamBold

    local nameBox = GUI:createTextBox(formFrame, "Nome do perfil", UDim2.new(1,0,0,28), false)
    local apiUrlBox = GUI:createTextBox(formFrame, "API URL", UDim2.new(1,0,0,28), false)
    local apiKeyBox = GUI:createTextBox(formFrame, "API Key", UDim2.new(1,0,0,28), false)

    -- Provider dropdown
    local provRow = Instance.new("Frame")
    provRow.Size = UDim2.new(1,0,0,28)
    provRow.BackgroundTransparency = 1
    provRow.Parent = formFrame
    local provLabel = GUI:createTextLabel(provRow, "Provedor:", UDim2.new(0,70,1,0), 11, Config.Window.TextDim)
    local provBtn = GUI:createButton(provRow, "Selecione provedor", UDim2.new(1,-76,1,0), Config.Window.Background2)
    provBtn.Position = UDim2.new(0,76,0,0)
    provBtn.TextSize = 12
    provBtn.Name = "ProviderBtn"

    local provList = Instance.new("ScrollingFrame")
    provList.Size = UDim2.new(0,180,0,150)
    provList.Position = UDim2.new(0,76,0,28)
    provList.BackgroundColor3 = Config.Window.Background2
    provList.Visible = false
    provList.ZIndex = 30
    provList.CanvasSize = UDim2.new(0,0,0,0)
    provList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    provList.ScrollBarThickness = 4
    provList.Parent = provRow
    GUI:createCorner(provList,6)
    GUI:createStroke(provList, State.visual.accent,1)
    local provListLayout = Instance.new("UIListLayout")
    provListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    provListLayout.Parent = provList

    local selectedProvider = nil

    -- Model search
    local modelSearchBox = GUI:createTextBox(formFrame, "Pesquisar modelo...", UDim2.new(1,0,0,28), false)
    modelSearchBox.Name = "ModelSearch"

    -- Model dropdown button
    local modelRow = Instance.new("Frame")
    modelRow.Size = UDim2.new(1,0,0,28)
    modelRow.BackgroundTransparency = 1
    modelRow.Parent = formFrame
    local modelLbl = GUI:createTextLabel(modelRow, "Modelo:", UDim2.new(0,60,1,0), 11, Config.Window.TextDim)
    local modelBtn = GUI:createButton(modelRow, "Selecione um modelo", UDim2.new(1,-66,1,0), Config.Window.Background2)
    modelBtn.Position = UDim2.new(0,66,0,0)
    modelBtn.TextSize = 12

    local modelListFrame = Instance.new("ScrollingFrame")
    modelListFrame.Size = UDim2.new(1,0,0,200)
    modelListFrame.BackgroundColor3 = Config.Window.Background2
    modelListFrame.Visible = false
    modelListFrame.ZIndex = 25
    modelListFrame.CanvasSize = UDim2.new(0,0,0,0)
    modelListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    modelListFrame.ScrollBarThickness = 4
    modelListFrame.Parent = formFrame
    GUI:createCorner(modelListFrame,6)
    GUI:createStroke(modelListFrame, State.visual.accent,1)
    local modelListLayout = Instance.new("UIListLayout")
    modelListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    modelListLayout.Padding = UDim.new(0,2)
    modelListLayout.Parent = modelListFrame

    local selectedModelId = nil
    local selectedModelPrice = "Unknown"

    -- Buttons for model catalog actions
    local modelActionsRow = Instance.new("Frame")
    modelActionsRow.Size = UDim2.new(1,0,0,28)
    modelActionsRow.BackgroundTransparency = 1
    modelActionsRow.Parent = formFrame
    local maLayout = Instance.new("UIListLayout")
    maLayout.FillDirection = Enum.FillDirection.Horizontal
    maLayout.Padding = UDim.new(0,6)
    maLayout.Parent = modelActionsRow

    local btnUpdateModels = GUI:createButton(modelActionsRow, "Atualizar modelos", UDim2.new(0,120,0,24), Config.Window.Background2)
    btnUpdateModels.TextSize = 11
    local btnCustomModel = GUI:createButton(modelActionsRow, "+ Modelo personalizado", UDim2.new(0,150,0,24), Config.Window.Background2)
    btnCustomModel.TextSize = 11

    -- Custom model form
    local customFrame = Instance.new("Frame")
    customFrame.Size = UDim2.new(1,0,0,0)
    customFrame.AutomaticSize = Enum.AutomaticSize.Y
    customFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)
    customFrame.Visible = false
    customFrame.Parent = formFrame
    GUI:createCorner(customFrame,6)
    local custLayout = Instance.new("UIListLayout")
    custLayout.SortOrder = Enum.SortOrder.LayoutOrder
    custLayout.Padding = UDim.new(0,4)
    custLayout.Parent = customFrame
    local custPad = Instance.new("UIPadding")
    custPad.PaddingAll = UDim.new(0,6)
    custPad.Parent = customFrame
    local custTitle = GUI:createTextLabel(customFrame, "Modelo personalizado", UDim2.new(1,0,0,18), 11, Config.Window.Text)
    custTitle.Font = Enum.Font.GothamBold
    local custNameBox = GUI:createTextBox(customFrame, "Nome", UDim2.new(1,0,0,24), false)
    local custIdBox = GUI:createTextBox(customFrame, "Model ID", UDim2.new(1,0,0,24), false)
    local custProvBox = GUI:createTextBox(customFrame, "Provedor", UDim2.new(1,0,0,24), false)
    local custPriceBtn = GUI:createButton(customFrame, "Preço: Desconhecido", UDim2.new(1,0,0,24), Config.Window.Background2)
    custPriceBtn.TextSize = 11
    local custApiUrlBox = GUI:createTextBox(customFrame, "API URL (opcional)", UDim2.new(1,0,0,24), false)
    local custSaveBtn = GUI:createButton(customFrame, "Salvar modelo personalizado", UDim2.new(1,0,0,26), State.visual.accent)
    custSaveBtn.TextSize = 11
    local custPriceOptions = {"Gratuito","Pago","Desconhecido"}
    local custPriceIdx = 3
    custPriceBtn.MouseButton1Click:Connect(function()
        custPriceIdx = custPriceIdx % #custPriceOptions + 1
        custPriceBtn.Text = "Preço: "..custPriceOptions[custPriceIdx]
    end)

    -- Form save/cancel
    local formBtnRow = Instance.new("Frame")
    formBtnRow.Size = UDim2.new(1,0,0,28)
    formBtnRow.BackgroundTransparency = 1
    formBtnRow.Parent = formFrame
    local formBtnLayout = Instance.new("UIListLayout")
    formBtnLayout.FillDirection = Enum.FillDirection.Horizontal
    formBtnLayout.Padding = UDim.new(0,6)
    formBtnLayout.Parent = formBtnRow
    local btnSaveProfile = GUI:createButton(formBtnRow, "Salvar", UDim2.new(0,80,0,26), State.visual.accent)
    local btnCancelProfile = GUI:createButton(formBtnRow, "Cancelar", UDim2.new(0,80,0,26), Config.Window.Background2)

    local editingProfileId = nil

    -- Functions for model catalog
    local function getAllModels()
        local all = {}
        -- from Config
        for prov, list in pairs(Config.ModelsCatalog) do
            for _, m in ipairs(list) do
                table.insert(all, {id=m.id, name=m.name or m.id, provider=prov, price=m.price or "Unknown", isCustom=false})
            end
        end
        -- custom
        for _, cm in ipairs(State.customModels) do
            table.insert(all, {id=cm.id, name=cm.name, provider=cm.provider or "Outros", price=cm.price or "Unknown", isCustom=true, apiUrl=cm.apiUrl})
        end
        return all
    end

    local function isFavorite(modelId)
        return State.favorites[modelId] == true
    end

    local function toggleFavorite(modelId)
        if State.favorites[modelId] then
            State.favorites[modelId] = nil
        else
            State.favorites[modelId] = true
        end
        Storage:save()
    end

    local function refreshModelList()
        for _,c in ipairs(modelListFrame:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("TextLabel") then
                if c.Name~="UIListLayout" then c:Destroy() end
            end
        end
        local searchText = string.lower(modelSearchBox.Text or "")
        local allModels = getAllModels()

        -- filter by search
        local filtered = {}
        for _, m in ipairs(allModels) do
            if searchText=="" or string.lower(m.id):find(searchText,1,true) or string.lower(m.name):find(searchText,1,true) or string.lower(m.provider):find(searchText,1,true) then
                table.insert(filtered, m)
            end
        end

        -- group
        local groups = {
            {name="[FAVORITOS]", key="fav", models={}},
            {name="[PROVEDOR: "..(selectedProvider or "TODOS").."]", key="prov", models={}},
            {name="[GRATUITOS]", key="free", models={}},
            {name="[PAGOS]", key="paid", models={}},
            {name="[OUTROS / DESCONHECIDO]", key="other", models={}},
            {name="[PERSONALIZADOS]", key="custom", models={}},
        }

        for _, m in ipairs(filtered) do
            if isFavorite(m.id) then
                table.insert(groups[1].models, m)
            elseif selectedProvider and m.provider==selectedProvider then
                table.insert(groups[2].models, m)
            elseif m.isCustom then
                table.insert(groups[6].models, m)
            elseif m.price=="Free" or m.price=="Gratuito" then
                table.insert(groups[3].models, m)
            elseif m.price=="Paid" or m.price=="Pago" then
                table.insert(groups[4].models, m)
            else
                table.insert(groups[5].models, m)
            end
        end

        -- if no provider selected, merge prov group into others? We'll keep but show only if provider selected
        local maxToShow = 150
        local shown = 0
        for _, g in ipairs(groups) do
            if #g.models>0 and shown<maxToShow then
                if not (g.key=="prov" and not selectedProvider) then
                    local header = GUI:createTextLabel(modelListFrame, g.name.." ("..#g.models..")", UDim2.new(1,0,0,20), 11, State.visual.accent)
                    header.Font = Enum.Font.GothamBold
                    shown = shown + 1
                    -- sort inside group by name
                    table.sort(g.models, function(a,b) return a.name:lower() < b.name:lower() end)
                    for _, m in ipairs(g.models) do
                        if shown>=maxToShow then break end
                        local row = Instance.new("Frame")
                        row.Size = UDim2.new(1,0,0,26)
                        row.BackgroundColor3 = Config.Window.Background3
                        row.Parent = modelListFrame
                        GUI:createCorner(row,4)

                        local nameLbl = GUI:createTextLabel(row, m.name.." ("..m.id..") ["..m.price.."]", UDim2.new(1,-50,1,0), 11, Config.Window.Text)
                        nameLbl.Position = UDim2.new(0,6,0,0)

                        local favBtn = Instance.new("TextButton")
                        favBtn.Size = UDim2.new(0,22,0,22)
                        favBtn.Position = UDim2.new(1,-46,0,2)
                        favBtn.BackgroundColor3 = Config.Window.Background2
                        favBtn.Text = isFavorite(m.id) and "*" or "+"
                        favBtn.TextColor3 = isFavorite(m.id) and State.visual.accent or Config.Window.TextDim
                        favBtn.TextSize = 12
                        favBtn.Font = Enum.Font.GothamBold
                        favBtn.Parent = row
                        GUI:createCorner(favBtn,4)
                        favBtn.MouseButton1Click:Connect(function()
                            toggleFavorite(m.id)
                            refreshModelList()
                        end)

                        local selBtn = Instance.new("TextButton")
                        selBtn.Size = UDim2.new(0,22,0,22)
                        selBtn.Position = UDim2.new(1,-22,0,2)
                        selBtn.BackgroundColor3 = State.visual.accent
                        selBtn.Text = ">"
                        selBtn.TextColor3 = Color3.new(1,1,1)
                        selBtn.TextSize = 12
                        selBtn.Parent = row
                        GUI:createCorner(selBtn,4)
                        selBtn.MouseButton1Click:Connect(function()
                            selectedModelId = m.id
                            selectedModelPrice = m.price
                            modelBtn.Text = m.id
                            modelListFrame.Visible = false
                            if m.apiUrl and m.apiUrl~="" and (apiUrlBox.Text=="" or apiUrlBox.Text==Config.ProviderAPIUrls[selectedProvider or ""]) then
                                -- optionally fill? Keep existing
                            end
                        end)

                        shown = shown + 1
                    end
                end
            end
        end
        if shown==0 then
            GUI:createTextLabel(modelListFrame, "Nenhum modelo encontrado. Use pesquisa ou adicione personalizado.", UDim2.new(1,0,0,24), 11, Config.Window.TextDim)
        end
    end

    provBtn.MouseButton1Click:Connect(function()
        provList.Visible = not provList.Visible
    end)

    -- populate provider list
    for _, prov in ipairs(Config.Providers) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-4,0,24)
        btn.BackgroundColor3 = Config.Window.Background3
        btn.Text = prov
        btn.TextColor3 = Config.Window.Text
        btn.TextSize = 12
        btn.Parent = provList
        GUI:createCorner(btn,4)
        btn.MouseButton1Click:Connect(function()
            selectedProvider = prov
            provBtn.Text = prov
            provList.Visible = false
            -- auto fill API URL if empty
            if apiUrlBox.Text=="" then
                local suggested = Config.ProviderAPIUrls[prov]
                if suggested and suggested~="" then
                    apiUrlBox.Text = suggested
                end
            end
            refreshModelList()
        end)
    end

    modelBtn.MouseButton1Click:Connect(function()
        refreshModelList()
        modelListFrame.Visible = not modelListFrame.Visible
    end)

    modelSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if modelListFrame.Visible then
            refreshModelList()
        end
    end)

    btnCustomModel.MouseButton1Click:Connect(function()
        customFrame.Visible = not customFrame.Visible
    end)

    custSaveBtn.MouseButton1Click:Connect(function()
        local nid = custIdBox.Text
        local nname = custNameBox.Text
        if nid=="" or nname=="" then return end
        local priceMap = {["Gratuito"]="Free", ["Pago"]="Paid", ["Desconhecido"]="Unknown"}
        local price = priceMap[custPriceOptions[custPriceIdx]] or "Unknown"
        local newModel = {
            id = nid,
            name = nname,
            provider = custProvBox.Text ~= "" and custProvBox.Text or "Outros",
            price = price,
            apiUrl = custApiUrlBox.Text,
        }
        table.insert(State.customModels, newModel)
        Storage:save()
        customFrame.Visible = false
        custNameBox.Text=""
        custIdBox.Text=""
        custProvBox.Text=""
        custApiUrlBox.Text=""
        refreshModelList()
    end)

    btnUpdateModels.MouseButton1Click:Connect(function()
        btnUpdateModels.Text = "..."
        task.spawn(function()
            -- Try to update from provider API if possible
            if not selectedProvider then
                btnUpdateModels.Text = "Selecione provedor"
                task.wait(1.5)
                btnUpdateModels.Text = "Atualizar modelos"
                return
            end
            -- For OpenRouter: GET https://openrouter.ai/api/v1/models
            if selectedProvider=="OpenRouter" then
                if not State.rscriptsApiKey and not AI:getActiveProfile() then
                    -- use any profile's key? We'll try without auth first
                end
                -- need API key from active profile if provider OpenRouter
                local profile = AI:getActiveProfile()
                local keyToUse = nil
                if profile and profile.Provider=="OpenRouter" then keyToUse = profile.API_KEY end
                -- try request
                local headers = {}
                if keyToUse then headers["Authorization"] = "Bearer "..keyToUse end
                local opts = {Url="https://openrouter.ai/api/v1/models", Method="GET", Headers=headers}
                local res = HTTP:request(opts)
                if res.Success then
                    local ok, dec = pcall(function() return HttpService:JSONDecode(res.Body) end)
                    if ok and dec and dec.data then
                        -- dec.data is list of models
                        local count=0
                        for _, m in ipairs(dec.data) do
                            local id = m.id
                            local name = m.name or id
                            -- try to detect provider from id prefix
                            local prov = "Outros"
                            if id:find("openai") then prov="OpenAI"
                            elseif id:find("google") or id:find("gemini") then prov="Google Gemini"
                            elseif id:find("deepseek") then prov="DeepSeek"
                            elseif id:find("anthropic") or id:find("claude") then prov="Anthropic"
                            elseif id:find("qwen") then prov="Qwen"
                            elseif id:find("mistral") then prov="Mistral"
                            elseif id:find("llama") or id:find("meta") then prov="Meta / Llama"
                            elseif id:find("grok") or id:find("xai") then prov="xAI / Grok"
                            end
                            -- check if already exists
                            local exists=false
                            for _, existing in ipairs(State.customModels) do if existing.id==id then exists=true break end end
                            if not exists then
                                -- add to custom or to catalog? We'll add to customModels for OpenRouter
                                local price = "Unknown"
                                if m.pricing then
                                    -- if pricing prompt is 0, free?
                                    if m.pricing.prompt=="0" then price="Free" else price="Paid" end
                                end
                                table.insert(State.customModels, {id=id, name=name, provider=prov, price=price, apiUrl=""})
                                count=count+1
                            end
                        end
                        Storage:save()
                        btnUpdateModels.Text = "Atualizados "..count
                        refreshModelList()
                        task.wait(2)
                        btnUpdateModels.Text = "Atualizar modelos"
                        return
                    end
                end
                btnUpdateModels.Text = "Falha"
                task.wait(1.5)
                btnUpdateModels.Text = "Atualizar modelos"
                return
            end
            -- For OpenAI-compatible: try /models endpoint derived from API URL
            local baseUrl = apiUrlBox.Text
            if baseUrl=="" then
                baseUrl = Config.ProviderAPIUrls[selectedProvider] or ""
            end
            local modelsUrl = nil
            if baseUrl:find("/chat/completions") then
                modelsUrl = baseUrl:gsub("/chat/completions","/models")
            elseif baseUrl:find("/v1") then
                modelsUrl = baseUrl:match("^(https?://[^/]+/v%d+)/") and baseUrl:match("^(https?://[^/]+/v%d+)/").."/models" or nil
                if not modelsUrl then
                    -- fallback: take origin + /v1/models
                    local origin = baseUrl:match("^(https?://[^/]+)")
                    if origin then modelsUrl = origin.."/v1/models" end
                end
            end
            if not modelsUrl then
                btnUpdateModels.Text = "Sem endpoint"
                task.wait(1.5)
                btnUpdateModels.Text = "Atualizar modelos"
                return
            end
            local profile = AI:getActiveProfile()
            local key = apiKeyBox.Text ~= "" and apiKeyBox.Text or (profile and profile.API_KEY) or ""
            local headers = {}
            if key~="" then headers["Authorization"]="Bearer "..key end
            local opts = {Url=modelsUrl, Method="GET", Headers=headers}
            local res = HTTP:request(opts)
            if res.Success then
                local ok, dec = pcall(function() return HttpService:JSONDecode(res.Body) end)
                if ok and dec then
                    local list = dec.data or dec.models or {}
                    local count=0
                    for _, m in ipairs(list) do
                        local id = m.id or m.name
                        if id then
                            local exists=false
                            -- check in catalog
                            for _, catList in pairs(Config.ModelsCatalog) do
                                for _, cm in ipairs(catList) do if cm.id==id then exists=true break end end
                                if exists then break end
                            end
                            if not exists then
                                for _, cm in ipairs(State.customModels) do if cm.id==id then exists=true break end end
                            end
                            if not exists then
                                table.insert(State.customModels, {id=id, name=m.name or id, provider=selectedProvider, price="Unknown", apiUrl=""})
                                count=count+1
                            end
                        end
                    end
                    Storage:save()
                    btnUpdateModels.Text = "Atualizados "..count
                    refreshModelList()
                    task.wait(2)
                    btnUpdateModels.Text = "Atualizar modelos"
                    return
                end
            end
            btnUpdateModels.Text = "Falha"
            task.wait(1.5)
            btnUpdateModels.Text = "Atualizar modelos"
        end)
    end)

    local function refreshProfilesList()
        for _,c in ipairs(profilesListFrame:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for _, p in ipairs(State.profiles) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1,0,0,36)
            row.BackgroundColor3 = Config.Window.Background3
            row.Parent = profilesListFrame
            GUI:createCorner(row,6)

            local nameLbl = GUI:createTextLabel(row, p.Name.." | "..(p.Provider or "?").." | "..(p.MODEL or "sem modelo"), UDim2.new(1,-130,1,0), 11, Config.Window.Text)
            nameLbl.Position = UDim2.new(0,6,0,0)

            local btnSelect = GUI:createButton(row, "Usar", UDim2.new(0,40,0,22), State.visual.accent)
            btnSelect.Position = UDim2.new(1,-120,0,7)
            btnSelect.TextSize = 11
            btnSelect.MouseButton1Click:Connect(function()
                State.activeProfileId = p.id
                Storage:save()
                chatApi:updateActiveProfileDisplay()
                -- visual feedback
                btnSelect.Text = "Ativo"
                task.wait(1)
                btnSelect.Text = "Usar"
            end)

            local btnEdit = GUI:createButton(row, "E", UDim2.new(0,22,0,22), Config.Window.Background2)
            btnEdit.Position = UDim2.new(1,-72,0,7)
            btnEdit.TextSize = 11
            btnEdit.MouseButton1Click:Connect(function()
                editingProfileId = p.id
                nameBox.Text = p.Name
                apiUrlBox.Text = p.API_URL
                apiKeyBox.Text = p.API_KEY
                selectedProvider = p.Provider
                provBtn.Text = p.Provider or "Selecione provedor"
                selectedModelId = p.MODEL
                modelBtn.Text = p.MODEL or "Selecione um modelo"
                formFrame.Visible = true
                formTitle.Text = "Editar Perfil"
            end)

            local btnDel = GUI:createButton(row, "X", UDim2.new(0,22,0,22), Color3.fromRGB(120,30,30))
            btnDel.Position = UDim2.new(1,-30,0,7)
            btnDel.TextSize = 11
            btnDel.MouseButton1Click:Connect(function()
                for i, pr in ipairs(State.profiles) do
                    if pr.id==p.id then
                        table.remove(State.profiles, i)
                        break
                    end
                end
                if State.activeProfileId==p.id then State.activeProfileId=nil end
                Storage:save()
                refreshProfilesList()
                chatApi:refreshProfileDropdown()
                chatApi:updateActiveProfileDisplay()
            end)
        end
        if #State.profiles==0 then
            local lbl = GUI:createTextLabel(profilesListFrame, "Nenhum perfil criado. Crie um para começar.", UDim2.new(1,0,0,24), 11, Config.Window.TextDim)
        end
    end

    btnCreateProfile.MouseButton1Click:Connect(function()
        editingProfileId = nil
        nameBox.Text = ""
        apiUrlBox.Text = ""
        apiKeyBox.Text = ""
        selectedProvider = nil
        provBtn.Text = "Selecione provedor"
        selectedModelId = nil
        modelBtn.Text = "Selecione um modelo"
        modelSearchBox.Text = ""
        formTitle.Text = "Novo Perfil"
        formFrame.Visible = not formFrame.Visible
    end)

    btnCancelProfile.MouseButton1Click:Connect(function()
        formFrame.Visible = false
        editingProfileId = nil
    end)

    btnSaveProfile.MouseButton1Click:Connect(function()
        local name = nameBox.Text
        local url = apiUrlBox.Text
        local key = apiKeyBox.Text
        local prov = selectedProvider or "Outros"
        local model = selectedModelId or modelBtn.Text
        if model=="Selecione um modelo" then model="" end
        if name:gsub("%s","")=="" then return end
        if editingProfileId then
            for _, p in ipairs(State.profiles) do
                if p.id==editingProfileId then
                    p.Name = name
                    p.API_URL = url
                    p.API_KEY = key
                    p.Provider = prov
                    p.MODEL = model
                    break
                end
            end
        else
            local newId = HttpService:GenerateGUID(false)
            local newProfile = {
                id = newId,
                Name = name,
                API_URL = url,
                API_KEY = key,
                Provider = prov,
                MODEL = model,
            }
            table.insert(State.profiles, newProfile)
            State.activeProfileId = newId
        end
        Storage:save()
        formFrame.Visible = false
        editingProfileId = nil
        refreshProfilesList()
        chatApi:refreshProfileDropdown()
        chatApi:updateActiveProfileDisplay()
    end)

    refreshProfilesList()

    return {
        refreshProfilesList = refreshProfilesList,
        updatePersistLabel = updatePersistLabel,
    }
end

--==================================================
-- 13. Initialization
--==================================================
local function init()
    -- load storage
    Storage:load()
    -- create gui
    local mainGui = MainGui:create()
    -- setup tabs
    local chatApi = ChatTab:setup(mainGui)
    local rscriptsApi = RScriptsTab:setup(mainGui, chatApi)
    local settingsApi = SettingsTab:setup(mainGui, chatApi)

    -- update visual from state
    if mainGui.MainFrame then
        mainGui.MainFrame.BackgroundTransparency = State.visual.transparency
    end
    if mainGui.MainStroke then
        mainGui.MainStroke.Color = State.visual.accent
    end
    if mainGui.UIScale then
        mainGui.UIScale.Scale = State.visual.scale
    end

    -- HTTP check message
    if not HTTP.available then
        chatApi.addMessage("system", "HTTP não disponível neste ambiente.", true)
    end

    -- initial active tab is Chat
    mainGui.setActiveTab("Chat")

    -- If no profiles, show message
    if #State.profiles==0 then
        chatApi.addMessage("system", "Configure a IA que você vai usar nas configurações.", true)
    end

    print("[AIChat] Inicializado. Perfis:", #State.profiles, "Persistencia:", State.persistenceAvailable, "HTTP:", HTTP.available)
end

-- Run
local ok, err = pcall(init)
if not ok then
    warn("[AIChat] Erro na inicialização: "..tostring(err))
end
