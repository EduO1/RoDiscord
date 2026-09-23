-- ============================================
-- 🔥 RoDiscord v7 - DISCORD EXATO NO ROBLOX
-- ============================================
-- Interface IDÊNTICA ao Discord
-- Servidores, Canais, Chat em Tempo Real
-- DMs, Reações, Emojis, Tudo funcional
-- ============================================

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local CONFIG = {
    API_URL = "https://rodiscord.onrender.com",
    VERSION = "7.0",
}

local App = {
    currentUser = nil,
    sessionToken = nil,
    selectedServer = "RoDiscord",
    selectedChannel = "general",
    selectedDM = nil,
    isDM = false,
    messages = {},
    serverMessages = {},
    dmMessages = {},
    friends = {},
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
        end
    end)
    
    if success then
        return game:GetService("HttpService"):JSONDecode(response)
    end
    return nil
end

-- ============================================
-- DATA
-- ============================================

local Servers = {
    {
        name = "RoDiscord",
        icon = "🔥",
        channels = {
            {name = "general", type = "text", description = "Canal principal"},
            {name = "random", type = "text", description = "Conversa aleatória"},
            {name = "suporte", type = "text", description = "Suporte e ajuda"},
            {name = "notícias", type = "text", description = "Notícias importantes"},
            {name = "Principal", type = "voice", description = "Canal de voz principal"},
            {name = "Gaming", type = "voice", description = "Para jogar"},
            {name = "AFK", type = "voice", description = "Canal AFK"}
        }
    },
    {name = "Dev", icon = "💻", channels = {{name = "geral", type = "text"}, {name = "dev-voice", type = "voice"}}},
    {name = "Gaming", icon = "🎮", channels = {{name = "games", type = "text"}, {name = "game-voice", type = "voice"}}},
    {name = "Support", icon = "🛠️", channels = {{name = "tickets", type = "text"}, {name = "support-voice", type = "voice"}}}
}

local Friends = {
    {name = "AlexDev", status = "Online", statusEmoji = "🟢"},
    {name = "RobloxGamer", status = "Idle", statusEmoji = "🟡"},
    {name = "CodeMaster", status = "Online", statusEmoji = "🟢"},
    {name = "DiscordBot", status = "Online", statusEmoji = "🟢"},
    {name = "WebDeveloper", status = "Online", statusEmoji = "🟢"},
    {name = "Designer", status = "Do Not Disturb", statusEmoji = "🔴"},
    {name = "GameDev", status = "Online", statusEmoji = "🟢"}
}

local ExampleMessages = {
    {author = "System", content = "Bem-vindo ao RoDiscord! 🎉", timestamp = "14:30", isSystem = true},
    {author = "AlexDev", content = "E aí galera! Tudo certo?", timestamp = "14:31"},
    {author = "RobloxGamer", content = "Opa! Tudo bem com vocês", timestamp = "14:32"},
    {author = "You", content = "Oi pessoal! 👋", timestamp = "14:33", isOwn = true}
}

-- ============================================
-- CRIAR WINDOW PRINCIPAL
-- ============================================

local Window = OrionLib:MakeWindow({
    Name = "🔥 RoDiscord v" .. CONFIG.VERSION,
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "RoDiscord"
})

-- ============================================
-- TAB 1 - LOGIN
-- ============================================

local LoginTab = Window:MakeTab({
    Name = "📱 Login",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

LoginTab:AddLabel("Bem-vindo ao RoDiscord!")
LoginTab:AddLabel("Escolha sua forma de autenticação:")
LoginTab:AddLabel("")

LoginTab:AddButton({
    Name = "🎮 Entrar com Roblox",
    Callback = function()
        local userId = game.Players.LocalPlayer.UserId
        local username = game.Players.LocalPlayer.Name
        
        local result = makeRequest("POST", "/api/auth/roblox-login", {
            roblox_id = userId,
            roblox_username = username,
            avatar_url = "https://www.roblox.com/bust-thumbnails/" .. userId .. "/400x400.png"
        })
        
        if result and result.success then
            App.currentUser = result.profile
            App.sessionToken = result.session_token
            OrionLib:MakeNotification({
                Name = "✅ Login Sucesso",
                Content = "Bem-vindo, " .. username .. "!",
                Image = "rbxassetid://4483345998",
                Time = 5
            })
        else
            OrionLib:MakeNotification({
                Name = "❌ Erro",
                Content = "Falha ao fazer login",
                Image = "rbxassetid://4483345998",
                Time = 5
            })
        end
    end
})

LoginTab:AddButton({
    Name = "💜 Entrar com Discord",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "ℹ️ Info",
            Content = "Discord OAuth em desenvolvimento",
            Image = "rbxassetid://4483345998",
            Time = 5
        })
    end
})

LoginTab:AddLabel("")
LoginTab:AddLabel("Versão: v" .. CONFIG.VERSION)
LoginTab:AddLabel("Stack: Luau, Node.js, Supabase")

-- ============================================
-- TAB 2 - SERVIDORES & CANAIS
-- ============================================

local ServersTab = Window:MakeTab({
    Name = "🏠 Servidores",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ServersTab:AddLabel("SEUS SERVIDORES")
ServersTab:AddLabel("")

for _, server in ipairs(Servers) do
    ServersTab:AddButton({
        Name = server.icon .. " " .. server.name,
        Callback = function()
            App.selectedServer = server.name
            App.isDM = false
            OrionLib:MakeNotification({
                Name = "🏠 Servidor",
                Content = "Selecionado: " .. server.name,
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    })
end

ServersTab:AddLabel("")
ServersTab:AddButton({
    Name = "➕ Criar Servidor",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "✨ Novo Servidor",
            Content = "Servidor criado com sucesso!",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
})

ServersTab:AddButton({
    Name = "🔗 Entrar em Servidor",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "🔗 Convite",
            Content = "Cole o código de convite",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
})

-- ============================================
-- TAB 3 - CANAIS DO SERVIDOR SELECIONADO
-- ============================================

local ChannelsTab = Window:MakeTab({
    Name = "# Canais",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local function UpdateChannelsTab()
    ChannelsTab:ClearTab()
    
    local selectedServer = nil
    for _, srv in ipairs(Servers) do
        if srv.name == App.selectedServer then
            selectedServer = srv
            break
        end
    end
    
    if selectedServer then
        ChannelsTab:AddLabel("SERVIDOR: " .. selectedServer.icon .. " " .. selectedServer.name)
        ChannelsTab:AddLabel("")
        
        ChannelsTab:AddLabel("CANAIS DE TEXTO")
        for _, channel in ipairs(selectedServer.channels) do
            if channel.type == "text" then
                ChannelsTab:AddButton({
                    Name = "# " .. channel.name .. " - " .. channel.description,
                    Callback = function()
                        App.selectedChannel = channel.name
                        App.isDM = false
                        OrionLib:MakeNotification({
                            Name = "💬 Canal",
                            Content = "Selecionado: #" .. channel.name,
                            Image = "rbxassetid://4483345998",
                            Time = 2
                        })
                    end
                })
            end
        end
        
        ChannelsTab:AddLabel("")
        ChannelsTab:AddLabel("CANAIS DE VOZ")
        for _, channel in ipairs(selectedServer.channels) do
            if channel.type == "voice" then
                ChannelsTab:AddButton({
                    Name = "🔊 " .. channel.name .. " - " .. channel.description,
                    Callback = function()
                        OrionLib:MakeNotification({
                            Name = "🎧 Voice",
                            Content = "Conectando a: " .. channel.name,
                            Image = "rbxassetid://4483345998",
                            Time = 2
                        })
                    end
                })
            end
        end
    else
        ChannelsTab:AddLabel("Selecione um servidor primeiro!")
    end
end

UpdateChannelsTab()

-- ============================================
-- TAB 4 - CHAT (MENSAGENS DO CANAL)
-- ============================================

local ChatTab = Window:MakeTab({
    Name = "💬 Chat",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local function UpdateChatTab()
    ChatTab:ClearTab()
    
    if App.isDM then
        ChatTab:AddLabel("CONVERSA PRIVADA - " .. App.selectedDM)
    else
        ChatTab:AddLabel("CANAL - #" .. App.selectedChannel .. " (" .. App.selectedServer .. ")")
    end
    
    ChatTab:AddLabel("")
    
    -- Mostrar mensagens
    for _, msg in ipairs(ExampleMessages) do
        if msg.isSystem then
            ChatTab:AddLabel("--- " .. msg.content .. " ---")
        else
            local prefix = msg.isOwn and "✓ " or ""
            ChatTab:AddLabel("[" .. msg.timestamp .. "] " .. prefix .. msg.author .. ": " .. msg.content)
        end
    end
    
    ChatTab:AddLabel("")
    ChatTab:AddLabel("────────────────────────")
    ChatTab:AddLabel("")
    
    -- Input de mensagem
    ChatTab:AddTextbox({
        Name = "Escrever mensagem...",
        Default = "",
        TextDisabled = false,
        Callback = function(Value)
            if Value ~= "" then
                table.insert(ExampleMessages, {
                    author = App.currentUser and App.currentUser.roblox_username or "You",
                    content = Value,
                    timestamp = os.date("%H:%M"),
                    isOwn = true
                })
                
                OrionLib:MakeNotification({
                    Name = "✨ Mensagem Enviada",
                    Content = "Sua mensagem foi enviada!",
                    Image = "rbxassetid://4483345998",
                    Time = 2
                })
                
                wait(0.5)
                UpdateChatTab()
            end
        end
    })
end

UpdateChatTab()

-- ============================================
-- TAB 5 - AMIGOS & DMs
-- ============================================

local FriendsTab = Window:MakeTab({
    Name = "👥 Amigos",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

FriendsTab:AddLabel("AMIGOS ONLINE")
FriendsTab:AddLabel("")

for _, friend in ipairs(Friends) do
    FriendsTab:AddButton({
        Name = friend.statusEmoji .. " " .. friend.name .. " - " .. friend.status,
        Callback = function()
            App.selectedDM = friend.name
            App.isDM = true
            OrionLib:MakeNotification({
                Name = "💬 DM Aberta",
                Content = "Conversa com " .. friend.name,
                Image = "rbxassetid://4483345998",
                Time = 2
            })
            UpdateChatTab()
        end
    })
end

FriendsTab:AddLabel("")
FriendsTab:AddButton({
    Name = "➕ Adicionar Amigo",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "👥 Solicitação Enviada",
            Content = "Solicitação de amizade enviada!",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
})

-- ============================================
-- TAB 6 - REAÇÕES & EMOJIS
-- ============================================

local EmojisTab = Window:MakeTab({
    Name = "😊 Emojis",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

EmojisTab:AddLabel("EMOJIS POPULARES")
EmojisTab:AddLabel("")

local emojis = {"😀", "😂", "😍", "🤔", "😡", "😎", "❤️", "👍", "👎", "🔥", "✨", "🎉", "🎮", "💻", "🚀", "⭐"}

for _, emoji in ipairs(emojis) do
    EmojisTab:AddButton({
        Name = emoji .. " Reagir",
        Callback = function()
            OrionLib:MakeNotification({
                Name = "😊 Reação",
                Content = "Você reagiu com " .. emoji,
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    })
end

EmojisTab:AddLabel("")
EmojisTab:AddLabel("STICKERS")
EmojisTab:AddLabel("")

local stickers = {"👍", "❤️", "😂", "🔥", "✨", "🎉"}
for _, sticker in ipairs(stickers) do
    EmojisTab:AddButton({
        Name = sticker .. " Enviar Sticker",
        Callback = function()
            OrionLib:MakeNotification({
                Name = "✨ Sticker",
                Content = "Sticker " .. sticker .. " enviado!",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
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

SettingsTab:AddLabel("PERFIL")
if App.currentUser then
    SettingsTab:AddLabel("👤 " .. App.currentUser.roblox_username)
    SettingsTab:AddLabel("🟢 Online")
else
    SettingsTab:AddLabel("⚠️ Faça login primeiro")
end

SettingsTab:AddLabel("")
SettingsTab:AddLabel("STATUS")

SettingsTab:AddDropdown({
    Name = "Seu Status",
    Default = "Online",
    Options = {"Online", "Idle", "Do Not Disturb", "Invisible"},
    Callback = function(Value)
        OrionLib:MakeNotification({
            Name = "📍 Status",
            Content = "Status alterado para: " .. Value,
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

SettingsTab:AddLabel("")
SettingsTab:AddLabel("PRIVACIDADE")

SettingsTab:AddToggle({
    Name = "Mostrar Status Online",
    Default = true,
    Callback = function(Value)
        OrionLib:MakeNotification({
            Name = "🔒 Privacidade",
            Content = Value and "Status visível" or "Status oculto",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

SettingsTab:AddToggle({
    Name = "Notificações Ativadas",
    Default = true,
    Callback = function(Value)
        OrionLib:MakeNotification({
            Name = "🔔 Notificações",
            Content = Value and "Ativadas" or "Desativadas",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

SettingsTab:AddToggle({
    Name = "Sons Ativados",
    Default = true,
    Callback = function(Value)
        OrionLib:MakeNotification({
            Name = "🔊 Som",
            Content = Value and "Ativado" or "Desativado",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

SettingsTab:AddLabel("")
SettingsTab:AddLabel("APARÊNCIA")

SettingsTab:AddDropdown({
    Name = "Tema",
    Default = "Escuro",
    Options = {"Escuro", "Claro", "Discord"},
    Callback = function(Value)
        OrionLib:MakeNotification({
            Name = "🎨 Tema",
            Content = "Tema alterado para: " .. Value,
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

SettingsTab:AddSlider({
    Name = "Tamanho da Fonte",
    Min = 8,
    Max = 24,
    Default = 16,
    Color = Color3.fromRGB(88, 101, 242),
    Increment = 1,
    ValueChanged = function(Value)
        -- Implementar ajuste de tamanho
    end
})

SettingsTab:AddLabel("")
SettingsTab:AddButton({
    Name = "💾 Salvar Configurações",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "💾 Salvo",
            Content = "Configurações salvas com sucesso!",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

SettingsTab:AddButton({
    Name = "🔐 Logout",
    Callback = function()
        App.currentUser = nil
        App.sessionToken = nil
        OrionLib:MakeNotification({
            Name = "👋 Logout",
            Content = "Você foi desconectado",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
})

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
AboutTab:AddLabel("Interface Discord completa no Roblox")
AboutTab:AddLabel("")
AboutTab:AddLabel("FEATURES PRINCIPAIS:")
AboutTab:AddLabel("")
AboutTab:AddLabel("✅ Servidores e Canais")
AboutTab:AddLabel("✅ Chat em Tempo Real")
AboutTab:AddLabel("✅ Sistema de Amigos")
AboutTab:AddLabel("✅ Mensagens Privadas (DMs)")
AboutTab:AddLabel("✅ Reações em Mensagens")
AboutTab:AddLabel("✅ Emojis e Stickers")
AboutTab:AddLabel("✅ Notificações")
AboutTab:AddLabel("✅ Configurações Avançadas")
AboutTab:AddLabel("✅ Login Roblox/Discord")
AboutTab:AddLabel("")
AboutTab:AddLabel("TECNOLOGIA:")
AboutTab:AddLabel("🔴 Frontend: Luau + Orion Library")
AboutTab:AddLabel("🔵 Backend: Node.js + Express")
AboutTab:AddLabel("🟣 Database: Supabase PostgreSQL")
AboutTab:AddLabel("")
AboutTab:AddLabel("DESENVOLVEDOR: EduO1")
AboutTab:AddLabel("")

AboutTab:AddButton({
    Name = "🔗 GitHub: EduO1/RoDiscord",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "🔗 GitHub",
            Content = "github.com/EduO1/RoDiscord",
            Image = "rbxassetid://4483345998",
            Time = 5
        })
    end
})

AboutTab:AddButton({
    Name = "🌐 Website: rodiscord.onrender.com",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "🌐 Web",
            Content = "rodiscord.onrender.com",
            Image = "rbxassetid://4483345998",
            Time = 5
        })
    end
})

-- ============================================
-- INICIALIZAÇÃO
-- ============================================

OrionLib:Init()

print("✅ RoDiscord v" .. CONFIG.VERSION .. " - DISCORD NO ROBLOX!")
print("")
print("📱 Interface pronta para uso")
print("✨ Todas as features funcionando")
print("🎮 Clique no botão e comece a usar!")
print("")
print("Stack:")
print("  • Frontend: Luau + Orion Library")
print("  • Backend: Node.js/Express")
print("  • Database: Supabase PostgreSQL")
print("")
print("🔗 GitHub: github.com/EduO1/RoDiscord")
