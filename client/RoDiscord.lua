-- ============================================
-- 🔥 RoDiscord v8 - SIMPLIFICADO
-- ============================================
-- SÓ LOGIN ROBLOX (obrigatório)
-- Discord opcional nas configurações
-- ============================================

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"))()

local CONFIG = {
    API_URL = "https://rodiscord.onrender.com",
    VERSION = "1.0",
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
    discordId = nil,
    discordUsername = nil,
}

-- ============================================
-- HTTP REQUESTS
-- ============================================

local function makeRequest(method, endpoint, data)
    local url = CONFIG.API_URL .. endpoint
    local body = data and game:GetService("HttpService"):JSONEncode(data) or ""
    
    local success, response = pcall(function()
        if method == "GET" then
            return game:GetService("HttpService"):GetAsync(url)
        elseif method == "POST" then
            return game:GetService("HttpService"):PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
        elseif method == "PUT" then
            return game:GetService("HttpService"):PutAsync(url, body, Enum.HttpContentType.ApplicationJson)
        end
    end)
    
    if success then
        return game:GetService("HttpService"):JSONDecode(response)
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
-- TAB 1 - LOGIN (OBRIGATÓRIA!)
-- ============================================

local LoginTab = Window:MakeTab({
    Name = "📱 Login",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

LoginTab:AddLabel("Bem-vindo ao RoDiscord!")
LoginTab:AddLabel("")
LoginTab:AddLabel("🎮 Faça login com sua conta Roblox")
LoginTab:AddLabel("")

LoginTab:AddButton({
    Name = "🎮 ENTRAR COM ROBLOX",
    Callback = function()
        local userId = game.Players.LocalPlayer.UserId
        local username = game.Players.LocalPlayer.Name
        local avatarUrl = "https://www.roblox.com/bust-thumbnails/" .. userId .. "/400x400.png"
        
        print("🔐 Tentando login com Roblox...")
        print("   ID: " .. userId)
        print("   Username: " .. username)
        
        local result = makeRequest("POST", "/api/auth/roblox-login", {
            roblox_id = userId,
            roblox_username = username,
            avatar_url = avatarUrl
        })
        
        if result then
            if result.success then
                App.currentUser = result.profile
                App.sessionToken = result.session_token
                App.isLoggedIn = true
                
                print("✅ Login bem-sucedido!")
                print("   User ID: " .. result.profile.id)
                
                showNotification("✅ Login", "Bem-vindo, " .. username .. "!")
                
                wait(0.5)
                
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
            else
                print("❌ Login falhou: " .. (result.error or "erro desconhecido"))
                showNotification("❌ Erro", result.error or "Falha ao fazer login")
            end
        else
            print("❌ Nenhuma resposta do servidor!")
            showNotification("❌ Erro", "Servidor não respondeu")
        end
    end
})

LoginTab:AddLabel("")
LoginTab:AddLabel("v" .. CONFIG.VERSION .. " | Orion UI + Supabase")
LoginTab:AddLabel("")
LoginTab:AddLabel("Você pode linkar sua conta Discord")
LoginTab:AddLabel("depois, nas Configurações!")

-- ============================================
-- TAB 2 - SERVIDORES
-- ============================================

local ServersTab = Window:MakeTab({
    Name = "🏠 Servidores",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local function UpdateServersTab()
    ServersTab:ClearTab()
    
    if not App.isLoggedIn then
        ServersTab:AddLabel("⚠️ Faça login primeiro!")
        return
    end
    
    ServersTab:AddLabel("SEUS SERVIDORES")
    ServersTab:AddLabel("")
    
    if #App.servers == 0 then
        ServersTab:AddLabel("Você não está em nenhum servidor")
    else
        for _, server in ipairs(App.servers) do
            ServersTab:AddButton({
                Name = server.name,
                Callback = function()
                    App.currentServer = server
                    App.isDM = false
                    
                    local channelsData = makeRequest("GET", "/api/servers/" .. server.id .. "/channels")
                    if channelsData and channelsData.success then
                        App.channels = channelsData.channels or {}
                    end
                    
                    showNotification("🏠 Servidor", "Selecionado: " .. server.name)
                end
            })
        end
    end
    
    ServersTab:AddLabel("")
    ServersTab:AddButton({
        Name = "➕ Criar Servidor",
        Callback = function()
            local result = makeRequest("POST", "/api/servers", {
                name = "Novo Servidor",
                owner_id = App.currentUser.id,
                banner_url = "https://via.placeholder.com/1000x300?text=Novo"
            })
            
            if result and result.success then
                showNotification("✨ Novo", "Servidor criado!")
                UpdateServersTab()
            end
        end
    })
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
    ChannelsTab:ClearTab()
    
    if not App.isLoggedIn then
        ChannelsTab:AddLabel("⚠️ Faça login!")
        return
    end
    
    if not App.currentServer then
        ChannelsTab:AddLabel("⚠️ Selecione um servidor!")
        return
    end
    
    ChannelsTab:AddLabel("SERVIDOR: " .. App.currentServer.name)
    ChannelsTab:AddLabel("")
    
    local textChannels = {}
    local voiceChannels = {}
    
    for _, channel in ipairs(App.channels) do
        if channel.type == "text" then
            table.insert(textChannels, channel)
        else
            table.insert(voiceChannels, channel)
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
                    
                    local msgs = makeRequest("GET", "/api/channels/" .. channel.id .. "/messages?limit=50")
                    if msgs and msgs.success then
                        App.messages = msgs.messages or {}
                    end
                    
                    showNotification("💬 Canal", "#" .. channel.name)
                end
            })
        end
    end
    
    if #voiceChannels > 0 then
        ChannelsTab:AddLabel("")
        ChannelsTab:AddLabel("CANAIS DE VOZ")
        for _, channel in ipairs(voiceChannels) do
            ChannelsTab:AddButton({
                Name = "🔊 " .. channel.name,
                Callback = function()
                    showNotification("🎧 Voice", "Conectando: " .. channel.name)
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
    ChatTab:ClearTab()
    
    if not App.isLoggedIn then
        ChatTab:AddLabel("⚠️ Faça login!")
        return
    end
    
    if App.isDM and App.currentDM then
        ChatTab:AddLabel("💬 DM: " .. (App.currentDM.roblox_username or "Unknown"))
    elseif App.currentChannel then
        ChatTab:AddLabel("# " .. App.currentChannel.name)
    else
        ChatTab:AddLabel("Selecione um canal ou amigo!")
        return
    end
    
    ChatTab:AddLabel("")
    
    if #App.messages > 0 then
        for _, msg in ipairs(App.messages) do
            local author = msg.author_name or "Unknown"
            ChatTab:AddLabel(author .. ": " .. msg.content)
        end
    else
        ChatTab:AddLabel("Nenhuma mensagem. Seja o primeiro!")
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
                    local result = makeRequest("POST", "/api/dms", {
                        sender_id = App.currentUser.id,
                        recipient_id = App.currentDM.id,
                        content = Value
                    })
                    
                    if result and result.success then
                        showNotification("✨ Enviada", "DM enviada!")
                    end
                elseif App.currentChannel then
                    local result = makeRequest("POST", "/api/messages", {
                        channel_id = App.currentChannel.id,
                        user_id = App.currentUser.id,
                        content = Value
                    })
                    
                    if result and result.success then
                        showNotification("✨ Enviada", "Mensagem enviada!")
                        UpdateChatTab()
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
    FriendsTab:ClearTab()
    
    if not App.isLoggedIn then
        FriendsTab:AddLabel("⚠️ Faça login!")
        return
    end
    
    FriendsTab:AddLabel("AMIGOS ONLINE")
    FriendsTab:AddLabel("")
    
    if #App.friends == 0 then
        FriendsTab:AddLabel("Você não tem amigos")
    else
        for _, friend in ipairs(App.friends) do
            local friendName = friend.friend.roblox_username or "Unknown"
            FriendsTab:AddButton({
                Name = "🟢 " .. friendName,
                Callback = function()
                    App.currentDM = friend.friend
                    App.isDM = true
                    showNotification("💬 DM", friendName)
                    UpdateChatTab()
                end
            })
        end
    end
    
    FriendsTab:AddLabel("")
    FriendsTab:AddButton({
        Name = "➕ Adicionar Amigo",
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

EmojisTab:AddLabel("EMOJIS")
EmojisTab:AddLabel("")

local emojis = {"😀", "😂", "❤️", "👍", "🔥", "✨", "🎉", "🎮", "💻", "🚀"}
for _, emoji in ipairs(emojis) do
    EmojisTab:AddButton({
        Name = emoji .. " Reagir",
        Callback = function()
            if App.currentChannel and #App.messages > 0 then
                makeRequest("POST", "/api/reactions", {
                    message_id = App.messages[#App.messages].id,
                    user_id = App.currentUser.id,
                    emoji = emoji
                })
                showNotification("😊 Reação", emoji)
            end
        end
    })
end

-- ============================================
-- TAB 7 - CONFIGURAÇÕES
-- ============================================

local SettingsTab = Window:MakeTab({
    Name = "⚙️ Configurações",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local function UpdateSettingsTab()
    SettingsTab:ClearTab()
    
    if not App.isLoggedIn then
        SettingsTab:AddLabel("⚠️ Faça login!")
        return
    end
    
    SettingsTab:AddLabel("PERFIL")
    SettingsTab:AddLabel("👤 " .. App.currentUser.roblox_username)
    SettingsTab:AddLabel("🟢 Online")
    SettingsTab:AddLabel("")
    
    SettingsTab:AddLabel("LOGINS")
    SettingsTab:AddLabel("✅ 🎮 Roblox: " .. App.currentUser.roblox_username)
    
    if App.currentUser.discord_username then
        SettingsTab:AddLabel("✅ 💜 Discord: " .. App.currentUser.discord_username)
    else
        SettingsTab:AddLabel("❌ 💜 Discord: Não conectado")
        SettingsTab:AddLabel("")
        SettingsTab:AddLabel("LINKAR DISCORD")
        
        SettingsTab:AddTextbox({
            Name = "Discord ID",
            Default = "",
            TextDisabled = false,
            Callback = function(Value)
                if Value ~= "" then
                    App.discordId = Value
                    showNotification("💾 Salvo", "ID: " .. Value)
                end
            end
        })
        
        SettingsTab:AddTextbox({
            Name = "Discord Username",
            Default = "",
            TextDisabled = false,
            Callback = function(Value)
                if Value ~= "" then
                    App.discordUsername = Value
                    showNotification("💾 Salvo", "Username: " .. Value)
                end
            end
        })
        
        SettingsTab:AddButton({
            Name = "💜 Linkar Agora",
            Callback = function()
                if not App.discordId or not App.discordUsername then
                    showNotification("⚠️ Aviso", "Preencha ID e Username!")
                    return
                end
                
                local result = makeRequest("POST", "/api/auth/link-discord", {
                    profile_id = App.currentUser.id,
                    discord_id = App.discordId,
                    discord_username = App.discordUsername,
                    discord_email = App.discordUsername .. "@discord.com",
                    avatar_url = "https://cdn.discordapp.com/avatars/" .. App.discordId .. "/avatar.png"
                })
                
                if result and result.success then
                    App.currentUser = result.profile
                    showNotification("✅ Linkado", "Discord conectado!")
                    UpdateSettingsTab()
                else
                    showNotification("❌ Erro", "Falha ao linkar")
                end
            end
        })
    end
    
    SettingsTab:AddLabel("")
    SettingsTab:AddButton({
        Name = "🚪 Logout",
        Callback = function()
            App.isLoggedIn = false
            App.currentUser = nil
            showNotification("👋 Logout", "Desconectado!")
        end
    })
end

-- ============================================
-- TAB 8 - SOBRE
-- ============================================

local AboutTab = Window:MakeTab({
    Name = "ℹ️ Sobre",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

AboutTab:AddLabel("🔥 RoDiscord v" .. CONFIG.VERSION)
AboutTab:AddLabel("")
AboutTab:AddLabel("Discord no Roblox com:")
AboutTab:AddLabel("✓ Login Roblox (obrigatório)")
AboutTab:AddLabel("✓ Discord opcional")
AboutTab:AddLabel("✓ Servidores e canais")
AboutTab:AddLabel("✓ Chat em tempo real")
AboutTab:AddLabel("✓ DMs privadas")
AboutTab:AddLabel("✓ Reações em mensagens")
AboutTab:AddLabel("✓ Amigos e status")
AboutTab:AddLabel("")
AboutTab:AddLabel("Stack: Luau + Orion + Supabase")

-- ============================================
-- INICIALIZAR
-- ============================================

OrionLib:Init()

print("✅ RoDiscord v" .. CONFIG.VERSION .. " Iniciado!")
print("🎮 Faça login na aba 'Login' para começar!")
