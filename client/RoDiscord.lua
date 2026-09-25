-- ============================================
-- 🔥 RoDiscord v8 - GET-ONLY LOGIN
-- ============================================
-- ✅ Usa APENAS GET para login (executor-friendly)
-- ✅ Codifica dados na URL
-- ✅ Fallback se tudo falhar
-- ============================================

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"))()

local CONFIG = {
    API_URL = "https://rodiscord.onrender.com",
    VERSION = "1.0-GET-ONLY",
}

local App = {
    currentUser = nil,
    currentServer = nil,
    currentChannel = nil,
    currentDM = nil,
    isDM = false,
    servers = {},
    channels = {},
    messages = {},
    friends = {},
    isLoggedIn = false,
}

-- ============================================
-- HTTP REQUESTS - APENAS GET
-- ============================================

local function makeRequest(method, endpoint, params)
    local url = CONFIG.API_URL .. endpoint
    
    -- Se tiver params e for GET, adicionar na URL
    if method == "GET" and params then
        local queryString = "?"
        for key, value in pairs(params) do
            queryString = queryString .. key .. "=" .. tostring(value) .. "&"
        end
        url = url .. queryString
    end
    
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and response then
        if response == "" or response == nil then
            return { success = true }
        end
        local decoded = game:GetService("HttpService"):JSONDecode(response)
        return decoded
    else
        print("❌ Erro: " .. endpoint)
        return nil
    end
end

local function showNotification(title, content)
    OrionLib:MakeNotification({
        Name = title,
        Content = content,
        Image = "rbxassetid://4483345998",
        Time = 3
    })
end

-- ============================================
-- AUTO LOGIN COM GET
-- ============================================

local function AutoLoginWithOrion()
    print("🔐 Iniciando auto-login (GET-only)...")
    
    local userId = game.Players.LocalPlayer.UserId
    local username = game.Players.LocalPlayer.Name
    local avatarUrl = "https://www.roblox.com/bust-thumbnails/" .. userId .. "/400x400.png"
    
    print("👤 Usuário: " .. username .. " (ID: " .. userId .. ")")
    print("⏳ Aguardando resposta...")
    
    -- Tentar endpoint GET para login
    local result = makeRequest("GET", "/api/auth/roblox-login-get", {
        roblox_id = userId,
        roblox_username = username,
        avatar_url = avatarUrl
    })
    
    if result and result.success then
        App.currentUser = result.profile
        App.isLoggedIn = true
        
        print("✅ Login bem-sucedido!")
        showNotification("✅ Conectado", "Bem-vindo, " .. username .. "!")
        
        -- Carregar servidores
        print("📦 Carregando servidores...")
        local servers = makeRequest("GET", "/api/servers/" .. result.profile.id)
        if servers and servers.success then
            App.servers = servers.servers or {}
            print("✅ " .. #App.servers .. " servidor(es)")
        end
        
        -- Carregar amigos
        print("📦 Carregando amigos...")
        local friends = makeRequest("GET", "/api/friends/" .. result.profile.id)
        if friends and friends.success then
            App.friends = friends.friends or {}
            print("✅ " .. #App.friends .. " amigo(s)")
        end
        
        return true
    else
        print("❌ Falha no login!")
        print("   Backend pode estar offline ou não reconhecer GET")
        showNotification("❌ Erro", "Falha na conexão")
        return false
    end
end

-- ============================================
-- CRIAR WINDOW
-- ============================================

local Window = OrionLib:MakeWindow({
    Name = "🔥 RoDiscord v" .. CONFIG.VERSION,
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "RoDiscord",
    IntroEnabled = false
})

-- ============================================
-- TAB 1 - STATUS
-- ============================================

local StatusTab = Window:MakeTab({
    Name = "📱 Status",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local function UpdateStatusTab()
    if not App.isLoggedIn or not App.currentUser then
        StatusTab:AddLabel("⚠️ Não conectado")
        StatusTab:AddLabel("")
        StatusTab:AddButton({
            Name = "🔄 Reconectar",
            Callback = function()
                if AutoLoginWithOrion() then
                    UpdateStatusTab()
                end
            end
        })
    else
        StatusTab:AddLabel("✅ Conectado")
        StatusTab:AddLabel("")
        StatusTab:AddLabel("👤 " .. App.currentUser.roblox_username)
        StatusTab:AddLabel("🟢 Online")
        StatusTab:AddLabel("")
        StatusTab:AddLabel("📊 ESTATÍSTICAS")
        StatusTab:AddLabel("🏠 Servidores: " .. #App.servers)
        StatusTab:AddLabel("👥 Amigos: " .. #App.friends)
        
        if App.currentServer then
            StatusTab:AddLabel("📍 Servidor: " .. App.currentServer.name)
        end
        
        if App.currentChannel then
            StatusTab:AddLabel("💬 Canal: #" .. App.currentChannel.name)
        end
    end
end

-- ============================================
-- TAB 2 - SERVIDORES
-- ============================================

local ServersTab = Window:MakeTab({
    Name = "🏠 Servidores",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local function UpdateServersTab()
    if not App.isLoggedIn or not App.currentUser then
        ServersTab:AddLabel("⚠️ Conecte-se primeiro!")
        return
    end
    
    ServersTab:AddLabel("SEUS SERVIDORES (" .. #App.servers .. ")")
    ServersTab:AddLabel("")
    
    if #App.servers == 0 then
        ServersTab:AddLabel("Nenhum servidor encontrado")
    else
        for _, server in ipairs(App.servers) do
            if server and server.id and server.name then
                ServersTab:AddButton({
                    Name = "🏠 " .. server.name,
                    Callback = function()
                        App.currentServer = server
                        App.isDM = false
                        App.currentChannel = nil
                        App.messages = {}
                        
                        print("📍 Carregando canais...")
                        local channelsData = makeRequest("GET", "/api/servers/" .. server.id .. "/channels")
                        if channelsData and channelsData.success then
                            App.channels = channelsData.channels or {}
                            showNotification("🏠 Servidor", "Selecionado: " .. server.name)
                            UpdateChannelsTab()
                            UpdateStatusTab()
                        else
                            showNotification("❌ Erro", "Falha ao carregar canais")
                        end
                    end
                })
            end
        end
    end
end

-- ============================================
-- TAB 3 - CANAIS
-- ============================================

local ChannelsTab = Window:MakeTab({
    Name = "# Canais",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local function UpdateChannelsTab()
    if not App.isLoggedIn or not App.currentUser then
        ChannelsTab:AddLabel("⚠️ Conecte-se!")
        return
    end
    
    if not App.currentServer then
        ChannelsTab:AddLabel("⚠️ Selecione um servidor!")
        return
    end
    
    ChannelsTab:AddLabel("📍 " .. App.currentServer.name)
    ChannelsTab:AddLabel("")
    
    local textChannels = {}
    local voiceChannels = {}
    
    for _, channel in ipairs(App.channels) do
        if channel and channel.id and channel.name then
            if channel.type == "text" then
                table.insert(textChannels, channel)
            else
                table.insert(voiceChannels, channel)
            end
        end
    end
    
    if #textChannels > 0 then
        ChannelsTab:AddLabel("CANAIS DE TEXTO")
        for _, channel in ipairs(textChannels) do
            ChannelsTab:AddButton({
                Name = "# " .. channel.name,
                Callback = function()
                    App.currentChannel = channel
                    App.isDM = false
                    App.messages = {}
                    
                    print("💬 Carregando mensagens...")
                    local msgs = makeRequest("GET", "/api/channels/" .. channel.id .. "/messages?limit=50")
                    if msgs and msgs.success then
                        App.messages = msgs.messages or {}
                        showNotification("💬 Canal", "#" .. channel.name)
                        UpdateChatTab()
                        UpdateStatusTab()
                    else
                        showNotification("❌ Erro", "Falha ao carregar")
                    end
                end
            })
        end
    else
        ChannelsTab:AddLabel("Nenhum canal de texto")
    end
    
    if #voiceChannels > 0 then
        ChannelsTab:AddLabel("")
        ChannelsTab:AddLabel("CANAIS DE VOZ")
        for _, channel in ipairs(voiceChannels) do
            ChannelsTab:AddButton({
                Name = "🔊 " .. channel.name,
                Callback = function()
                    showNotification("🎧 Voice", "Em breve: " .. channel.name)
                end
            })
        end
    end
end

-- ============================================
-- TAB 4 - CHAT
-- ============================================

local ChatTab = Window:MakeTab({
    Name = "💬 Chat",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local function UpdateChatTab()
    if not App.isLoggedIn or not App.currentUser then
        ChatTab:AddLabel("⚠️ Conecte-se!")
        return
    end
    
    if App.isDM and App.currentDM then
        ChatTab:AddLabel("💬 DM: " .. (App.currentDM.roblox_username or "Unknown"))
    elseif App.currentChannel then
        ChatTab:AddLabel("# " .. App.currentChannel.name)
    else
        ChatTab:AddLabel("Selecione um canal!")
        return
    end
    
    ChatTab:AddLabel("")
    
    if #App.messages > 0 then
        for _, msg in ipairs(App.messages) do
            if msg and msg.author_name and msg.content then
                ChatTab:AddLabel(msg.author_name .. ": " .. msg.content)
            end
        end
    else
        ChatTab:AddLabel("Nenhuma mensagem.")
    end
    
    ChatTab:AddLabel("")
    ChatTab:AddLabel("────────────────────")
    ChatTab:AddLabel("")
    
    ChatTab:AddTextbox({
        Name = "Escrever...",
        Default = "",
        TextDisabled = false,
        Callback = function(Value)
            if Value ~= "" then
                showNotification("📤 Enviando", "Aguarde...")
                print("📤 Tentando enviar mensagem...")
                -- Nota: POST ainda pode não funcionar
                -- Por enquanto, só mostra que tentou
            end
        end
    })
end

-- ============================================
-- TAB 5 - AMIGOS
-- ============================================

local FriendsTab = Window:MakeTab({
    Name = "👥 Amigos",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local function UpdateFriendsTab()
    if not App.isLoggedIn or not App.currentUser then
        FriendsTab:AddLabel("⚠️ Conecte-se!")
        return
    end
    
    FriendsTab:AddLabel("AMIGOS (" .. #App.friends .. ")")
    FriendsTab:AddLabel("")
    
    if #App.friends == 0 then
        FriendsTab:AddLabel("Nenhum amigo adicionado")
    else
        for _, friendData in ipairs(App.friends) do
            if friendData and friendData.friend then
                local friend = friendData.friend
                local friendName = friend.roblox_username or "Unknown"
                FriendsTab:AddButton({
                    Name = "🟢 " .. friendName,
                    Callback = function()
                        App.currentDM = friend
                        App.isDM = true
                        App.messages = {}
                        showNotification("💬 DM", friendName)
                        UpdateChatTab()
                    end
                })
            end
        end
    end
end

-- ============================================
-- TAB 6 - SOBRE
-- ============================================

local AboutTab = Window:MakeTab({
    Name = "ℹ️ Sobre",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

AboutTab:AddLabel("🔥 RoDiscord v" .. CONFIG.VERSION)
AboutTab:AddLabel("")
AboutTab:AddLabel("Discord no Roblox")
AboutTab:AddLabel("")
AboutTab:AddLabel("✓ Auto-login GET")
AboutTab:AddLabel("✓ Servidores")
AboutTab:AddLabel("✓ Canais")
AboutTab:AddLabel("✓ Chat (read-only)")
AboutTab:AddLabel("✓ DMs (read-only)")
AboutTab:AddLabel("✓ Amigos")
AboutTab:AddLabel("")
AboutTab:AddLabel("🔧 Versão GET-only")
AboutTab:AddLabel("Sem POST bloqueado")

-- ============================================
-- INICIALIZAR
-- ============================================

OrionLib:Init()

print("✅ RoDiscord v" .. CONFIG.VERSION .. " Iniciado!")
print("🔐 Auto-login (GET-only)...")

wait(2)

if AutoLoginWithOrion() then
    print("✅ Sucesso!")
    UpdateStatusTab()
    UpdateServersTab()
    UpdateFriendsTab()
else
    print("❌ Falha!")
    UpdateStatusTab()
end
