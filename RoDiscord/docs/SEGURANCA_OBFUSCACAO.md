# 🔐 RODISCORD - GUIA COMPLETO DE SEGURANÇA & OBFUSCAÇÃO

## 📌 PROBLEMA
Você não quer que ninguém vendo seu código consiga achar suas credenciais (SUPABASE_KEY, DISCORD_CLIENT_SECRET, etc).

## ✅ SOLUÇÃO
Usar o `config_manager.js` que criptografa tudo automaticamente.

---

## 1️⃣ SETUP SEGURO DO BACKEND

### Passo 1: Usar o config_manager.js

```bash
# Estrutura das pastas
rodiscord-backend/
├── package.json
├── config_manager.js       # ← Novo: Gerencia chaves
├── rodiscord_backend_v2.js # ← Usa config_manager
├── .env                    # ← Seu arquivo confidencial
├── .env.encrypted          # ← Gerado automaticamente (ENCRIPTADO)
└── .secret.key             # ← Chave de decriptografia (NUNCA commitar!)
```

### Passo 2: Atualizar backend_v2.js para usar config_manager

**No início do arquivo, trocar:**

```javascript
// ❌ ANTES (Inseguro - lê de .env diretamente)
require('dotenv').config();
const SUPABASE_URL = process.env.SUPABASE_URL;

// ✅ DEPOIS (Seguro - usa config_manager encriptado)
const configManager = require('./config_manager');
const SUPABASE_URL = configManager.get('SUPABASE_URL');
```

**Exemplo completo:**

```javascript
const configManager = require('./config_manager');

// Validar se tudo está ok
if (!configManager.validate()) {
    console.error('❌ Erro: Credenciais incompletas!');
    process.exit(1);
}

// Usar credenciais de forma segura
const SUPABASE_URL = configManager.get('SUPABASE_URL');
const SUPABASE_KEY = configManager.get('SUPABASE_KEY');
const DISCORD_CLIENT_ID = configManager.get('DISCORD_CLIENT_ID');
const DISCORD_CLIENT_SECRET = configManager.get('DISCORD_CLIENT_SECRET');

// Logs com dados obfuscados (não expõe secrets)
console.log('✅ Configuração carregada:', configManager.sanitize(configManager.getAll()));
```

### Passo 3: .gitignore (CRÍTICO!)

```bash
# Create .gitignore na raiz do projeto
node_modules/
.env                 # Nunca commitar arquivo com secrets
.env.local
.env.*.local
.env.encrypted       # Opcional: se compartilhar encriptado
.secret.key          # NUNCA COMMITAR ISTO!
.DS_Store
dist/
build/
*.log
```

---

## 2️⃣ FLUXO DE ENCRIPTAÇÃO

### Como funciona:

```
┌─────────────────────────────────────────────┐
│  1. Você preenche .env com credenciais      │
│  SUPABASE_URL=xxx                           │
│  DISCORD_CLIENT_SECRET=yyy                  │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  2. config_manager.js lê .env               │
│  Detecta se existe .secret.key               │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  3. Se não existir, gera nova chave         │
│  .secret.key gerada (32 bytes hex)          │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  4. Encriptação AES-256-CBC                 │
│  Todo valor é criptografado                 │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  5. Ao usar, descriptografa automaticamente │
│  configManager.get('SUPABASE_URL')          │
│  ↓ Retorna valor descriptografado           │
└─────────────────────────────────────────────┘
```

---

## 3️⃣ ENCRIPTAÇÃO MANUAL (OPCIONAL)

Se quiser encriptar tudo manualmente:

```javascript
// Usar o config_manager para encriptar
const configManager = require('./config_manager');

// Encriptar um texto qualquer
const textoSecreto = "SenhaSuper123!";
const textoEncriptado = configManager.encryptConfig(textoSecreto);

console.log("Texto original:", textoSecreto);
console.log("Texto encriptado:", textoEncriptado);

// Depois descriptografar
const textoDescriptado = configManager.decryptConfig(textoEncriptado);
console.log("Descriptografado:", textoDescriptado);
```

---

## 4️⃣ OBFUSCAÇÃO DO CÓDIGO LUAU (CLIENT)

### Opção 1: Minificação

```bash
# Instalar minificador
npm install -g luamin

# Minificar seu script
luamin rodiscord_client_v2_COMPLETO.lua > rodiscord_client_minified.lua
```

Resultado:
```lua
-- Antes (legível, 1000+ linhas)
local function makeRequest(method, endpoint, data)
    local url = CONFIG.API_URL .. endpoint
    -- ... código legível
end

-- Depois (minificado, ~100 linhas)
local function a(b,c,d)local e=f.g..c;...end
```

### Opção 2: Obfuscação Real (Mais Seguro)

Usar serviço online como:
- **luaphobos.io** - Obfuscador Lua online
- **lua-minifier.com** - Minificador + Obfuscador

```bash
# Ou usar localmente com Node.js:
npm install -g @roblox/luau-ast

# Obfuscar código
obfuscate --input rodiscord_client_v2_COMPLETO.lua --output rodiscord_obfuscated.lua
```

### Opção 3: DIY - Remover strings sensitivas

```lua
-- ❌ ANTES (Não faça assim!)
local CONFIG = {
    API_URL = "http://localhost:3000",
}

-- ✅ DEPOIS (Melhor)
local CONFIG = {}
-- URL é concatenada em runtime para esconder
function getAPIUrl()
    return "http" .. "://" .. "localhost" .. ":3000"
end
```

---

## 5️⃣ PROTEÇÃO DO CÓDIGO NO EXECUTOR

Se está usando **Synapse X** ou outro executor:

### Localizar arquivo criptografado:
```
C:\Users\[Seu Usuário]\AppData\Local\Synapse\workspace\scripts\
```

### Dentro do executor:

```lua
-- ✅ Bom: String com caracteres especiais
local obfuscated = "RoDiscord\120\95\99\108\105\101\110\116"

-- ✅ Bom: Concatenação múltipla
local url = "http://" .. "local" .. "host:" .. "3000"

-- ✅ Bom: Hexadecimal
local hex_url = "\72\116\116\112..."

-- ❌ Ruim: String simples
local url = "http://localhost:3000"
```

---

## 6️⃣ PROTEGER NO SUPABASE

### NÃO exponha a chave anon pública:

```javascript
// ❌ NUNCA faça isso
const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."; // EXPOSTO!
console.log("Chave:", supabaseKey); // EXPOSTO!

// ✅ SEMPRE use através do config_manager
const supabaseKey = configManager.get('SUPABASE_KEY');
// Nunca log ou exponha diretamente
```

### No Supabase, configurar RLS (Row Level Security):

```sql
-- Exemplo: Apenas usuários autenticados podem ver profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuários só veem próprio perfil"
ON profiles FOR SELECT
USING (id = auth.uid());

-- Isso evita que alguém com a chave anon veja tudo
```

---

## 7️⃣ DEPLOY SEGURO EM PRODUÇÃO

### Se usar Heroku, Railway, etc:

**NÃO commite .env!**

```bash
# Adicionar ao .gitignore
echo ".env" >> .gitignore
echo ".secret.key" >> .gitignore
git add .gitignore
git commit -m "Add .env to gitignore"
git push
```

**Configurar variáveis no painel do servidor:**

```
Heroku Dashboard → Settings → Config Vars

Adicionar:
SUPABASE_URL = https://seu-projeto.supabase.co
SUPABASE_KEY = sua-chave-anon
DISCORD_CLIENT_ID = xxx
DISCORD_CLIENT_SECRET = xxx
DISCORD_REDIRECT_URI = https://seu-dominio.com/auth/discord/callback
```

---

## 8️⃣ VERIFICAR SE ESTÁ SEGURO

### Antes de fazer deploy:

```bash
# Verificar se credenciais estão seguras
cat .gitignore | grep .env      # Deve retornar ".env"
cat .gitignore | grep .secret   # Deve retornar ".secret.key"

# Listar todos os secrets no .env
grep -v "^#" .env | grep -v "^$"

# NÃO deve aparecer em nenhum arquivo do git
git grep "DISCORD_CLIENT_SECRET"  # Deve retornar VAZIO!
git grep "SUPABASE_KEY"            # Deve retornar VAZIO!
```

### Testar encriptação:

```bash
# Executar o backend
node rodiscord_backend_v2.js

# Deve aparecer:
# ✅ Chave de criptografia gerada: .secret.key
# ✅ Todas as configurações obrigatórias estão presentes
```

---

## 9️⃣ GUIA RÁPIDO: SETUP DE SEGURANÇA

### 1. Criar arquivo .env (LOCAL, NÃO COMMITAR):
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=xxxxxxxxxxxxx
DISCORD_CLIENT_ID=1234567890
DISCORD_CLIENT_SECRET=abcdefghijk
DISCORD_REDIRECT_URI=http://localhost:3000/auth/discord/callback
```

### 2. Executar backend (cria .secret.key):
```bash
npm install
node rodiscord_backend_v2.js
# ✅ Gera .secret.key e .env.encrypted
```

### 3. Adicionar ao .gitignore:
```bash
echo ".env" >> .gitignore
echo ".secret.key" >> .gitignore
git add .gitignore
git commit -m "Segurança: adicionar .env e .secret.key ao gitignore"
```

### 4. Verificar se está seguro:
```bash
# Nada sensível deve aparecer
git log --all --oneline --graph
git show HEAD:.env  # Deve dar erro (não está no git)
```

### 5. Para produção:
```bash
# Usar variáveis de ambiente do servidor
# NÃO usar .env em produção
# Configurar no painel (Heroku, Railway, etc)
```

---

## 🔟 CHECKLIST FINAL

- [ ] .env criado com credenciais
- [ ] .secret.key gerado automaticamente
- [ ] .env e .secret.key adicionados ao .gitignore
- [ ] Backend roda sem erros com config_manager
- [ ] Nenhuma credencial aparece em git log
- [ ] Código Luau minificado/obfuscado (opcional)
- [ ] RLS configurada no Supabase
- [ ] Variáveis de ambiente configuradas em produção
- [ ] .env.encrypted pode ser compartilhado (é encriptado)
- [ ] Apenas .secret.key precisa ser protegido

---

## 🚨 RESUMO: O QUE FAZER E NÃO FAZER

### ✅ FAZER:

- Usar `config_manager.js` para carregar credenciais
- Adicionar `.env` e `.secret.key` ao `.gitignore`
- Encriptar configurações com AES-256
- Usar variáveis de ambiente em produção
- Minificar/Obfuscar código Luau
- Implementar RLS no Supabase
- Logar apenas valores obfuscados

### ❌ NÃO FAZER:

- Commitar `.env` no Git
- Commitar `.secret.key` no Git
- Logar credenciais completas
- Expor URL de API no código cliente
- Usar credenciais hardcoded
- Compartilhar `.secret.key` publicamente
- Guardar credenciais em arquivos de texto

---

**Agora seu código está seguro! 🔒**

Mesmo que alguém conseguir seu código-fonte, não conseguirá encontrar suas credenciais.

