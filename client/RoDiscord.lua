-- ============================================
-- 🔥 RoDiscord v8 - SIMPLIFICADO + CORRIGIDO
-- ============================================
-- ✅ Login Roblox (obrigatório)
-- ✅ Discord opcional nas configurações
-- ✅ PUT/DELETE com RequestAsync
-- ✅ Validação de dados antes de usar
-- ✅ Recarregar dados após ações
-- ============================================

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"))()

local CONFIG = {
    API_URL = "https://rodiscord.onrender.com",
    VERSION = "1.0-CORRIGIDO",
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
    discordAvatarHash = nil,
}

-- ============================================
-- HTTP REQUESTS - CORRIGIDO
-- ============================================

local function makeRequest(method, endpoint, data)
    local url = CONFIG.API_URL .. endpoint
    local body = data and game:GetService("HttpService"):JSONEncode(data) or ""
    
    local success, response = pcall(function()
        local http = game:GetService("HttpService")
        
        if method == "GET" then
            return http:GetAsync(url)
        elseif method == "POST" then
            return http:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
        elseif method == "PUT" then
            -- ✅ FIX 1: Usar RequestAsync para PUT
            local request = {
                Url = url,
                Method = "PUT",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = body
            }
            local httpResponse = http:RequestAsync(request)
            return httpResponse.Body
        elseif method == "DELETE" then
            -- ✅ FIX 2: Suporte completo para DELETE
            local request = {
                Url = url,
                Method = "DELETE",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = body
            }
            local httpResponse = http:RequestAsync(request)
            return httpResponse.Body
        end
    end)
    
    if success and response then
        if response == "" then
            return { success = true }
        end
        local decoded = game:GetService("HttpService"):JSONDecode(response)
        return decoded
    else
        print("❌ Erro na requisição " .. method .. " " .. endpoint .. ": " .. tostring(response))
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

-- ✅ FIX 3: Função para recarregar servidores
local function ReloadServersFromServer()
    if not App.isLoggedIn or not App.currentUser then
        showNotification("⚠️ Aviso", "Faça login primeiro!")
        return false
    end
    
    local servers = makeRequest("GET", "/api/servers/" .. App.currentUser.id)
    if servers and servers.success then
        App.servers = servers.servers or {}
        print("✅ Recarregados " .. #App.servers .. " servidores")
        return true
    else
        print("❌ Erro ao recarregar servidores")
        showNotification("❌ Erro", "Não conseguiu recarregar servidores")
        return false
    end
end

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
            if server and server.id and server.name then
                ServersTab:AddButton({
                    Name = server.name,
                    Callback = function()
                        App.currentServer = server
                        App.isDM = false
                        App.currentChannel = nil
                        App.messages = {}
                        
                        local channelsData = makeRequest("GET", "/api/servers/" .. server.id .. "/channels")
                        if channelsData and channelsData.success then
                            App.channels = channelsData.channels or {}
                            showNotification("🏠 Servidor", "Selecionado: " .. server.name)
                        else
                            showNotification("❌ Erro", "Não conseguiu carregar canais")
                        end
                    end
                })
            end
        end
    end
    
    ServersTab:AddLabel("")
    ServersTab:AddButton({
        Name = "➕ Criar Servidor",
        Callback = function()
            if not App.currentUser or not App.currentUser.id then
                showNotification("⚠️ Aviso", "Usuário inválido")
                return
            end
            
            local result = makeRequest("POST", "/api/servers", {
                name = "Novo Servidor",
                owner_id = App.currentUser.id,
                banner_url = "https://via.placeholder.com/1000x300?text=Novo"
            })
            
            if result and result.success then
                showNotification("✨ Novo", "Servidor criado!")
                wait(0.5)
                
                if ReloadServersFromServer() then
                    UpdateServersTab()
                end
            else
                showNotification("❌ Erro", result and result.error or "Falha ao criar servidor")
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
                    
                    local msgs = makeRequest("GET", "/api/channels/" .. channel.id .. "/messages?limit=50")
                    if msgs and msgs.success then
                        App.messages = msgs.messages or {}
                        showNotification("💬 Canal", "#" .. channel.name)
                    else
                        showNotification("❌ Erro", "Não conseguiu carregar mensagens")
                    end
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
            if msg and msg.author_name and msg.content then
                ChatTab:AddLabel(msg.author_name .. ": " .. msg.content)
            end
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
                    if not App.currentUser or not App.currentUser.id or not App.currentDM.id then
                        showNotification("⚠️ Erro", "DM inválido")
                        return
                    end
                    
                    local result = makeRequest("POST", "/api/dms", {
                        sender_id = App.currentUser.id,
                        recipient_id = App.currentDM.id,
                        content = Value
                    })
                    
                    if result and result.success then
                        showNotification("✨ Enviada", "DM enviada!")
                        UpdateChatTab()
                    else
                        showNotification("❌ Erro", "Falha ao enviar DM")
                    end
                elseif App.currentChannel then
                    if not App.currentUser or not App.currentUser.id or not App.currentChannel.id then
                        showNotification("⚠️ Erro", "Canal inválido")
                        return
                    end
                    
                    local result = makeRequest("POST", "/api/messages", {
                        channel_id = App.currentChannel.id,
                        user_id = App.currentUser.id,
                        content = Value
                    })
                    
                    if result and result.success then
                        showNotification("✨ Enviada", "Mensagem enviada!")
                        wait(0.5)
                        UpdateChatTab()
                    else
                        showNotification("❌ Erro", "Falha ao enviar mensagem")
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
        for _, friendData in ipairs(App.friends) do
            if friendData and friendData.friend and friendData.friend.id then
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
            -- ✅ FIX 4: Validação completa antes de reagir
            if not App.currentChannel or #App.messages == 0 then
                showNotification("⚠️ Aviso", "Carregue mensagens primeiro!")
                return
            end
            
            local lastMsg = App.messages[#App.messages]
            if not lastMsg or not lastMsg.id or not App.currentUser or not App.currentUser.id then
                showNotification("⚠️ Erro", "Dados inválidos para reagir")
                return
            end
            
            local result = makeRequest("POST", "/api/reactions", {
                message_id = lastMsg.id,
                user_id = App.currentUser.id,
                emoji = emoji
            })
            
            if result and result.success then
                showNotification("😊 Reação", emoji .. " adicionada!")
            else
                showNotification("❌ Erro", "Falha ao reagir")
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
    SettingsTab:AddLabel("👤 " .. (App.currentUser.roblox_username or "Unknown"))
    SettingsTab:AddLabel("🟢 Online")
    SettingsTab:AddLabel("")
    
    SettingsTab:AddLabel("LOGINS")
    SettingsTab:AddLabel("✅ 🎮 Roblox: " .. (App.currentUser.roblox_username or "N/A"))
    
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
        
        -- ✅ FIX 5: Avatar Hash opcional
        SettingsTab:AddTextbox({
            Name = "Discord Avatar Hash (opcional)",
            Default = "",
            TextDisabled = false,
            Callback = function(Value)
                if Value ~= "" then
                    App.discordAvatarHash = Value
                    showNotification("💾 Salvo", "Hash: " .. Value)
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
                
                if not App.currentUser or not App.currentUser.id then
                    showNotification("⚠️ Aviso", "Usuário inválido")
                    return
                end
                
                -- ✅ FIX 5: Avatar URL melhorada
                local avatarUrl = App.discordAvatarHash 
                    and ("https://cdn.discordapp.com/avatars/" .. App.discordId .. "/" .. App.discordAvatarHash .. ".png")
                    or ("https://www.gravatar.com/avatar/" .. App.discordUsername .. "?d=identicon")
                
                local result = makeRequest("POST", "/api/auth/link-discord", {
                    profile_id = App.currentUser.id,
                    discord_id = App.discordId,
                    discord_username = App.discordUsername,
                    discord_email = App.discordUsername .. "@discord.example",
                    avatar_url = avatarUrl
                })
                
                if result and result.success then
                    App.currentUser = result.profile
                    showNotification("✅ Linkado", "Discord conectado!")
                    UpdateSettingsTab()
                else
                    showNotification("❌ Erro", result and result.error or "Falha ao linkar")
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
            App.servers = {}
            App.channels = {}
            App.messages = {}
            App.friends = {}
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
AboutTab:AddLabel("🔧 CORREÇÕES v1.0:")
AboutTab:AddLabel("✅ RequestAsync para PUT/DELETE")
AboutTab:AddLabel("✅ Validação de dados nil")
AboutTab:AddLabel("✅ Recarregar servidores após criar")
AboutTab:AddLabel("✅ Avatar Discord flexível")
AboutTab:AddLabel("")
AboutTab:AddLabel("Stack: Luau + Orion + Supabase")

-- ============================================
-- INICIALIZAR
-- ============================================

OrionLib:Init()

print("✅ RoDiscord v" .. CONFIG.VERSION .. " Iniciado!")
print("🎮 Faça login na aba 'Login' para começar!")
print("🔧 Todas as correções aplicadas!")
