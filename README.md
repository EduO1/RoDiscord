# 🔥 RoDiscord v2 - Discord COMPLETO no Roblox

> **Discord inteiro, mas NÃO é Discord. Sem restrições de idade, sem moderação chata. Só você, seus amigos e pura diversão.**

## ✨ O QUE TEM DE NOVO (v2)

### 🎮 Recursos Completos
- ✅ **Servidores** - Crie, gerencie, customize
- ✅ **Canais** - Text, voice, announcement
- ✅ **Mensagens em Tempo Real** - Polling otimizado
- ✅ **Emojis Personalizados** - Crie emojis únicos do seu servidor
- ✅ **Figurinhas** - Upload e uso de stickers
- ✅ **Reações** - Reaja com qualquer emoji/sticker
- ✅ **Mensagens Diretas** - Chat privado 1v1
- ✅ **Perfis** - Bio, status, avatar customizável
- ✅ **Bloqueio de Usuários** - Controle de quem vê você

### ⚙️ PAINEL DE CONFIGURAÇÕES (Discord-like)
- 🖥️ **Configurações do Servidor**
  - Permitir emojis personalizados
  - Permitir figurinhas
  - Filtro de profanidade
  - Nível de verificação
  - Idioma do servidor

- 🔒 **Configurações de Segurança**
  - 2FA (planejado)
  - Logs de auditoria
  - Bloqueio em massa
  - Limitação de rate

- 😀 **Gerenciar Emojis**
  - Lista de emojis do servidor
  - Adicionar novo emoji
  - Deletar emoji
  - Visualizar uso

- 🎨 **Gerenciar Figurinhas**
  - Categorias de stickers
  - Upload de imagens
  - Organizar por categoria
  - Histórico de uso

### 🔐 SEGURANÇA MÁXIMA
- ✅ Credenciais encriptadas (AES-256)
- ✅ `.env` nunca commitado no Git
- ✅ `.secret.key` gerada automaticamente
- ✅ Código Luau pode ser obfuscado
- ✅ Rate limiting em produção
- ✅ RLS no Supabase

---

## 📦 ARQUIVOS v2

```
RoDiscord v2/
│
├── Backend
│   ├── config_manager.js              ← NOVO: Gerencia credenciais criptografadas
│   ├── rodiscord_backend_v2.js        ← Expandido com emojis, stickers, settings
│   ├── package.json
│   ├── .env                           ← Suas credenciais (nunca commitar!)
│   ├── .env.encrypted                 ← Auto-gerado (encriptado)
│   └── .secret.key                    ← Auto-gerado (nunca commitar!)
│
├── Database
│   └── rodiscord_database_v2.sql      ← CORRIGIDO: Sem erros de sintaxe
│
├── Client
│   └── rodiscord_client_v2_COMPLETO.lua  ← Completo com configurações
│
├── Segurança
│   └── SEGURANCA_OBFUSCACAO.md        ← Guia de proteção do código
│
└── Docs
    └── Este README
```

---

## 🚀 SETUP RÁPIDO (10 MINUTOS)

### 1. **Preparar Backend**

```bash
# Criar pasta
mkdir rodiscord-backend
cd rodiscord-backend

# Copiar arquivos
# config_manager.js
# rodiscord_backend_v2.js
# package.json

# Instalar dependências
npm install

# Criar arquivo .env com suas credenciais (veja seção abaixo)
# (Copiar seu SUPABASE_URL, DISCORD_CLIENT_ID, etc)

# Executar
npm run dev
# ✅ Backend rodando em http://localhost:3000
# ✅ .secret.key gerado automaticamente
# ✅ Credenciais encriptadas
```

### 2. **Preparar Supabase**

1. Ir para https://supabase.com
2. Criar novo projeto
3. Copiar URL e chave (anon)
4. No SQL Editor, rodar o arquivo `rodiscord_database_v2.sql`
5. ✅ Tudo pronto!

### 3. **Configurar Discord OAuth2**

1. https://discord.com/developers/applications
2. New Application
3. Copiar CLIENT_ID e CLIENT_SECRET
4. Em OAuth2 → Redirects, adicionar:
   - http://localhost:3000/auth/discord/callback
5. ✅ Pronto!

### 4. **Preencher .env**

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_KEY=sua-chave-anon-aqui
DISCORD_CLIENT_ID=seu-id-aqui
DISCORD_CLIENT_SECRET=seu-secret-aqui
DISCORD_REDIRECT_URI=http://localhost:3000/auth/discord/callback
PORT=3000
NODE_ENV=development
```

### 5. **Executar no Roblox**

1. Abrir executor (Synapse X, Script-Ware, etc)
2. Copiar `rodiscord_client_v2_COMPLETO.lua`
3. Alterar URL: `API_URL = "http://localhost:3000"`
4. Executar em um jogo Roblox
5. Fazer login (Discord ou Roblox)
6. ✅ Curtir o RoDiscord!

---

## 💬 FUNCIONALIDADES DETALHADAS

### Mensagens
```
[12:34] 👤 Usuario: Oi pessoal! 😄
        Reactions: 😂 (3) ❤️ (2)
```

### Emojis Personalizados
```
Nome: cute_smile
URL: https://cdn.example.com/emoji.png

Usar em mensagem: :cute_smile:
```

### Figurinhas
```
Categoria: Anime
Nome: Astolfo
URL: https://...
Usar: Clique para enviar sticker
```

### Configurações (Painel Lateral)
```
⚙️ Configurações
│
├─ 🖥️ Servidor
│  ├─ Emojis Personalizados: ON
│  ├─ Figurinhas: ON
│  └─ Filtro de Profanidade: OFF
│
├─ 🔒 Segurança
│  ├─ 2FA: OFF (em breve)
│  ├─ Logs de Auditoria: ON
│  └─ Rate Limiting: 100/15min
│
├─ 😀 Emojis (5 criados)
│  ├─ + Adicionar Emoji
│  └─ smile, love, custom, omg, lol
│
└─ 🎨 Figurinhas (12 criadas)
   └─ + Adicionar Figurinha
```

---

## 🔒 SEGURANÇA

### Como suas credenciais são protegidas:

1. **Arquivo .env é lido UMA VEZ** ao iniciar o backend
2. **AES-256 encripta** todas as credenciais na memória
3. **.secret.key gerada** automaticamente (32 bytes)
4. **Nunca é commitado** no Git (está em .gitignore)
5. **Código Luau pode ser obfuscado** para não revelar URLs
6. **Rate limiting** evita brute force attacks

### Veja: SEGURANCA_OBFUSCACAO.md

Tem instrução completa de como proteger tudo.

---

## 📊 ENDPOINTS API (20+)

### Autenticação
- `GET /auth/discord` - Redirecionar para login Discord
- `GET /auth/discord/callback` - Callback do Discord
- `POST /api/auth/verify-pin` - Verificar PIN do Roblox
- `POST /api/auth/roblox-login` - Login com Roblox

### Servidores
- `GET /api/servers` - Listar servidores
- `POST /api/servers` - Criar servidor
- `GET /api/servers/:id/settings` - Ver configurações
- `PUT /api/servers/:id/settings` - Alterar configurações

### Canais
- `GET /api/servers/:id/channels` - Listar canais
- `POST /api/servers/:id/channels` - Criar canal

### Mensagens
- `GET /api/channels/:id/messages` - Listar mensagens
- `POST /api/channels/:id/messages` - Enviar mensagem

### Emojis
- `GET /api/servers/:id/emojis` - Listar emojis
- `POST /api/servers/:id/emojis` - Criar emoji

### Stickers
- `GET /api/servers/:id/stickers` - Listar figurinhas
- `POST /api/servers/:id/stickers` - Upload de figurinha

### Reações
- `POST /api/messages/:id/reactions` - Adicionar reação
- `GET /api/messages/:id/reactions` - Ver reações

### Mensagens Diretas
- `GET /api/direct-messages/:user_id` - Ver DMs
- `POST /api/direct-messages` - Enviar DM

### Bloqueio
- `POST /api/users/:id/block/:blocked_id` - Bloquear usuário
- `GET /api/users/:id/blocked` - Ver bloqueados

---

## 📈 STATS

| Métrica | Valor |
|---------|-------|
| Linhas de código | 3000+ |
| Endpoints API | 20+ |
| Tabelas BD | 12 |
| Funcionalidades | 25+ |
| Emojis personalizados | ∞ |
| Figurinhas personalizadas | ∞ |
| Usuários simultâneos | Ilimitado |
| Mensagens por segundo | Limitado por rate limit |

---

## 🎯 PRÓXIMOS PASSOS

### Fase 1 (Agora)
- [x] Servidores e canais
- [x] Mensagens
- [x] Emojis personalizados
- [x] Figurinhas
- [x] Configurações
- [x] Segurança

### Fase 2 (Breve)
- [ ] Voice chat
- [ ] Edição de mensagens
- [ ] Deletar mensagens
- [ ] Pinned messages
- [ ] Threads
- [ ] Roles e permissões

### Fase 3 (Futuro)
- [ ] Bot API
- [ ] Webhooks
- [ ] Integrações
- [ ] Streaming
- [ ] Mobile app

---

## 🐛 TROUBLESHOOTING

### "Erro 42P10 no SQL"
**Solução**: Use `rodiscord_database_v2.sql` (versão corrigida)

### "PIN inválido"
**Solução**: Ir em http://localhost:3000/auth/discord, fazer login e copiar novo PIN

### "Cannot connect to backend"
**Solução**: Verificar se `npm run dev` está rodando

### "Credenciais não carregam"
**Solução**: Preencher .env corretamente e reiniciar backend

Veja: **SEGURANCA_OBFUSCACAO.md** para mais soluções

---

## 📝 CHANGELOG v2

```
v2.0.0 (2026-09-22)
├─ [NEW] Painel de configurações completo
├─ [NEW] Sistema de emojis personalizados
├─ [NEW] Sistema de figurinhas
├─ [NEW] Reações com emojis
├─ [NEW] Segurança com criptografia
├─ [NEW] config_manager.js
├─ [FIX] SQL schema corrigido
├─ [FIX] Obfuscação de credenciais
└─ [IMPROVE] UI Discord-like completa
```

---

## 🎉 FEATURES

**Total de funcionalidades**: 25+

Servidores ✅
Canais ✅
Mensagens ✅
Emojis Personalizados ✅
Figurinhas ✅
Reações ✅
Mensagens Diretas ✅
Perfis ✅
Configurações ✅
Segurança ✅
Rate Limiting ✅
Logs de Auditoria ✅
Bloqueio de Usuários ✅
RLS no Banco ✅
Encriptação ✅

---

## ✅ CHECKLIST DE SETUP

- [ ] Backend instalado e rodando
- [ ] Supabase criado e DB populado
- [ ] Discord OAuth2 configurado
- [ ] .env preenchido com credenciais
- [ ] .secret.key gerado automaticamente
- [ ] Roblox executor com script
- [ ] Primeiro login funcionando
- [ ] Mensagens sendo enviadas
- [ ] Emojis personalizados funcionando
- [ ] Painel de configurações abrindo

---

## 💻 REQUISITOS

- Node.js 16+
- Conta Supabase (gratuita)
- Conta Discord Developer (gratuita)
- Executor Roblox
- Internet

---

## 📞 SUPORTE

Dúvidas? Veja:
1. SEGURANCA_OBFUSCACAO.md - Segurança e proteção
2. RODISCORD_SETUP_GUIDE.md - Setup passo-a-passo
3. RODISCORD_TECHNICAL_DOCS.md - Documentação técnica

---

**Desenvolvido com ❤️ para criar o Discord que você MERECE** 🔥

Sem restrições, sem moderação, sem age-lock. Só diversão com amigos.

**Aproveita!** 🎉
