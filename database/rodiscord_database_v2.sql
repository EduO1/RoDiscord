-- ============================================
-- RODISCORD v2 - DATABASE SCHEMA (CORRIGIDO)
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLE: profiles (Usuários do Sistema)
-- ============================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    roblox_id BIGINT UNIQUE,
    discord_id BIGINT UNIQUE,
    roblox_username VARCHAR(255),
    discord_username VARCHAR(255),
    discord_discriminator VARCHAR(10),
    display_name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    banner_url TEXT,
    bio TEXT,
    status VARCHAR(20) DEFAULT 'online' CHECK (status IN ('online', 'away', 'dnd', 'offline')),
    auth_type VARCHAR(20) CHECK (auth_type IN ('roblox', 'discord')),
    session_token UUID UNIQUE,
    session_pin VARCHAR(6) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_profiles_roblox_id ON profiles(roblox_id);
CREATE INDEX idx_profiles_discord_id ON profiles(discord_id);
CREATE INDEX idx_profiles_session_token ON profiles(session_token);
CREATE INDEX idx_profiles_session_pin ON profiles(session_pin);

-- ============================================
-- TABLE: servers (Servidores/Comunidades)
-- ============================================
CREATE TABLE IF NOT EXISTS servers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    icon_url TEXT,
    banner_url TEXT,
    owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_servers_owner_id ON servers(owner_id);

-- ============================================
-- TABLE: server_settings (Configurações do Servidor)
-- ============================================
CREATE TABLE IF NOT EXISTS server_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    server_id UUID NOT NULL UNIQUE REFERENCES servers(id) ON DELETE CASCADE,
    allow_custom_emojis BOOLEAN DEFAULT TRUE,
    allow_stickers BOOLEAN DEFAULT TRUE,
    profanity_filter BOOLEAN DEFAULT FALSE,
    verification_level VARCHAR(20) DEFAULT 'none' CHECK (verification_level IN ('none', 'low', 'medium', 'high')),
    default_role VARCHAR(100) DEFAULT 'member',
    max_members INTEGER DEFAULT 999999,
    language VARCHAR(10) DEFAULT 'pt-BR',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_server_settings_server_id ON server_settings(server_id);

-- ============================================
-- TABLE: server_members (Membros do Servidor)
-- ============================================
CREATE TABLE IF NOT EXISTS server_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    server_id UUID NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role VARCHAR(100) DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(server_id, profile_id)
);

CREATE INDEX idx_server_members_server_id ON server_members(server_id);
CREATE INDEX idx_server_members_profile_id ON server_members(profile_id);

-- ============================================
-- TABLE: channels (Canais do Servidor)
-- ============================================
CREATE TABLE IF NOT EXISTS channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    server_id UUID NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(20) CHECK (type IN ('text', 'voice', 'announcement')) DEFAULT 'text',
    description TEXT,
    position INTEGER DEFAULT 0,
    is_nsfw BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_channels_server_id ON channels(server_id);

-- ============================================
-- TABLE: messages (Mensagens do Canal)
-- ============================================
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    edited BOOLEAN DEFAULT FALSE,
    pinned BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_messages_channel_id ON messages(channel_id);
CREATE INDEX idx_messages_author_id ON messages(author_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);

-- ============================================
-- TABLE: direct_messages (Mensagens Privadas)
-- ============================================
CREATE TABLE IF NOT EXISTS direct_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_direct_messages_sender_id ON direct_messages(sender_id);
CREATE INDEX idx_direct_messages_receiver_id ON direct_messages(receiver_id);
CREATE INDEX idx_direct_messages_created_at ON direct_messages(created_at DESC);

-- ============================================
-- TABLE: custom_emojis (Emojis Personalizados)
-- ============================================
CREATE TABLE IF NOT EXISTS custom_emojis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    server_id UUID NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    image_url TEXT NOT NULL,
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(server_id, name)
);

CREATE INDEX idx_custom_emojis_server_id ON custom_emojis(server_id);
CREATE INDEX idx_custom_emojis_created_by ON custom_emojis(created_by);

-- ============================================
-- TABLE: stickers (Figurinhas)
-- ============================================
CREATE TABLE IF NOT EXISTS stickers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    server_id UUID NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    image_url TEXT NOT NULL,
    category VARCHAR(100) DEFAULT 'geral',
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(server_id, name)
);

CREATE INDEX idx_stickers_server_id ON stickers(server_id);
CREATE INDEX idx_stickers_category ON stickers(category);
CREATE INDEX idx_stickers_created_by ON stickers(created_by);

-- ============================================
-- TABLE: reactions (Reações com Emojis)
-- ============================================
CREATE TABLE IF NOT EXISTS reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    emoji VARCHAR(500) NOT NULL,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(message_id, emoji, user_id)
);

CREATE INDEX idx_reactions_message_id ON reactions(message_id);
CREATE INDEX idx_reactions_user_id ON reactions(user_id);

-- ============================================
-- TABLE: blocked_users (Usuários Bloqueados)
-- ============================================
CREATE TABLE IF NOT EXISTS blocked_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    blocked_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, blocked_user_id),
    CHECK (user_id != blocked_user_id)
);

CREATE INDEX idx_blocked_users_user_id ON blocked_users(user_id);
CREATE INDEX idx_blocked_users_blocked_user_id ON blocked_users(blocked_user_id);

-- ============================================
-- TABLE: friends (Amigos)
-- ============================================
CREATE TABLE IF NOT EXISTS friends (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status VARCHAR(20) CHECK (status IN ('pending', 'accepted', 'blocked')) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, friend_id),
    CHECK (user_id != friend_id)
);

CREATE INDEX idx_friends_user_id ON friends(user_id);
CREATE INDEX idx_friends_friend_id ON friends(friend_id);

-- ============================================
-- TABLE: invites (Convites de Servidor)
-- ============================================
CREATE TABLE IF NOT EXISTS invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(20) UNIQUE NOT NULL,
    server_id UUID NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    uses INTEGER DEFAULT 0,
    max_uses INTEGER DEFAULT NULL,
    expires_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_invites_server_id ON invites(server_id);
CREATE INDEX idx_invites_code ON invites(code);
CREATE INDEX idx_invites_expires_at ON invites(expires_at);

-- ============================================
-- TABLE: message_attachments (Anexos de Mensagem)
-- ============================================
CREATE TABLE IF NOT EXISTS message_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    filename VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_size INTEGER,
    file_type VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_message_attachments_message_id ON message_attachments(message_id);

-- ============================================
-- TABLE: audit_logs (Logs de Auditoria)
-- ============================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    server_id UUID REFERENCES servers(id) ON DELETE CASCADE,
    action_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    action_type VARCHAR(100) NOT NULL,
    target_id UUID,
    details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_server_id ON audit_logs(server_id);
CREATE INDEX idx_audit_logs_action_by ON audit_logs(action_by);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- ============================================
-- VIEWS ÚTEIS
-- ============================================

-- View: Mensagens com dados do autor
CREATE OR REPLACE VIEW messages_with_author AS
SELECT 
    m.id,
    m.channel_id,
    m.content,
    m.created_at,
    m.updated_at,
    m.edited,
    m.pinned,
    p.id as author_id,
    p.display_name as author_name,
    p.avatar_url as author_avatar,
    p.status as author_status
FROM messages m
JOIN profiles p ON m.author_id = p.id
ORDER BY m.created_at DESC;

-- View: DMs com dados do remetente
CREATE OR REPLACE VIEW direct_messages_with_author AS
SELECT 
    dm.id,
    dm.sender_id,
    dm.receiver_id,
    dm.content,
    dm.read,
    dm.created_at,
    p.display_name as sender_name,
    p.avatar_url as sender_avatar
FROM direct_messages dm
JOIN profiles p ON dm.sender_id = p.id
ORDER BY dm.created_at DESC;

-- View: Reações agrupadas por emoji
CREATE OR REPLACE VIEW reactions_grouped AS
SELECT 
    message_id,
    emoji,
    COUNT(*) as count,
    ARRAY_AGG(user_id) as users
FROM reactions
GROUP BY message_id, emoji;

-- View: Membros do servidor com detalhes
CREATE OR REPLACE VIEW server_members_detailed AS
SELECT 
    sm.id,
    sm.server_id,
    sm.profile_id,
    sm.role,
    sm.joined_at,
    p.display_name,
    p.avatar_url,
    p.status
FROM server_members sm
JOIN profiles p ON sm.profile_id = p.id;

-- ============================================
-- DADOS DE TESTE
-- ============================================

-- Inserir usuário padrão
INSERT INTO profiles (display_name, auth_type, avatar_url)
VALUES ('Sistema RoDiscord', 'roblox', 'https://www.roblox.com/bust-thumbnails/nouser_headshot_100x100.png')
ON CONFLICT DO NOTHING;

-- Inserir servidor padrão
INSERT INTO servers (name, description, icon_url, owner_id)
SELECT 'RoDiscord Central', 'Servidor padrão para testes e documentação', 'https://via.placeholder.com/512', id
FROM profiles
WHERE display_name = 'Sistema RoDiscord'
ON CONFLICT DO NOTHING;

-- Inserir canal padrão no servidor
INSERT INTO channels (server_id, name, type, description)
SELECT id, 'geral', 'text', 'Canal geral para conversar'
FROM servers
WHERE name = 'RoDiscord Central'
ON CONFLICT DO NOTHING;

-- Inserir configurações padrão
INSERT INTO server_settings (server_id, allow_custom_emojis, allow_stickers, profanity_filter)
SELECT id, true, true, false
FROM servers
WHERE name = 'RoDiscord Central'
ON CONFLICT DO NOTHING;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE servers ENABLE ROW LEVEL SECURITY;
ALTER TABLE channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE direct_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_emojis ENABLE ROW LEVEL SECURITY;
ALTER TABLE stickers ENABLE ROW LEVEL SECURITY;
ALTER TABLE reactions ENABLE ROW LEVEL SECURITY;

-- Políticas de leitura pública (para demonstração, em produção ser mais rigoroso)
CREATE POLICY "Profiles são legíveis por todos" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Servers são legíveis por todos" ON servers
    FOR SELECT USING (true);

CREATE POLICY "Channels são legíveis por todos" ON channels
    FOR SELECT USING (true);

CREATE POLICY "Messages são legíveis por todos" ON messages
    FOR SELECT USING (true);

CREATE POLICY "Direct messages só legíveis pelo remetente/receptor" ON direct_messages
    FOR SELECT USING (sender_id = auth.uid() OR receiver_id = auth.uid());

CREATE POLICY "Custom emojis legíveis por todos" ON custom_emojis
    FOR SELECT USING (true);

CREATE POLICY "Stickers legíveis por todos" ON stickers
    FOR SELECT USING (true);

CREATE POLICY "Reactions legíveis por todos" ON reactions
    FOR SELECT USING (true);

-- ============================================
-- FUNÇÕES ÚTEIS
-- ============================================

-- Função para atualizar timestamp updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para atualizar updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_servers_updated_at BEFORE UPDATE ON servers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_channels_updated_at BEFORE UPDATE ON channels
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- TABELA PARA GUARDAR SECRETS (OPCIONAL)
-- ============================================

CREATE TABLE IF NOT EXISTS secrets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(255) UNIQUE NOT NULL,
    encrypted_value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_secrets_key ON secrets(key);

-- ============================================
-- PRONTO!
-- ============================================

-- Verificar se tudo foi criado
SELECT 
    'Tabelas criadas com sucesso!' as status,
    COUNT(*) as total_tables
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

-- Listar todas as tabelas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
