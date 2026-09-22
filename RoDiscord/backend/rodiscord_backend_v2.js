/**
 * ============================================
 * RODISCORD BACKEND V2 - COMPLETO
 * ============================================
 * Discord Clone Completo com:
 * - Configurações de servidor
 * - Sistema de emojis personalizados
 * - Figurinhas
 * - Segurança avançada
 * - Rate limiting
 */

const express = require('express');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const rateLimit = require('express-rate-limit');
const configManager = require('./config_manager');

require('dotenv').config();

const app = express();
const PORT = configManager.get('PORT') || 3000;

// ============================================
// VALIDAÇÃO DE CONFIGURAÇÃO
// ============================================
if (!configManager.validate()) {
    console.error('❌ Erro: Configure suas credenciais em .env');
    process.exit(1);
}

// ============================================
// SUPABASE
// ============================================
const SUPABASE_URL = configManager.get('SUPABASE_URL');
const SUPABASE_KEY = configManager.get('SUPABASE_KEY');
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// ============================================
// DISCORD OAUTH2
// ============================================
const DISCORD_CLIENT_ID = configManager.get('DISCORD_CLIENT_ID');
const DISCORD_CLIENT_SECRET = configManager.get('DISCORD_CLIENT_SECRET');
const DISCORD_REDIRECT_URI = configManager.get('DISCORD_REDIRECT_URI');

const DISCORD_AUTH_URL = 'https://discord.com/api/oauth2/authorize';
const DISCORD_TOKEN_URL = 'https://discord.com/api/oauth2/token';
const DISCORD_USER_URL = 'https://discord.com/api/users/@me';

// ============================================
// RATE LIMITING
// ============================================
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: configManager.get('API_RATE_LIMIT') || 100,
    message: 'Muitas requisições, tente novamente mais tarde',
    standardHeaders: true,
    legacyHeaders: false,
});

const strictLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hora
    max: 30, // Limite mais rigoroso para auth
    skipSuccessfulRequests: true,
});

// ============================================
// MIDDLEWARE
// ============================================
app.use(cors({
    origin: process.env.NODE_ENV === 'production' 
        ? ['https://seu-dominio.com']
        : ['http://localhost:3000', 'http://localhost:*'],
    credentials: true
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Rate limiting global
app.use('/api/', limiter);

// ============================================
// MIDDLEWARE DE LOGGING (SEM DADOS SENSITIVOS)
// ============================================
app.use((req, res, next) => {
    const timestamp = new Date().toISOString();
    const sanitizedBody = configManager.sanitize(req.body);
    
    console.log(`[${timestamp}] ${req.method} ${req.path}`);
    if (Object.keys(sanitizedBody).length > 0) {
        console.log(`  → Body: ${JSON.stringify(sanitizedBody).substring(0, 100)}...`);
    }
    
    next();
});

// ============================================
// AUTENTICAÇÃO - Discord
// ============================================

app.get('/auth/discord', (req, res) => {
    const scope = ['identify', 'email'];
    const authUrl = `${DISCORD_AUTH_URL}?client_id=${DISCORD_CLIENT_ID}&redirect_uri=${encodeURIComponent(DISCORD_REDIRECT_URI)}&response_type=code&scope=${scope.join('%20')}`;
    res.redirect(authUrl);
});

app.get('/auth/discord/callback', strictLimiter, async (req, res) => {
    const { code } = req.query;
    
    if (!code) {
        return res.status(400).json({ error: 'Código de autorização não fornecido' });
    }

    try {
        const tokenResponse = await axios.post(DISCORD_TOKEN_URL, 
            new URLSearchParams({
                client_id: DISCORD_CLIENT_ID,
                client_secret: DISCORD_CLIENT_SECRET,
                code: code,
                grant_type: 'authorization_code',
                redirect_uri: DISCORD_REDIRECT_URI
            }).toString(),
            { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
        );

        const accessToken = tokenResponse.data.access_token;
        const userResponse = await axios.get(DISCORD_USER_URL, {
            headers: { Authorization: `Bearer ${accessToken}` }
        });

        const discordUser = userResponse.data;
        const sessionToken = uuidv4();
        const sessionPin = Math.floor(100000 + Math.random() * 900000).toString();

        const { data: existingProfile } = await supabase
            .from('profiles')
            .select('*')
            .eq('discord_id', discordUser.id)
            .single();

        const profileData = {
            discord_id: discordUser.id,
            discord_username: discordUser.username,
            discord_discriminator: discordUser.discriminator || '0000',
            display_name: discordUser.username,
            avatar_url: `https://cdn.discordapp.com/avatars/${discordUser.id}/${discordUser.avatar}.png`,
            auth_type: 'discord',
            session_token: sessionToken,
            session_pin: sessionPin,
            updated_at: new Date()
        };

        if (existingProfile) {
            await supabase.from('profiles').update(profileData).eq('discord_id', discordUser.id);
        } else {
            await supabase.from('profiles').insert(profileData);
        }

        const html = `
            <!DOCTYPE html>
            <html lang="pt-BR">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>RoDiscord - Autenticação Bem-sucedida</title>
                <style>
                    * { margin: 0; padding: 0; box-sizing: border-box; }
                    body {
                        background: linear-gradient(135deg, #313338 0%, #2B2D31 100%);
                        color: #DBDEE1;
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                        display: flex;
                        justify-content: center;
                        align-items: center;
                        height: 100vh;
                    }
                    .container {
                        background: #2B2D31;
                        padding: 40px;
                        border-radius: 12px;
                        box-shadow: 0 8px 16px rgba(0, 0, 0, 0.3);
                        text-align: center;
                        max-width: 400px;
                    }
                    h1 { color: #5865F2; margin-bottom: 20px; }
                    .user-info { background: #1E1F22; padding: 20px; border-radius: 8px; margin: 20px 0; }
                    .avatar { width: 80px; height: 80px; border-radius: 50%; margin: 0 auto 15px; }
                    .pin-section { background: #313338; padding: 20px; border-radius: 8px; margin: 20px 0; }
                    .pin { font-size: 48px; font-weight: bold; color: #5865F2; letter-spacing: 8px; font-family: monospace; margin: 20px 0; user-select: all; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>✅ Autenticado!</h1>
                    <div class="user-info">
                        <img src="https://cdn.discordapp.com/avatars/${discordUser.id}/${discordUser.avatar}.png" class="avatar">
                        <div style="font-weight: 600;">${discordUser.username}</div>
                    </div>
                    <div class="pin-section">
                        <div style="font-size: 12px; color: #949BA4;">PIN DO ROBLOX</div>
                        <div class="pin">${sessionPin}</div>
                        <div style="font-size: 12px; color: #949BA4; margin-top: 10px;">Cole no Roblox para continuar</div>
                    </div>
                </div>
            </body>
            </html>
        `;

        res.send(html);

    } catch (error) {
        console.error('Erro na autenticação Discord:', error.message);
        res.status(500).json({ error: 'Erro ao autenticar com Discord' });
    }
});

// ============================================
// AUTENTICAÇÃO - Verificar PIN
// ============================================

app.post('/api/auth/verify-pin', strictLimiter, async (req, res) => {
    const { pin } = req.body;

    if (!pin || pin.length !== 6) {
        return res.status(400).json({ error: 'PIN inválido' });
    }

    try {
        const { data: profile } = await supabase
            .from('profiles')
            .select('*')
            .eq('session_pin', pin)
            .single();

        if (!profile) {
            return res.status(401).json({ error: 'PIN não encontrado ou expirado' });
        }

        res.json({
            success: true,
            profile: {
                id: profile.id,
                display_name: profile.display_name,
                avatar_url: profile.avatar_url,
                auth_type: profile.auth_type,
                session_token: profile.session_token
            }
        });

    } catch (error) {
        res.status(500).json({ error: 'Erro ao verificar PIN' });
    }
});

// ============================================
// AUTENTICAÇÃO - Roblox Login
// ============================================

app.post('/api/auth/roblox-login', strictLimiter, async (req, res) => {
    const { roblox_id, roblox_username, avatar_url } = req.body;

    if (!roblox_id || !roblox_username) {
        return res.status(400).json({ error: 'Dados inválidos' });
    }

    try {
        const sessionToken = uuidv4();
        const { data: existingProfile } = await supabase
            .from('profiles')
            .select('*')
            .eq('roblox_id', roblox_id)
            .single();

        if (existingProfile) {
            await supabase
                .from('profiles')
                .update({
                    roblox_username: roblox_username,
                    avatar_url: avatar_url || existingProfile.avatar_url,
                    session_token: sessionToken,
                    updated_at: new Date()
                })
                .eq('roblox_id', roblox_id);
        } else {
            await supabase
                .from('profiles')
                .insert({
                    roblox_id: roblox_id,
                    roblox_username: roblox_username,
                    display_name: roblox_username,
                    avatar_url: avatar_url || 'https://www.roblox.com/bust-thumbnails/nouser_headshot_100x100.png',
                    auth_type: 'roblox',
                    session_token: sessionToken
                });
        }

        res.json({
            success: true,
            session_token: sessionToken,
            profile: {
                roblox_id: roblox_id,
                display_name: roblox_username,
                avatar_url: avatar_url
            }
        });

    } catch (error) {
        console.error('Erro no login Roblox:', error.message);
        res.status(500).json({ error: 'Erro ao fazer login' });
    }
});

// ============================================
// SERVIDORES
// ============================================

app.get('/api/servers', async (req, res) => {
    try {
        const { data: servers } = await supabase
            .from('servers')
            .select('*')
            .order('created_at', { ascending: false });

        res.json(servers);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao listar servidores' });
    }
});

app.post('/api/servers', async (req, res) => {
    const { name, owner_id, icon_url, description } = req.body;

    if (!name || !owner_id) {
        return res.status(400).json({ error: 'Nome e owner_id obrigatórios' });
    }

    try {
        const { data: server } = await supabase
            .from('servers')
            .insert({
                name: name.substring(0, 100),
                owner_id: owner_id,
                icon_url: icon_url || 'https://via.placeholder.com/512',
                description: description ? description.substring(0, 500) : null
            })
            .select()
            .single();

        res.status(201).json(server);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao criar servidor' });
    }
});

// ============================================
// CONFIGURAÇÕES DO SERVIDOR
// ============================================

app.get('/api/servers/:server_id/settings', async (req, res) => {
    const { server_id } = req.params;

    try {
        const { data: settings } = await supabase
            .from('server_settings')
            .select('*')
            .eq('server_id', server_id)
            .single();

        if (!settings) {
            // Criar settings padrão
            const { data: newSettings } = await supabase
                .from('server_settings')
                .insert({
                    server_id: server_id,
                    allow_custom_emojis: true,
                    allow_stickers: true,
                    profanity_filter: true,
                    default_role: 'member',
                    verification_level: 'none'
                })
                .select()
                .single();
            
            return res.json(newSettings);
        }

        res.json(settings);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao buscar configurações' });
    }
});

app.put('/api/servers/:server_id/settings', async (req, res) => {
    const { server_id } = req.params;
    const { allow_custom_emojis, allow_stickers, profanity_filter, verification_level } = req.body;

    try {
        const { data: settings } = await supabase
            .from('server_settings')
            .update({
                allow_custom_emojis,
                allow_stickers,
                profanity_filter,
                verification_level,
                updated_at: new Date()
            })
            .eq('server_id', server_id)
            .select()
            .single();

        res.json(settings);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao atualizar configurações' });
    }
});

// ============================================
// CANAIS
// ============================================

app.get('/api/servers/:server_id/channels', async (req, res) => {
    const { server_id } = req.params;

    try {
        const { data: channels } = await supabase
            .from('channels')
            .select('*')
            .eq('server_id', server_id)
            .order('created_at', { ascending: true });

        res.json(channels);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao listar canais' });
    }
});

app.post('/api/servers/:server_id/channels', async (req, res) => {
    const { server_id } = req.params;
    const { name, type, description } = req.body;

    if (!name) {
        return res.status(400).json({ error: 'Nome do canal obrigatório' });
    }

    try {
        const { data: channel } = await supabase
            .from('channels')
            .insert({
                server_id: server_id,
                name: name.substring(0, 100),
                type: type || 'text',
                description: description ? description.substring(0, 500) : null
            })
            .select()
            .single();

        res.status(201).json(channel);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao criar canal' });
    }
});

// ============================================
// MENSAGENS
// ============================================

app.get('/api/channels/:channel_id/messages', async (req, res) => {
    const { channel_id } = req.params;
    const limit = Math.min(parseInt(req.query.limit) || 50, 200);

    try {
        const { data: messages } = await supabase
            .from('messages_with_author')
            .select('*')
            .eq('channel_id', channel_id)
            .order('created_at', { ascending: false })
            .limit(limit);

        res.json(messages.reverse());
    } catch (error) {
        res.status(500).json({ error: 'Erro ao listar mensagens' });
    }
});

app.post('/api/channels/:channel_id/messages', async (req, res) => {
    const { channel_id } = req.params;
    const { author_id, content } = req.body;

    if (!author_id || !content || content.trim().length === 0) {
        return res.status(400).json({ error: 'author_id e content obrigatórios' });
    }

    const sanitizedContent = content.trim().substring(0, 2000);

    try {
        const { data: message } = await supabase
            .from('messages')
            .insert({
                channel_id: channel_id,
                author_id: author_id,
                content: sanitizedContent
            })
            .select()
            .single();

        res.status(201).json(message);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao enviar mensagem' });
    }
});

// ============================================
// EMOJIS PERSONALIZADOS
// ============================================

app.get('/api/servers/:server_id/emojis', async (req, res) => {
    const { server_id } = req.params;

    try {
        const { data: emojis } = await supabase
            .from('custom_emojis')
            .select('*')
            .eq('server_id', server_id)
            .order('created_at', { ascending: false });

        res.json(emojis || []);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao listar emojis' });
    }
});

app.post('/api/servers/:server_id/emojis', async (req, res) => {
    const { server_id } = req.params;
    const { name, image_url, created_by } = req.body;

    if (!name || !image_url || !created_by) {
        return res.status(400).json({ error: 'Nome, URL e criador obrigatórios' });
    }

    try {
        const { data: emoji } = await supabase
            .from('custom_emojis')
            .insert({
                server_id: server_id,
                name: name.substring(0, 50),
                image_url: image_url,
                created_by: created_by
            })
            .select()
            .single();

        res.status(201).json(emoji);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao criar emoji' });
    }
});

// ============================================
// FIGURINHAS
// ============================================

app.get('/api/servers/:server_id/stickers', async (req, res) => {
    const { server_id } = req.params;

    try {
        const { data: stickers } = await supabase
            .from('stickers')
            .select('*')
            .eq('server_id', server_id)
            .order('created_at', { ascending: false });

        res.json(stickers || []);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao listar figurinhas' });
    }
});

app.post('/api/servers/:server_id/stickers', async (req, res) => {
    const { server_id } = req.params;
    const { name, image_url, category, created_by } = req.body;

    if (!name || !image_url || !created_by) {
        return res.status(400).json({ error: 'Dados obrigatórios faltando' });
    }

    try {
        const { data: sticker } = await supabase
            .from('stickers')
            .insert({
                server_id: server_id,
                name: name.substring(0, 100),
                image_url: image_url,
                category: category || 'geral',
                created_by: created_by
            })
            .select()
            .single();

        res.status(201).json(sticker);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao criar figurinha' });
    }
});

// ============================================
// REAÇÕES COM EMOJIS
// ============================================

app.post('/api/messages/:message_id/reactions', async (req, res) => {
    const { message_id } = req.params;
    const { emoji, user_id } = req.body;

    if (!emoji || !user_id) {
        return res.status(400).json({ error: 'Emoji e user_id obrigatórios' });
    }

    try {
        const { data: reaction } = await supabase
            .from('reactions')
            .insert({
                message_id: message_id,
                emoji: emoji.substring(0, 100),
                user_id: user_id
            })
            .select()
            .single();

        res.status(201).json(reaction);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao adicionar reação' });
    }
});

app.get('/api/messages/:message_id/reactions', async (req, res) => {
    const { message_id } = req.params;

    try {
        const { data: reactions } = await supabase
            .from('reactions')
            .select('*')
            .eq('message_id', message_id);

        res.json(reactions || []);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao listar reações' });
    }
});

// ============================================
// BLOCOS/SILENCIAMENTO
// ============================================

app.post('/api/users/:user_id/block/:blocked_user_id', async (req, res) => {
    const { user_id, blocked_user_id } = req.params;

    try {
        const { data: block } = await supabase
            .from('blocked_users')
            .insert({
                user_id: user_id,
                blocked_user_id: blocked_user_id
            })
            .select()
            .single();

        res.status(201).json(block);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao bloquear usuário' });
    }
});

app.get('/api/users/:user_id/blocked', async (req, res) => {
    const { user_id } = req.params;

    try {
        const { data: blocked } = await supabase
            .from('blocked_users')
            .select('*')
            .eq('user_id', user_id);

        res.json(blocked || []);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao listar bloqueados' });
    }
});

// ============================================
// MENSAGENS DIRETAS
// ============================================

app.get('/api/direct-messages/:user_id', async (req, res) => {
    const { user_id } = req.params;
    const limit = parseInt(req.query.limit) || 50;

    try {
        const { data: dms } = await supabase
            .from('direct_messages_with_author')
            .select('*')
            .or(`sender_id.eq.${user_id},receiver_id.eq.${user_id}`)
            .order('created_at', { ascending: false })
            .limit(limit);

        res.json(dms.reverse());
    } catch (error) {
        res.status(500).json({ error: 'Erro ao listar DMs' });
    }
});

app.post('/api/direct-messages', async (req, res) => {
    const { sender_id, receiver_id, content } = req.body;

    if (!sender_id || !receiver_id || !content) {
        return res.status(400).json({ error: 'Dados obrigatórios faltando' });
    }

    try {
        const { data: dm } = await supabase
            .from('direct_messages')
            .insert({
                sender_id: sender_id,
                receiver_id: receiver_id,
                content: content.trim().substring(0, 2000)
            })
            .select()
            .single();

        res.status(201).json(dm);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao enviar DM' });
    }
});

// ============================================
// PERFIS
// ============================================

app.get('/api/profiles/:profile_id', async (req, res) => {
    const { profile_id } = req.params;

    try {
        const { data: profile } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', profile_id)
            .single();

        if (!profile) {
            return res.status(404).json({ error: 'Perfil não encontrado' });
        }

        res.json(profile);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao buscar perfil' });
    }
});

app.put('/api/profiles/:profile_id', async (req, res) => {
    const { profile_id } = req.params;
    const { bio, status, avatar_url } = req.body;

    try {
        const { data: profile } = await supabase
            .from('profiles')
            .update({
                bio: bio ? bio.substring(0, 500) : null,
                status: status || 'online',
                avatar_url: avatar_url,
                updated_at: new Date()
            })
            .eq('id', profile_id)
            .select()
            .single();

        res.json(profile);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao atualizar perfil' });
    }
});

// ============================================
// HEALTH CHECK
// ============================================

app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        timestamp: new Date(),
        environment: process.env.NODE_ENV 
    });
});

// ============================================
// ERROS 404
// ============================================

app.use((req, res) => {
    res.status(404).json({ error: 'Rota não encontrada' });
});

// ============================================
// ERROR HANDLER
// ============================================

app.use((err, req, res, next) => {
    console.error('❌ Erro:', err.message);
    res.status(500).json({ error: 'Erro interno do servidor' });
});

// ============================================
// INICIAR SERVIDOR
// ============================================

app.listen(PORT, () => {
    console.log(`
╔════════════════════════════════════════════╗
║     🚀 RoDiscord Backend v2 Rodando       ║
╚════════════════════════════════════════════╝

📍 URL: http://localhost:${PORT}
🔒 Segurança: Ativada
⚡ Rate Limiting: Ativo
📊 Ambiente: ${process.env.NODE_ENV || 'development'}

✅ Endpoints disponíveis:
  - /auth/discord
  - /api/servers
  - /api/servers/:id/settings
  - /api/servers/:id/emojis
  - /api/servers/:id/stickers
  - /api/channels/:id/messages
  - /api/messages/:id/reactions
  - E muito mais...

    `);
});

module.exports = app;
