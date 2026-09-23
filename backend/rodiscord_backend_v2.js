// ============================================
// 🔥 RoDiscord Backend v2 - COMPLETO
// ============================================
// Todos os endpoints funcionando
// Login dual, servidores, canais, mensagens, DMs
// ============================================

const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// ============================================
// SUPABASE
// ============================================

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_KEY
);

// ============================================
// AUTH ENDPOINTS
// ============================================

// Login Roblox
app.post('/api/auth/roblox-login', async (req, res) => {
    try {
        const { roblox_id, roblox_username, avatar_url } = req.body;

        // Verificar se user existe
        let { data: profile, error: fetchError } = await supabase
            .from('profiles')
            .select('*')
            .eq('roblox_id', roblox_id)
            .single();

        if (fetchError && fetchError.code !== 'PGRST116') {
            return res.status(500).json({ error: fetchError.message });
        }

        // Se não existe, criar
        if (!profile) {
            const { data: newProfile, error: createError } = await supabase
                .from('profiles')
                .insert([{
                    roblox_id,
                    roblox_username,
                    avatar_url,
                    status: 'online',
                    created_at: new Date()
                }])
                .select()
                .single();

            if (createError) {
                return res.status(500).json({ error: createError.message });
            }

            profile = newProfile;
        } else {
            // Atualizar status
            await supabase
                .from('profiles')
                .update({ status: 'online', last_seen: new Date() })
                .eq('id', profile.id);
        }

        const sessionToken = Math.random().toString(36).substring(2);

        res.json({
            success: true,
            session_token: sessionToken,
            profile: {
                id: profile.id,
                roblox_id: profile.roblox_id,
                roblox_username: profile.roblox_username,
                discord_id: profile.discord_id,
                discord_username: profile.discord_username,
                avatar_url: profile.avatar_url,
                status: 'online'
            }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Login Discord
app.post('/api/auth/discord-login', async (req, res) => {
    try {
        const { discord_id, discord_username, discord_email, avatar_url } = req.body;

        let { data: profile, error: fetchError } = await supabase
            .from('profiles')
            .select('*')
            .eq('discord_id', discord_id)
            .single();

        if (fetchError && fetchError.code !== 'PGRST116') {
            return res.status(500).json({ error: fetchError.message });
        }

        if (!profile) {
            const { data: newProfile, error: createError } = await supabase
                .from('profiles')
                .insert([{
                    discord_id,
                    discord_username,
                    discord_email,
                    avatar_url,
                    status: 'online',
                    created_at: new Date()
                }])
                .select()
                .single();

            if (createError) {
                return res.status(500).json({ error: createError.message });
            }

            profile = newProfile;
        } else {
            await supabase
                .from('profiles')
                .update({ status: 'online', last_seen: new Date() })
                .eq('id', profile.id);
        }

        const sessionToken = Math.random().toString(36).substring(2);

        res.json({
            success: true,
            session_token: sessionToken,
            profile: {
                id: profile.id,
                roblox_id: profile.roblox_id,
                roblox_username: profile.roblox_username,
                discord_id: profile.discord_id,
                discord_username: profile.discord_username,
                avatar_url: profile.avatar_url,
                status: 'online'
            }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Linkar Discord a Roblox
app.post('/api/auth/link-discord', async (req, res) => {
    try {
        const { profile_id, discord_id, discord_username, discord_email, avatar_url } = req.body;

        const { data, error } = await supabase
            .from('profiles')
            .update({
                discord_id,
                discord_username,
                discord_email,
                avatar_url
            })
            .eq('id', profile_id)
            .select()
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true, profile: data });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Linkar Roblox a Discord
app.post('/api/auth/link-roblox', async (req, res) => {
    try {
        const { profile_id, roblox_id, roblox_username, avatar_url } = req.body;

        const { data, error } = await supabase
            .from('profiles')
            .update({
                roblox_id,
                roblox_username,
                avatar_url
            })
            .eq('id', profile_id)
            .select()
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true, profile: data });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ============================================
// SERVERS ENDPOINTS
// ============================================

// Listar servidores do usuário
app.get('/api/servers/:user_id', async (req, res) => {
    try {
        const { user_id } = req.params;

        const { data, error } = await supabase
            .from('servers')
            .select('*')
            .in('id', (
                await supabase
                    .from('server_members')
                    .select('server_id')
                    .eq('user_id', user_id)
            ).data?.map(m => m.server_id) || []);

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true, servers: data || [] });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Criar servidor
app.post('/api/servers', async (req, res) => {
    try {
        const { name, owner_id, banner_url } = req.body;

        const { data: server, error: serverError } = await supabase
            .from('servers')
            .insert([{
                name,
                owner_id,
                banner_url: banner_url || 'https://via.placeholder.com/1000x300?text=' + name,
                created_at: new Date()
            }])
            .select()
            .single();

        if (serverError) return res.status(500).json({ error: serverError.message });

        // Adicionar owner como membro
        await supabase
            .from('server_members')
            .insert([{
                server_id: server.id,
                user_id: owner_id,
                role: 'owner',
                joined_at: new Date()
            }]);

        res.json({ success: true, server });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ============================================
// CHANNELS ENDPOINTS
// ============================================

// Listar canais do servidor
app.get('/api/servers/:server_id/channels', async (req, res) => {
    try {
        const { server_id } = req.params;

        const { data, error } = await supabase
            .from('channels')
            .select('*')
            .eq('server_id', server_id)
            .order('position', { ascending: true });

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true, channels: data || [] });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Criar canal
app.post('/api/channels', async (req, res) => {
    try {
        const { server_id, name, type, is_private, description } = req.body;

        const { data, error } = await supabase
            .from('channels')
            .insert([{
                server_id,
                name,
                type, // 'text' ou 'voice'
                is_private: is_private || false,
                description: description || '',
                created_at: new Date()
            }])
            .select()
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true, channel: data });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ============================================
// MESSAGES ENDPOINTS
// ============================================

// Listar mensagens do canal
app.get('/api/channels/:channel_id/messages', async (req, res) => {
    try {
        const { channel_id } = req.params;
        const limit = req.query.limit || 50;

        const { data, error } = await supabase
            .from('messages_with_author')
            .select('*')
            .eq('channel_id', channel_id)
            .order('created_at', { ascending: false })
            .limit(limit);

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true, messages: (data || []).reverse() });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Enviar mensagem
app.post('/api/messages', async (req, res) => {
    try {
        const { channel_id, user_id, content } = req.body;

        const { data, error } = await supabase
            .from('messages')
            .insert([{
                channel_id,
                user_id,
                content,
                created_at: new Date()
            }])
            .select()
            .single();

        if (error) return res.status(500).json({ error: error.message });

        // Buscar com autor
        const { data: messageWithAuthor } = await supabase
            .from('messages_with_author')
            .select('*')
            .eq('id', data.id)
            .single();

        res.json({ success: true, message: messageWithAuthor });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Editar mensagem
app.put('/api/messages/:message_id', async (req, res) => {
    try {
        const { message_id } = req.params;
        const { content } = req.body;

        const { data, error } = await supabase
            .from('messages')
            .update({ content, edited_at: new Date() })
            .eq('id', message_id)
            .select()
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true, message: data });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Deletar mensagem
app.delete('/api/messages/:message_id', async (req, res) => {
    try {
        const { message_id } = req.params;

        const { error } = await supabase
            .from('messages')
            .delete()
            .eq('id', message_id);

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ============================================
// REACTIONS ENDPOINTS
// ============================================

// Adicionar reação
app.post('/api/reactions', async (req, res) => {
    try {
        const { message_id, user_id, emoji } = req.body;

        const { data, error } = await supabase
            .from('reactions')
            .insert([{
                message_id,
                user_id,
                emoji,
                created_at: new Date()
            }])
            .select()
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true, reaction: data });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Remover reação
app.delete('/api/reactions/:reaction_id', async (req, res) => {
    try {
        const { reaction_id } = req.params;

        const { error } = await supabase
            .from('reactions')
            .delete()
            .eq('id', reaction_id);

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ============================================
// DIRECT MESSAGES ENDPOINTS
// ============================================

// Listar DMs
app.get('/api/dms/:user_id', async (req, res) => {
    try {
        const { user_id } = req.params;

        const { data, error } = await supabase
            .from('direct_messages_with_author')
            .select('*')
            .or(`sender_id.eq.${user_id},recipient_id.eq.${user_id}`)
            .order('created_at', { ascending: false });

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true, messages: data || [] });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Enviar DM
app.post('/api/dms', async (req, res) => {
    try {
        const { sender_id, recipient_id, content } = req.body;

        const { data, error } = await supabase
            .from('direct_messages')
            .insert([{
                sender_id,
                recipient_id,
                content,
                created_at: new Date()
            }])
            .select()
            .single();

        if (error) return res.status(500).json({ error: error.message });

        const { data: dmWithAuthor } = await supabase
            .from('direct_messages_with_author')
            .select('*')
            .eq('id', data.id)
            .single();

        res.json({ success: true, message: dmWithAuthor });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ============================================
// FRIENDS ENDPOINTS
// ============================================

// Listar amigos online
app.get('/api/friends/:user_id', async (req, res) => {
    try {
        const { user_id } = req.params;

        const { data, error } = await supabase
            .from('friends')
            .select('*, friend:friend_id(id, roblox_username, discord_username, avatar_url, status)')
            .eq('user_id', user_id);

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true, friends: data || [] });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Adicionar amigo
app.post('/api/friends', async (req, res) => {
    try {
        const { user_id, friend_id } = req.body;

        const { data, error } = await supabase
            .from('friends')
            .insert([{
                user_id,
                friend_id,
                created_at: new Date()
            }])
            .select()
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true, friend: data });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Remover amigo
app.delete('/api/friends/:friend_id', async (req, res) => {
    try {
        const { friend_id } = req.params;

        const { error } = await supabase
            .from('friends')
            .delete()
            .eq('id', friend_id);

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ============================================
// PROFILES ENDPOINTS
// ============================================

// Buscar perfil
app.get('/api/profiles/:user_id', async (req, res) => {
    try {
        const { user_id } = req.params;

        const { data, error } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', user_id)
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true, profile: data });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Atualizar perfil
app.put('/api/profiles/:user_id', async (req, res) => {
    try {
        const { user_id } = req.params;
        const { status, bio } = req.body;

        const { data, error } = await supabase
            .from('profiles')
            .update({ status, bio, updated_at: new Date() })
            .eq('id', user_id)
            .select()
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.json({ success: true, profile: data });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ============================================
// START SERVER
// ============================================

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`✅ RoDiscord Backend v2 rodando em porta ${PORT}`);
    console.log(`📝 Stack: Node.js + Express + Supabase`);
    console.log(`🌐 URL: https://rodiscord.onrender.com`);
});
