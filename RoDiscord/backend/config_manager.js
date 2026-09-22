/**
 * ============================================
 * CONFIG MANAGER - Segurança de Credenciais
 * ============================================
 * Arquivo para gerenciar configurações sensitivas
 * Mantém credenciais seguras e obfuscadas
 */

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

class ConfigManager {
    constructor() {
        this.envFile = path.join(__dirname, '.env');
        this.encryptedFile = path.join(__dirname, '.env.encrypted');
        this.keyFile = path.join(__dirname, '.secret.key');
        this.loadConfig();
    }

    // ============================================
    // Gerar chave de criptografia
    // ============================================
    generateEncryptionKey() {
        const key = crypto.randomBytes(32);
        fs.writeFileSync(this.keyFile, key.toString('hex'));
        console.log('✅ Chave de criptografia gerada: .secret.key');
        return key;
    }

    // ============================================
    // Obter chave de criptografia
    // ============================================
    getEncryptionKey() {
        if (!fs.existsSync(this.keyFile)) {
            return this.generateEncryptionKey();
        }
        const keyHex = fs.readFileSync(this.keyFile, 'utf8');
        return Buffer.from(keyHex, 'hex');
    }

    // ============================================
    // Criptografar configuração
    // ============================================
    encryptConfig(plainText) {
        const key = this.getEncryptionKey();
        const iv = crypto.randomBytes(16);
        const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
        
        let encrypted = cipher.update(plainText);
        encrypted = Buffer.concat([encrypted, cipher.final()]);
        
        return iv.toString('hex') + ':' + encrypted.toString('hex');
    }

    // ============================================
    // Descriptografar configuração
    // ============================================
    decryptConfig(encryptedText) {
        const key = this.getEncryptionKey();
        const parts = encryptedText.split(':');
        const iv = Buffer.from(parts[0], 'hex');
        const encrypted = Buffer.from(parts[1], 'hex');
        
        const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
        let decrypted = decipher.update(encrypted);
        decrypted = Buffer.concat([decrypted, decipher.final()]);
        
        return decrypted.toString('utf8');
    }

    // ============================================
    // Carregar configuração
    // ============================================
    loadConfig() {
        require('dotenv').config();
        
        // Se .env existe, priorizar isso
        if (fs.existsSync(this.envFile)) {
            this.config = this.loadFromEnv();
        }
        // Se arquivo criptografado existe, descriptografar
        else if (fs.existsSync(this.encryptedFile)) {
            this.config = this.loadFromEncrypted();
        }
        // Senão, criar novo
        else {
            this.createNewConfig();
        }
    }

    // ============================================
    // Carregar de .env
    // ============================================
    loadFromEnv() {
        return {
            SUPABASE_URL: process.env.SUPABASE_URL,
            SUPABASE_KEY: process.env.SUPABASE_KEY,
            DISCORD_CLIENT_ID: process.env.DISCORD_CLIENT_ID,
            DISCORD_CLIENT_SECRET: process.env.DISCORD_CLIENT_SECRET,
            DISCORD_REDIRECT_URI: process.env.DISCORD_REDIRECT_URI,
            PORT: process.env.PORT || 3000,
            NODE_ENV: process.env.NODE_ENV || 'development',
            JWT_SECRET: process.env.JWT_SECRET || crypto.randomBytes(32).toString('hex'),
            API_RATE_LIMIT: process.env.API_RATE_LIMIT || '100',
            SESSION_TIMEOUT: process.env.SESSION_TIMEOUT || '86400'
        };
    }

    // ============================================
    // Carregar de arquivo criptografado
    // ============================================
    loadFromEncrypted() {
        const encrypted = fs.readFileSync(this.encryptedFile, 'utf8');
        const decrypted = this.decryptConfig(encrypted);
        return JSON.parse(decrypted);
    }

    // ============================================
    // Criar novo arquivo de configuração
    // ============================================
    createNewConfig() {
        if (!fs.existsSync(this.envFile)) {
            const template = `# ============================================
# RODISCORD - CONFIGURAÇÃO (NÃO COMMITAR!)
# ============================================

# Node Environment
NODE_ENV=development
PORT=3000

# ============================================
# SUPABASE
# ============================================
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_KEY=sua-chave-anon-aqui

# ============================================
# DISCORD OAUTH2
# ============================================
DISCORD_CLIENT_ID=seu-client-id-aqui
DISCORD_CLIENT_SECRET=seu-client-secret-aqui
DISCORD_REDIRECT_URI=http://localhost:3000/auth/discord/callback

# ============================================
# SEGURANÇA
# ============================================
JWT_SECRET=sua-chave-secreta-aqui
API_RATE_LIMIT=100
SESSION_TIMEOUT=86400
`;
            fs.writeFileSync(this.envFile, template);
            console.log('✅ Arquivo .env criado. Preencha com suas credenciais!');
        }
        
        require('dotenv').config();
        this.config = this.loadFromEnv();
    }

    // ============================================
    // Salvar configuração criptografada
    // ============================================
    saveEncrypted() {
        const plainText = JSON.stringify(this.config, null, 2);
        const encrypted = this.encryptConfig(plainText);
        fs.writeFileSync(this.encryptedFile, encrypted);
        console.log('✅ Configuração salva de forma criptografada: .env.encrypted');
    }

    // ============================================
    // Obter valor da configuração
    // ============================================
    get(key) {
        return this.config[key];
    }

    // ============================================
    // Obter todas as configurações
    // ============================================
    getAll() {
        return { ...this.config };
    }

    // ============================================
    // Validar configuração
    // ============================================
    validate() {
        const required = [
            'SUPABASE_URL',
            'SUPABASE_KEY',
            'DISCORD_CLIENT_ID',
            'DISCORD_CLIENT_SECRET',
            'DISCORD_REDIRECT_URI'
        ];

        const missing = required.filter(key => !this.config[key]);

        if (missing.length > 0) {
            console.error('❌ Variáveis de ambiente faltando:', missing);
            return false;
        }

        console.log('✅ Todas as configurações obrigatórias estão presentes');
        return true;
    }

    // ============================================
    // Obfuscar valores sensitivos (para logs)
    // ============================================
    sanitize(obj) {
        const sensitiveKeys = ['SUPABASE_KEY', 'DISCORD_CLIENT_SECRET', 'JWT_SECRET'];
        const sanitized = { ...obj };

        sensitiveKeys.forEach(key => {
            if (sanitized[key]) {
                const original = sanitized[key];
                const length = original.length;
                sanitized[key] = original.substring(0, 4) + '*'.repeat(length - 8) + original.substring(length - 4);
            }
        });

        return sanitized;
    }
}

// ============================================
// EXPORTAR E INICIALIZAR
// ============================================
const configManager = new ConfigManager();

module.exports = configManager;
