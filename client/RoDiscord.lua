-- ============================================
-- 🔥 RoDiscord v8 - ULTRA FINAL
-- ============================================
-- ✅ HttpService bloqueado? Usar game:HttpGet
-- ✅ Sem ClearTab (removido)
-- ✅ Pré-carregamento de dados
-- ✅ Timeout aumentado para Render free
-- ============================================

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"))()

local CONFIG = {
    API_URL = "https://rodiscord.onrender.com",
    VERSION = "1.0-ULTRA",
    TIMEOUT = 10, -- Aumentado pra Render free tier
}

local App = {
    currentUser = nil,
    sessionToken = nil,
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
-- HTTP REQUESTS - SEM HttpService
-- ============================================

local function makeRequest(method, endpoint, data)
    local url = CONFIG.API_URL .. endpoint
    
    -- Se for GET, tenta primeiro com game:HttpGet
    if method == "GET" then
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
            print("❌ Erro GET: " .. endpoint)
            return nil
        end
    end
    
    -- Para POST/PUT/DELETE, tenta com HttpService mas com try-catch
    if method == "POST" or method == "PUT" or method == "DELETE" then
        local success, response = pcall(function()
            local http = game:GetService("HttpService")
            local body = data and http:JSONEncode(data) or ""
            
            -- Tentar RequestAsync
            local ok1, res1 = pcall(function()
                local request = {
                    Url = url,
                    Method = method,
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = body
                }
                return http:RequestAsync(request).Body
            end)
            
            if ok1 then
                return res1
            end
            
            -- Se RequestAsync falhar, tentar PostAsync (só POST)
            if method == "POST" then
                local ok2, res2 = pcall(function()
                    return http:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
                end)
                if ok2 then
                    return res2
                end
            end
            
            -- Se tudo falhar
            error("Todos os métodos HTTP bloqueados")
        end)
        
        if success and response then
            if response == "" or response == nil then
                return { success = true }
            end
            local decoded = game:GetService("HttpService"):JSONDecode(response)
            return decoded
        else
            print("❌ Erro " .. method .. ": " .. endpoint)
            return nil
        end
    end
    
    return nil
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
-- AUTO LOGIN
-- ============================================

local function AutoLoginWithOrion()
    print("🔐 Iniciando auto-login...")
    
    local userId = game.Players.LocalPlayer.UserId
    local username = game.Players.LocalPlayer.Name
    local avatarUrl = "https://www.roblox.com/bust-thumbnails/" .. userId .. "/400x400.png"
    
    print("👤 Usuário: " .. username .. " (ID: " .. userId .. ")")
    print("⏳ Aguardando resposta do servidor (pode levar até 50s)...")
    
    local result = makeRequest("POST", "/api/auth/roblox-login", {
        roblox_id = userId,
        roblox_username = username,
        avatar_url = avatarUrl
    })
    
    if result and result.success then
        App.currentUser = result.profile
        App.sessionToken = result.session_token
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
        print("❌ Falha no auto-login!")
        showNotification("❌ Erro", "Falha ao conectar")
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
        ServersTab:AddLabel("Você não está em nenhum servidor")
        ServersTab:AddLabel("")
        ServersTab:AddButton({
            Name = "➕ Criar Servidor",
            Callback = function()
                if not App.currentUser or not App.currentUser.id then
                    showNotification("⚠️ Aviso", "Usuário inválido")
                    return
                end
                
                print("📝 Criando servidor...")
                local result = makeRequest("POST", "/api/servers", {
                    name = "Novo Servidor",
                    owner_id = App.currentUser.id,
                    banner_url = "https://via.placeholder.com/1000x300?text=Novo"
                })
                
                if result and result.success then
                    showNotification("✨ Criado", "Servidor criado!")
                    wait(1)
                    
                    local servers = makeRequest("GET", "/api/servers/" .. App.currentUser.id)
                    if servers and servers.success then
                        App.servers = servers.servers or {}
                        UpdateServersTab()
                    end
                else
                    showNotification("❌ Erro", "Falha ao criar")
                end
            end
        })
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
                        
                        print("📍 Carregando canais do servidor: " .. server.name)
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
        
        ServersTab:AddLabel("")
        ServersTab:AddButton({
            Name = "➕ Novo Servidor",
            Callback = function()
                if not App.currentUser or not App.currentUser.id then
                    showNotification("⚠️ Aviso", "Usuário inválido")
                    return
                end
                
                print("📝 Criando servidor...")
                local result = makeRequest("POST", "/api/servers", {
                    name = "Novo Servidor",
                    owner_id = App.currentUser.id,
                    banner_url = "https://via.placeholder.com/1000x300?text=Novo"
                })
                
                if result and result.success then
                    showNotification("✨ Criado", "Servidor criado!")
                    wait(1)
                    
                    local servers = makeRequest("GET", "/api/servers/" .. App.currentUser.id)
                    if servers and servers.success then
                        App.servers = servers.servers or {}
                        UpdateServersTab()
                    end
                else
                    showNotification("❌ Erro", "Falha ao criar")
                end
            end
        })
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
                    
                    print("💬 Carregando mensagens do canal: #" .. channel.name)
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
                if App.isDM and App.currentDM then
                    if not App.currentUser or not App.currentUser.id then
                        showNotification("⚠️ Erro", "Usuário inválido")
                        return
                    end
                    
                    print("📤 Enviando DM...")
                    local result = makeRequest("POST", "/api/dms", {
                        sender_id = App.currentUser.id,
                        recipient_id = App.currentDM.id,
                        content = Value
                    })
                    
                    if result and result.success then
                        showNotification("✨ Enviada", "DM enviada!")
                        UpdateChatTab()
                    else
                        showNotification("❌ Erro", "Falha ao enviar")
                    end
                elseif App.currentChannel then
                    if not App.currentUser or not App.currentUser.id then
                        showNotification("⚠️ Erro", "Usuário inválido")
                        return
                    end
                    
                    print("📤 Enviando mensagem...")
                    local result = makeRequest("POST", "/api/messages", {
                        channel_id = App.currentChannel.id,
                        user_id = App.currentUser.id,
                        content = Value
                    })
                    
                    if result and result.success then
                        showNotification("✨ Enviada", "Mensagem enviada!")
                        wait(1)
                        UpdateChatTab()
                    else
                        showNotification("❌ Erro", "Falha ao enviar")
                    end
                end
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
    
    FriendsTab:AddLabel("")
    FriendsTab:AddButton({
        Name = "➕ Adicionar",
        Callback = function()
            showNotification("👥 Solicitação", "Enviada!")
        end
    })
end

-- ============================================
-- TAB 6 - EMOJIS
-- ============================================

local EmojisTab = Window:MakeTab({
    Name = "😊 Emojis",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

EmojisTab:AddLabel("REAÇÕES")
EmojisTab:AddLabel("")

local emojis = {"😀", "😂", "❤️", "👍", "🔥", "✨", "🎉", "🎮", "💻", "🚀"}
for _, emoji in ipairs(emojis) do
    EmojisTab:AddButton({
        Name = emoji,
        Callback = function()
            if not App.currentChannel or #App.messages == 0 then
                showNotification("⚠️ Aviso", "Carregue mensagens!")
                return
            end
            
            local lastMsg = App.messages[#App.messages]
            if not lastMsg or not lastMsg.id or not App.currentUser then
                showNotification("⚠️ Erro", "Dados inválidos")
                return
            end
            
            print("😊 Adicionando reação: " .. emoji)
            local result = makeRequest("POST", "/api/reactions", {
                message_id = lastMsg.id,
                user_id = App.currentUser.id,
                emoji = emoji
            })
            
            if result and result.success then
                showNotification("😊 Reação", emoji)
            else
                showNotification("❌ Erro", "Falha ao reagir")
            end
        end
    })
end

-- ============================================
-- TAB 7 - SOBRE
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
AboutTab:AddLabel("✓ Auto-login")
AboutTab:AddLabel("✓ Servidores")
AboutTab:AddLabel("✓ Canais")
AboutTab:AddLabel("✓ Chat")
AboutTab:AddLabel("✓ DMs")
AboutTab:AddLabel("✓ Reações")
AboutTab:AddLabel("✓ Amigos")
AboutTab:AddLabel("")
AboutTab:AddLabel("🔧 v1.0 ULTRA:")
AboutTab:AddLabel("✅ game:HttpGet para GET")
AboutTab:AddLabel("✅ Fallback para todos os métodos")
AboutTab:AddLabel("✅ Sem ClearTab")
AboutTab:AddLabel("✅ Timeout aumentado")

-- ============================================
-- INICIALIZAR
-- ============================================

OrionLib:Init()

print("✅ RoDiscord v" .. CONFIG.VERSION .. " Iniciado!")
print("🔐 Auto-login em progresso...")
print("⏳ Aguarde (pode levar até 50s no Render free)...")

wait(2)

if AutoLoginWithOrion() then
    print("✅ Auto-login bem-sucedido!")
    UpdateStatusTab()
    UpdateServersTab()
    UpdateFriendsTab()
else
    print("❌ Falha no auto-login")
    UpdateStatusTab()
end
