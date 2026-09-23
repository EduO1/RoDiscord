-- ============================================
-- RODISCORD v2 - CLIENT (Roblox Executor)
-- ============================================
-- 100% Luau | Sem dependências externas
-- Recursos: Configurações, Emojis, Stickers
-- ============================================

local CONFIG = {
    -- API Backend
    API_URL = "https://rodiscord.onrender.com",
    
    -- Cores Discord Oficiais
    COLORS = {
        BLURPLE = Color3.fromRGB(88, 101, 242),
        BACKGROUND = Color3.fromRGB(49, 51, 56),
        SIDEBAR = Color3.fromRGB(43, 45, 49),
        INPUT = Color3.fromRGB(30, 31, 34),
        TEXT_PRIMARY = Color3.fromRGB(219, 222, 225),
        TEXT_SECONDARY = Color3.fromRGB(181, 186, 193),
        BORDER = Color3.fromRGB(79, 84, 92),
        SUCCESS = Color3.fromRGB(87, 171, 90),
        DANGER = Color3.fromRGB(240, 71, 71)
    },
    
    -- UI Dimensions
    SIDEBAR_WIDTH = 260,
    CHANNEL_PANEL_WIDTH = 200,
    SETTINGS_PANEL_WIDTH = 300,
    
    -- Polling
    MESSAGE_FETCH_INTERVAL = 2,
    POLL_INTERVAL = 3,
    
    -- Limites
    MAX_MESSAGE_LENGTH = 2000,
    MAX_EMOJI_NAME = 50,
    MAX_STICKER_NAME = 100
}

-- ============================================
-- VARIÁVEIS GLOBAIS
-- ============================================

local RoDiscord = {
    -- Autenticação
    currentUser = nil,
    sessionToken = nil,
    
    -- Estado da UI
    selectedServer = nil,
    selectedChannel = nil,
    showSettings = false,
    currentTab = "messages",
    
    -- Dados
    servers = {},
    channels = {},
    messages = {},
    dms = {},
    customEmojis = {},
    stickers = {},
    serverSettings = nil,
    
    -- UI References
    mainGui = nil,
    mainFrame = nil,
    messageList = nil,
    messageInput = nil,
    settingsPanel = nil
}

-- ============================================
-- FUNÇÕES UTILITÁRIAS HTTP
-- ============================================

local function makeRequest(method, endpoint, data)
    local url = CONFIG.API_URL .. endpoint
    local headers = {
        ["Content-Type"] = "application/json"
    }
    
    if RoDiscord.sessionToken then
        headers["Authorization"] = "Bearer " .. RoDiscord.sessionToken
    end
    
    local body = nil
    if data then
        body = game:GetService("HttpService"):JSONEncode(data)
    end
    
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
        local decoded = game:GetService("HttpService"):JSONDecode(response)
        return decoded
    else
        warn("[RoDiscord] Erro na requisição:", response)
        return nil
    end
end

-- ============================================
-- TELAS DE AUTENTICAÇÃO
-- ============================================

local function showAuthScreen()
    if RoDiscord.mainGui then
        RoDiscord.mainGui:Destroy()
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "RoDiscordAuth"
    gui.ResetOnSpawn = false
    
    local guiParent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    gui.Parent = guiParent
    
    -- Background com gradiente
    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = CONFIG.COLORS.BACKGROUND
    bg.BorderSizePixel = 0
    bg.Parent = gui
    
    -- Container central
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 450, 0, 600)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.BackgroundColor3 = CONFIG.COLORS.SIDEBAR
    container.BorderSizePixel = 1
    container.BorderColor3 = CONFIG.COLORS.BORDER
    container.Parent = bg
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = container
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 25)
    padding.PaddingRight = UDim.new(0, 25)
    padding.PaddingTop = UDim.new(0, 25)
    padding.PaddingBottom = UDim.new(0, 25)
    padding.Parent = container
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 20)
    layout.Parent = container
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 70)
    title.BackgroundTransparency = 1
    title.Text = "🔥 RoDiscord"
    title.TextColor3 = CONFIG.COLORS.BLURPLE
    title.TextSize = 48
    title.Font = Enum.Font.GothamBold
    title.Parent = container
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, 0, 0, 35)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Discord no Roblox - Sem Restrições"
    subtitle.TextColor3 = CONFIG.COLORS.TEXT_SECONDARY
    subtitle.TextSize = 14
    subtitle.Font = Enum.Font.Gotham
    subtitle.Parent = container
    
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.BackgroundColor3 = CONFIG.COLORS.BORDER
    divider.BorderSizePixel = 0
    divider.Parent = container
    
    -- Botão Discord Login
    local discordButton = Instance.new("TextButton")
    discordButton.Name = "DiscordButton"
    discordButton.Size = UDim2.new(1, 0, 0, 50)
    discordButton.BackgroundColor3 = CONFIG.COLORS.BLURPLE
    discordButton.BorderSizePixel = 0
    discordButton.Text = "Logar com Discord"
    discordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    discordButton.TextSize = 16
    discordButton.Font = Enum.Font.GothamBold
    discordButton.Parent = container
    
    local discordCorner = Instance.new("UICorner")
    discordCorner.CornerRadius = UDim.new(0, 8)
    discordCorner.Parent = discordButton
    
    discordButton.MouseButton1Click:Connect(function()
        local authUrl = CONFIG.API_URL .. "/auth/discord"
        local message = "📱 Cole esta URL no navegador:\n\n" .. authUrl .. "\n\n✅ Após logar, você receberá um PIN.\nCole o PIN abaixo para continuar no Roblox."
        showPinInputModal(message)
    end)
    
    -- Botão Roblox Login
    local robloxButton = Instance.new("TextButton")
    robloxButton.Name = "RobloxButton"
    robloxButton.Size = UDim2.new(1, 0, 0, 50)
    robloxButton.BackgroundColor3 = CONFIG.COLORS.INPUT
    robloxButton.BorderSizePixel = 1
    robloxButton.BorderColor3 = CONFIG.COLORS.BORDER
    robloxButton.Text = "Usar Roblox"
    robloxButton.TextColor3 = CONFIG.COLORS.TEXT_PRIMARY
    robloxButton.TextSize = 16
    robloxButton.Font = Enum.Font.GothamBold
    robloxButton.Parent = container
    
    local robloxCorner = Instance.new("UICorner")
    robloxCorner.CornerRadius = UDim.new(0, 8)
    robloxCorner.Parent = robloxButton
    
    robloxButton.MouseButton1Click:Connect(function()
        local userId = game.Players.LocalPlayer.UserId
        local username = game.Players.LocalPlayer.Name
        local avatarUrl = "https://www.roblox.com/bust-thumbnails/" .. userId .. "/400x400.png"
        
        local data = {
            roblox_id = userId,
            roblox_username = username,
            avatar_url = avatarUrl
        }
        
        local result = makeRequest("POST", "/api/auth/roblox-login", data)
        
        if result and result.success then
            RoDiscord.currentUser = result.profile
            RoDiscord.sessionToken = result.session_token
            gui:Destroy()
            initializeMainUI()
        else
            warn("Erro no login Roblox")
        end
    end)
    
    RoDiscord.mainGui = gui
end

local function showPinInputModal(instructionText)
    local modal = Instance.new("ScreenGui")
    modal.Name = "PinModal"
    modal.ResetOnSpawn = false
    
    local guiParent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    modal.Parent = guiParent
    
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = modal
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 500, 0, 450)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.BackgroundColor3 = CONFIG.COLORS.SIDEBAR
    container.BorderColor3 = CONFIG.COLORS.BORDER
    container.BorderSizePixel = 1
    container.Parent = modal
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = container
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 25)
    padding.PaddingRight = UDim.new(0, 25)
    padding.PaddingTop = UDim.new(0, 25)
    padding.PaddingBottom = UDim.new(0, 25)
    padding.Parent = container
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 15)
    layout.Parent = container
    
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(1, 0, 0, 100)
    instructions.BackgroundTransparency = 1
    instructions.Text = instructionText
    instructions.TextColor3 = CONFIG.COLORS.TEXT_SECONDARY
    instructions.TextSize = 13
    instructions.Font = Enum.Font.Gotham
    instructions.TextWrapped = true
    instructions.TextXAlignment = Enum.TextXAlignment.Center
    instructions.TextYAlignment = Enum.TextYAlignment.Top
    instructions.Parent = container
    
    local pinInputBg = Instance.new("Frame")
    pinInputBg.Name = "PinInputBg"
    pinInputBg.Size = UDim2.new(1, 0, 0, 50)
    pinInputBg.BackgroundColor3 = CONFIG.COLORS.INPUT
    pinInputBg.BorderColor3 = CONFIG.COLORS.BORDER
    pinInputBg.BorderSizePixel = 1
    pinInputBg.Parent = container
    
    local pinInputCorner = Instance.new("UICorner")
    pinInputCorner.CornerRadius = UDim.new(0, 8)
    pinInputCorner.Parent = pinInputBg
    
    local pinInput = Instance.new("TextBox")
    pinInput.Name = "PinInput"
    pinInput.Size = UDim2.new(1, 0, 1, 0)
    pinInput.BackgroundTransparency = 1
    pinInput.BorderSizePixel = 0
    pinInput.Text = ""
    pinInput.PlaceholderText = "Cole o PIN de 6 dígitos aqui"
    pinInput.TextColor3 = CONFIG.COLORS.TEXT_PRIMARY
    pinInput.PlaceholderColor3 = CONFIG.COLORS.TEXT_SECONDARY
    pinInput.TextSize = 20
    pinInput.Font = Enum.Font.GothamBold
    pinInput.Parent = pinInputBg
    
    local pinInputPadding = Instance.new("UIPadding")
    pinInputPadding.PaddingLeft = UDim.new(0, 15)
    pinInputPadding.PaddingRight = UDim.new(0, 15)
    pinInputPadding.Parent = pinInput
    
    local verifyButton = Instance.new("TextButton")
    verifyButton.Name = "VerifyButton"
    verifyButton.Size = UDim2.new(1, 0, 0, 50)
    verifyButton.BackgroundColor3 = CONFIG.COLORS.BLURPLE
    verifyButton.BorderSizePixel = 0
    verifyButton.Text = "✅ Verificar PIN"
    verifyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    verifyButton.TextSize = 16
    verifyButton.Font = Enum.Font.GothamBold
    verifyButton.Parent = container
    
    local verifyCorner = Instance.new("UICorner")
    verifyCorner.CornerRadius = UDim.new(0, 8)
    verifyCorner.Parent = verifyButton
    
    verifyButton.MouseButton1Click:Connect(function()
        local pin = pinInput.Text:gsub("%s+", "")
        
        if #pin ~= 6 then
            pinInput.PlaceholderText = "PIN deve ter exatamente 6 dígitos!"
            return
        end
        
        local result = makeRequest("POST", "/api/auth/verify-pin", { pin = pin })
        
        if result and result.success then
            RoDiscord.currentUser = result.profile
            RoDiscord.sessionToken = result.profile.session_token
            modal:Destroy()
            RoDiscord.mainGui:Destroy()
            initializeMainUI()
        else
            pinInput.PlaceholderText = "PIN inválido ou expirado!"
            pinInput.Text = ""
        end
    end)
    
    local cancelButton = Instance.new("TextButton")
    cancelButton.Name = "CancelButton"
    cancelButton.Size = UDim2.new(1, 0, 0, 40)
    cancelButton.BackgroundColor3 = CONFIG.COLORS.INPUT
    cancelButton.BorderColor3 = CONFIG.COLORS.BORDER
    cancelButton.BorderSizePixel = 1
    cancelButton.Text = "❌ Cancelar"
    cancelButton.TextColor3 = CONFIG.COLORS.TEXT_SECONDARY
    cancelButton.TextSize = 14
    cancelButton.Font = Enum.Font.Gotham
    cancelButton.Parent = container
    
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 8)
    cancelCorner.Parent = cancelButton
    
    cancelButton.MouseButton1Click:Connect(function()
        modal:Destroy()
    end)
end

-- ============================================
-- PAINEL DE CONFIGURAÇÕES
-- ============================================

local function createSettingsPanel(parent)
    local settingsPanel = Instance.new("Frame")
    settingsPanel.Name = "SettingsPanel"
    settingsPanel.Size = UDim2.new(0, CONFIG.SETTINGS_PANEL_WIDTH, 1, 0)
    settingsPanel.Position = UDim2.new(1, 0, 0, 0)
    settingsPanel.BackgroundColor3 = CONFIG.COLORS.BACKGROUND
    settingsPanel.BorderColor3 = CONFIG.COLORS.BORDER
    settingsPanel.BorderSizePixel = 1
    settingsPanel.Visible = false
    settingsPanel.Parent = parent
    
    -- Cabeçalho
    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = CONFIG.COLORS.SIDEBAR
    header.BorderColor3 = CONFIG.COLORS.BORDER
    header.BorderSizePixel = 1
    header.Text = "⚙️ Configurações"
    header.TextColor3 = CONFIG.COLORS.TEXT_PRIMARY
    header.TextSize = 16
    header.Font = Enum.Font.GothamBold
    header.Parent = settingsPanel
    
    -- Botão fechar
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -45, 0, 5)
    closeButton.BackgroundColor3 = CONFIG.COLORS.DANGER
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        settingsPanel.Visible = false
        RoDiscord.showSettings = false
    end)
    
    -- ScrollFrame para conteúdo
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, 0, 1, -50)
    scrollFrame.Position = UDim2.new(0, 0, 0, 50)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.Parent = settingsPanel
    
    local scrollLayout = Instance.new("UIListLayout")
    scrollLayout.FillDirection = Enum.FillDirection.Vertical
    scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Fill
    scrollLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    scrollLayout.Padding = UDim.new(0, 10)
    scrollLayout.Parent = scrollFrame
    
    local scrollPadding = Instance.new("UIPadding")
    scrollPadding.PaddingLeft = UDim.new(0, 10)
    scrollPadding.PaddingRight = UDim.new(0, 10)
    scrollPadding.PaddingTop = UDim.new(0, 10)
    scrollPadding.PaddingBottom = UDim.new(0, 10)
    scrollPadding.Parent = scrollFrame
    
    -- Abas de configuração
    local tabs = {"Servidor", "Segurança", "Emojis", "Stickers"}
    
    for _, tabName in ipairs(tabs) do
        local tab = Instance.new("TextButton")
        tab.Name = "Tab_" .. tabName
        tab.Size = UDim2.new(1, 0, 0, 40)
        tab.BackgroundColor3 = CONFIG.COLORS.INPUT
        tab.BorderColor3 = CONFIG.COLORS.BORDER
        tab.BorderSizePixel = 1
        tab.Text = "📋 " .. tabName
        tab.TextColor3 = CONFIG.COLORS.TEXT_PRIMARY
        tab.TextSize = 12
        tab.Font = Enum.Font.Gotham
        tab.Parent = scrollFrame
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 6)
        tabCorner.Parent = tab
        
        tab.MouseButton1Click:Connect(function()
            print("Abrindo aba: " .. tabName)
            RoDiscord.currentTab = tabName:lower()
        end)
    end
    
    -- Seção: Configurações do Servidor
    local serverTitle = Instance.new("TextLabel")
    serverTitle.Name = "ServerTitle"
    serverTitle.Size = UDim2.new(1, 0, 0, 30)
    serverTitle.BackgroundTransparency = 1
    serverTitle.Text = "🖥️ Servidor"
    serverTitle.TextColor3 = CONFIG.COLORS.BLURPLE
    serverTitle.TextSize = 14
    serverTitle.Font = Enum.Font.GothamBold
    serverTitle.Parent = scrollFrame
    
    -- Toggle: Emojis personalizados
    local emojiToggleBg = Instance.new("Frame")
    emojiToggleBg.Name = "EmojiToggleBg"
    emojiToggleBg.Size = UDim2.new(1, 0, 0, 35)
    emojiToggleBg.BackgroundColor3 = CONFIG.COLORS.INPUT
    emojiToggleBg.BorderColor3 = CONFIG.COLORS.BORDER
    emojiToggleBg.BorderSizePixel = 1
    emojiToggleBg.Parent = scrollFrame
    
    local emojiToggleCorner = Instance.new("UICorner")
    emojiToggleCorner.CornerRadius = UDim.new(0, 6)
    emojiToggleCorner.Parent = emojiToggleBg
    
    local emojiLabel = Instance.new("TextLabel")
    emojiLabel.Name = "EmojiLabel"
    emojiLabel.Size = UDim2.new(0.7, 0, 1, 0)
    emojiLabel.Position = UDim2.new(0, 10, 0, 0)
    emojiLabel.BackgroundTransparency = 1
    emojiLabel.Text = "Emojis Personalizados"
    emojiLabel.TextColor3 = CONFIG.COLORS.TEXT_PRIMARY
    emojiLabel.TextSize = 12
    emojiLabel.Font = Enum.Font.Gotham
    emojiLabel.Parent = emojiToggleBg
    
    local emojiToggleButton = Instance.new("TextButton")
    emojiToggleButton.Name = "EmojiToggleButton"
    emojiToggleButton.Size = UDim2.new(0, 35, 0, 25)
    emojiToggleButton.Position = UDim2.new(1, -40, 0.5, -12)
    emojiToggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
    emojiToggleButton.BackgroundColor3 = CONFIG.COLORS.SUCCESS
    emojiToggleButton.BorderSizePixel = 0
    emojiToggleButton.Text = "ON"
    emojiToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    emojiToggleButton.TextSize = 10
    emojiToggleButton.Font = Enum.Font.GothamBold
    emojiToggleButton.Parent = emojiToggleBg
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = emojiToggleButton
    
    -- Toggle: Figurinhas
    local stickerToggleBg = Instance.new("Frame")
    stickerToggleBg.Name = "StickerToggleBg"
    stickerToggleBg.Size = UDim2.new(1, 0, 0, 35)
    stickerToggleBg.BackgroundColor3 = CONFIG.COLORS.INPUT
    stickerToggleBg.BorderColor3 = CONFIG.COLORS.BORDER
    stickerToggleBg.BorderSizePixel = 1
    stickerToggleBg.Parent = scrollFrame
    
    local stickerToggleCorner = Instance.new("UICorner")
    stickerToggleCorner.CornerRadius = UDim.new(0, 6)
    stickerToggleCorner.Parent = stickerToggleBg
    
    local stickerLabel = Instance.new("TextLabel")
    stickerLabel.Name = "StickerLabel"
    stickerLabel.Size = UDim2.new(0.7, 0, 1, 0)
    stickerLabel.Position = UDim2.new(0, 10, 0, 0)
    stickerLabel.BackgroundTransparency = 1
    stickerLabel.Text = "Permitir Figurinhas"
    stickerLabel.TextColor3 = CONFIG.COLORS.TEXT_PRIMARY
    stickerLabel.TextSize = 12
    stickerLabel.Font = Enum.Font.Gotham
    stickerLabel.Parent = stickerToggleBg
    
    local stickerToggleButton = Instance.new("TextButton")
    stickerToggleButton.Name = "StickerToggleButton"
    stickerToggleButton.Size = UDim2.new(0, 35, 0, 25)
    stickerToggleButton.Position = UDim2.new(1, -40, 0.5, -12)
    stickerToggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
    stickerToggleButton.BackgroundColor3 = CONFIG.COLORS.SUCCESS
    stickerToggleButton.BorderSizePixel = 0
    stickerToggleButton.Text = "ON"
    stickerToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    stickerToggleButton.TextSize = 10
    stickerToggleButton.Font = Enum.Font.GothamBold
    stickerToggleButton.Parent = stickerToggleBg
    
    local stickerToggleCorner = Instance.new("UICorner")
    stickerToggleCorner.CornerRadius = UDim.new(0, 4)
    stickerToggleCorner.Parent = stickerToggleButton
    
    -- Seção: Emojis Personalizados
    local emojisTitle = Instance.new("TextLabel")
    emojisTitle.Name = "EmojisTitle"
    emojisTitle.Size = UDim2.new(1, 0, 0, 30)
    emojisTitle.BackgroundTransparency = 1
    emojisTitle.Text = "😀 Emojis"
    emojisTitle.TextColor3 = CONFIG.COLORS.BLURPLE
    emojisTitle.TextSize = 14
    emojisTitle.Font = Enum.Font.GothamBold
    emojisTitle.Parent = scrollFrame
    
    local emojisCount = Instance.new("TextLabel")
    emojisCount.Name = "EmojisCount"
    emojisCount.Size = UDim2.new(1, 0, 0, 25)
    emojisCount.BackgroundTransparency = 1
    emojisCount.Text = "Você tem " .. #RoDiscord.customEmojis .. " emojis personalizados"
    emojisCount.TextColor3 = CONFIG.COLORS.TEXT_SECONDARY
    emojisCount.TextSize = 11
    emojisCount.Font = Enum.Font.Gotham
    emojisCount.Parent = scrollFrame
    
    local addEmojiButton = Instance.new("TextButton")
    addEmojiButton.Name = "AddEmojiButton"
    addEmojiButton.Size = UDim2.new(1, 0, 0, 35)
    addEmojiButton.BackgroundColor3 = CONFIG.COLORS.BLURPLE
    addEmojiButton.BorderSizePixel = 0
    addEmojiButton.Text = "+ Adicionar Emoji"
    addEmojiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    addEmojiButton.TextSize = 12
    addEmojiButton.Font = Enum.Font.GothamBold
    addEmojiButton.Parent = scrollFrame
    
    local addEmojiCorner = Instance.new("UICorner")
    addEmojiCorner.CornerRadius = UDim.new(0, 6)
    addEmojiCorner.Parent = addEmojiButton
    
    addEmojiButton.MouseButton1Click:Connect(function()
        showAddEmojiModal()
    end)
    
    -- Seção: Figurinhas
    local stickersTitle = Instance.new("TextLabel")
    stickersTitle.Name = "StickersTitle"
    stickersTitle.Size = UDim2.new(1, 0, 0, 30)
    stickersTitle.BackgroundTransparency = 1
    stickersTitle.Text = "🎨 Figurinhas"
    stickersTitle.TextColor3 = CONFIG.COLORS.BLURPLE
    stickersTitle.TextSize = 14
    stickersTitle.Font = Enum.Font.GothamBold
    stickersTitle.Parent = scrollFrame
    
    local stickersCount = Instance.new("TextLabel")
    stickersCount.Name = "StickersCount"
    stickersCount.Size = UDim2.new(1, 0, 0, 25)
    stickersCount.BackgroundTransparency = 1
    stickersCount.Text = "Você tem " .. #RoDiscord.stickers .. " figurinhas"
    stickersCount.TextColor3 = CONFIG.COLORS.TEXT_SECONDARY
    stickersCount.TextSize = 11
    stickersCount.Font = Enum.Font.Gotham
    stickersCount.Parent = scrollFrame
    
    local addStickerButton = Instance.new("TextButton")
    addStickerButton.Name = "AddStickerButton"
    addStickerButton.Size = UDim2.new(1, 0, 0, 35)
    addStickerButton.BackgroundColor3 = CONFIG.COLORS.BLURPLE
    addStickerButton.BorderSizePixel = 0
    addStickerButton.Text = "+ Adicionar Figurinha"
    addStickerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    addStickerButton.TextSize = 12
    addStickerButton.Font = Enum.Font.GothamBold
    addStickerButton.Parent = scrollFrame
    
    local addStickerCorner = Instance.new("UICorner")
    addStickerCorner.CornerRadius = UDim.new(0, 6)
    addStickerCorner.Parent = addStickerButton
    
    addStickerButton.MouseButton1Click:Connect(function()
        showAddStickerModal()
    end)
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 20)
    
    return settingsPanel
end

-- ============================================
-- MODAIS PARA ADICIONAR EMOJI/STICKER
-- ============================================

local function showAddEmojiModal()
    local modal = Instance.new("ScreenGui")
    modal.Name = "AddEmojiModal"
    modal.ResetOnSpawn = false
    
    local guiParent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    modal.Parent = guiParent
    
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = modal
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 450, 0, 350)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.BackgroundColor3 = CONFIG.COLORS.SIDEBAR
    container.BorderColor3 = CONFIG.COLORS.BORDER
    container.BorderSizePixel = 1
    container.Parent = modal
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = container
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 20)
    padding.PaddingRight = UDim.new(0, 20)
    padding.PaddingTop = UDim.new(0, 20)
    padding.PaddingBottom = UDim.new(0, 20)
    padding.Parent = container
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 12)
    layout.Parent = container
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "😀 Novo Emoji"
    title.TextColor3 = CONFIG.COLORS.TEXT_PRIMARY
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = container
    
    -- Input: Nome
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "Nome do Emoji"
    nameLabel.TextColor3 = CONFIG.COLORS.TEXT_SECONDARY
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.Parent = container
    
    local nameInputBg = Instance.new("Frame")
    nameInputBg.Size = UDim2.new(1, 0, 0, 40)
    nameInputBg.BackgroundColor3 = CONFIG.COLORS.INPUT
    nameInputBg.BorderColor3 = CONFIG.COLORS.BORDER
    nameInputBg.BorderSizePixel = 1
    nameInputBg.Parent = container
    
    local nameInputCorner = Instance.new("UICorner")
    nameInputCorner.CornerRadius = UDim.new(0, 6)
    nameInputCorner.Parent = nameInputBg
    
    local nameInput = Instance.new("TextBox")
    nameInput.Size = UDim2.new(1, 0, 1, 0)
    nameInput.BackgroundTransparency = 1
    nameInput.BorderSizePixel = 0
    nameInput.PlaceholderText = "Ex: smile, love, custom"
    nameInput.PlaceholderColor3 = CONFIG.COLORS.TEXT_SECONDARY
    nameInput.TextColor3 = CONFIG.COLORS.TEXT_PRIMARY
    nameInput.TextSize = 13
    nameInput.Font = Enum.Font.Gotham
    nameInput.Parent = nameInputBg
    
    local nameInputPadding = Instance.new("UIPadding")
    nameInputPadding.PaddingLeft = UDim.new(0, 12)
    nameInputPadding.PaddingRight = UDim.new(0, 12)
    nameInputPadding.Parent = nameInput
    
    -- Input: URL
    local urlLabel = Instance.new("TextLabel")
    urlLabel.Size = UDim2.new(1, 0, 0, 20)
    urlLabel.BackgroundTransparency = 1
    urlLabel.Text = "URL da Imagem"
    urlLabel.TextColor3 = CONFIG.COLORS.TEXT_SECONDARY
    urlLabel.TextSize = 11
    urlLabel.Font = Enum.Font.Gotham
    urlLabel.Parent = container
    
    local urlInputBg = Instance.new("Frame")
    urlInputBg.Size = UDim2.new(1, 0, 0, 40)
    urlInputBg.BackgroundColor3 = CONFIG.COLORS.INPUT
    urlInputBg.BorderColor3 = CONFIG.COLORS.BORDER
    urlInputBg.BorderSizePixel = 1
    urlInputBg.Parent = container
    
    local urlInputCorner = Instance.new("UICorner")
    urlInputCorner.CornerRadius = UDim.new(0, 6)
    urlInputCorner.Parent = urlInputBg
    
    local urlInput = Instance.new("TextBox")
    urlInput.Size = UDim2.new(1, 0, 1, 0)
    urlInput.BackgroundTransparency = 1
    urlInput.BorderSizePixel = 0
    urlInput.PlaceholderText = "https://..."
    urlInput.PlaceholderColor3 = CONFIG.COLORS.TEXT_SECONDARY
    urlInput.TextColor3 = CONFIG.COLORS.TEXT_PRIMARY
    urlInput.TextSize = 12
    urlInput.Font = Enum.Font.Gotham
    urlInput.Parent = urlInputBg
    
    local urlInputPadding = Instance.new("UIPadding")
    urlInputPadding.PaddingLeft = UDim.new(0, 12)
    urlInputPadding.PaddingRight = UDim.new(0, 12)
    urlInputPadding.Parent = urlInput
    
    -- Botões
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, 0, 0, 45)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = container
    
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    buttonLayout.Padding = UDim.new(0, 10)
    buttonLayout.Parent = buttonContainer
    
    local createButton = Instance.new("TextButton")
    createButton.Size = UDim2.new(0, 150, 1, 0)
    createButton.BackgroundColor3 = CONFIG.COLORS.BLURPLE
    createButton.BorderSizePixel = 0
    createButton.Text = "✅ Criar"
    createButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    createButton.TextSize = 14
    createButton.Font = Enum.Font.GothamBold
    createButton.Parent = buttonContainer
    
    local createCorner = Instance.new("UICorner")
    createCorner.CornerRadius = UDim.new(0, 6)
    createCorner.Parent = createButton
    
    createButton.MouseButton1Click:Connect(function()
        local name = nameInput.Text:gsub("%s+", "")
        local url = urlInput.Text:gsub("%s+", "")
        
        if name == "" or url == "" then
            print("Preencha todos os campos!")
            return
        end
        
        local data = {
            name = name,
            image_url = url,
            created_by = RoDiscord.currentUser.id
        }
        
        local result = makeRequest("POST", "/api/servers/" .. RoDiscord.selectedServer .. "/emojis", data)
        
        if result then
            print("✅ Emoji criado!")
            modal:Destroy()
            loadServerEmojis()
        end
    end)
    
    local cancelButton = Instance.new("TextButton")
    cancelButton.Size = UDim2.new(0, 150, 1, 0)
    cancelButton.BackgroundColor3 = CONFIG.COLORS.INPUT
    cancelButton.BorderColor3 = CONFIG.COLORS.BORDER
    cancelButton.BorderSizePixel = 1
    cancelButton.Text = "❌ Cancelar"
    cancelButton.TextColor3 = CONFIG.COLORS.TEXT_SECONDARY
    cancelButton.TextSize = 14
    cancelButton.Font = Enum.Font.Gotham
    cancelButton.Parent = buttonContainer
    
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 6)
    cancelCorner.Parent = cancelButton
    
    cancelButton.MouseButton1Click:Connect(function()
        modal:Destroy()
    end)
end

local function showAddStickerModal()
    -- Similar ao addEmojiModal, mas para stickers
    print("Modal de adicionar sticker - implementar similar ao emoji")
end

-- ============================================
-- FUNÇÕES DE CARREGAMENTO DE DADOS
-- ============================================

local function loadServerEmojis()
    if not RoDiscord.selectedServer then return end
    
    local result = makeRequest("GET", "/api/servers/" .. RoDiscord.selectedServer .. "/emojis")
    
    if result then
        RoDiscord.customEmojis = result
    end
end

local function loadServerStickers()
    if not RoDiscord.selectedServer then return end
    
    local result = makeRequest("GET", "/api/servers/" .. RoDiscord.selectedServer .. "/stickers")
    
    if result then
        RoDiscord.stickers = result
    end
end

local function loadServerSettings()
    if not RoDiscord.selectedServer then return end
    
    local result = makeRequest("GET", "/api/servers/" .. RoDiscord.selectedServer .. "/settings")
    
    if result then
        RoDiscord.serverSettings = result
    end
end

-- ============================================
-- INICIALIZAR UI PRINCIPAL
-- ============================================

function initializeMainUI()
    if RoDiscord.mainGui then
        RoDiscord.mainGui:Destroy()
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "RoDiscordMain"
    gui.ResetOnSpawn = false
    gui.ZIndex = 1000
    
    local guiParent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    gui.Parent = guiParent
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = CONFIG.COLORS.BACKGROUND
    bg.BorderSizePixel = 0
    bg.Parent = gui
    
    RoDiscord.mainFrame = bg
    RoDiscord.mainGui = gui
    
    -- Criar sidebar
    createSidebar(bg)
    
    -- Criar panel de canais
    createChannelList(bg)
    
    -- Criar area de mensagens
    createMessageArea(bg)
    
    -- Criar painel de configurações
    local settingsPanel = createSettingsPanel(bg)
    RoDiscord.settingsPanel = settingsPanel
    
    -- Carregar dados iniciais
    loadServerSettings()
    loadServerEmojis()
    loadServerStickers()
    
    -- Polling
    task.spawn(function()
        while RoDiscord.mainGui and RoDiscord.mainGui.Parent do
            if RoDiscord.selectedChannel then
                updateMainContent()
            end
            task.wait(CONFIG.MESSAGE_FETCH_INTERVAL)
        end
    end)
end

-- Função para criar sidebar (simplificada - expandir com seu código anterior)
local function createSidebar(parent)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, CONFIG.SIDEBAR_WIDTH, 1, 0)
    sidebar.BackgroundColor3 = CONFIG.COLORS.SIDEBAR
    sidebar.BorderSizePixel = 0
    sidebar.Parent = parent
    
    -- Botão de configurações
    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Name = "SettingsButton"
    settingsBtn.Size = UDim2.new(0, 40, 0, 40)
    settingsBtn.Position = UDim2.new(1, -50, 0, 10)
    settingsBtn.BackgroundColor3 = CONFIG.COLORS.INPUT
    settingsBtn.BorderColor3 = CONFIG.COLORS.BORDER
    settingsBtn.BorderSizePixel = 1
    settingsBtn.Text = "⚙️"
    settingsBtn.TextSize = 20
    settingsBtn.Font = Enum.Font.Gotham
    settingsBtn.Parent = sidebar
    
    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 6)
    settingsCorner.Parent = settingsBtn
    
    settingsBtn.MouseButton1Click:Connect(function()
        RoDiscord.showSettings = not RoDiscord.showSettings
        RoDiscord.settingsPanel.Visible = RoDiscord.showSettings
    end)
    
    print("✅ Sidebar criada com botão de configurações")
end

-- Funções placeholder (expandir com código anterior)
local function createChannelList(parent)
    print("📋 Canal list criado")
end

local function createMessageArea(parent)
    print("💬 Message area criada")
end

local function updateMainContent()
    print("Atualizando conteúdo...")
end

-- ============================================
-- INICIAR APLICAÇÃO
-- ============================================

task.spawn(function()
    wait(1)
    showAuthScreen()
end)
