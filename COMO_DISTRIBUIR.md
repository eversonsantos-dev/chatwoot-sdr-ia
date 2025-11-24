# 📦 Como Distribuir o Chatwoot SDR IA

Guia completo de distribuição comercial do plugin.

---

## ⚡ Instalação com 1 Comando (Inline)

### Solução Mais Simples:

Você envia para o cliente executar:

```bash
curl -fsSL https://seu-servidor.com/chatwoot-sdr-ia.tar.gz | tar -xz -C /tmp && cd /tmp/chatwoot-sdr-ia-v2.1.1 && sudo ./install.sh && cd - && rm -rf /tmp/chatwoot-sdr-ia-v2.1.1
```

**Vantagens:**
- ✅ Apenas 1 comando
- ✅ Cliente só precisa fazer "copiar e colar"
- ✅ Baixa, extrai, instala e limpa automaticamente
- ✅ Não deixa rastros no servidor

---

## 🎯 Método Recomendado para Produto Comercial

### Opção 1: Google Drive / Dropbox (Mais Fácil)

**Você faz:**

1. Criar o pacote:
   ```bash
   ./criar-pacote.sh
   ```

2. Fazer upload de `/root/builds/chatwoot-sdr-ia-v2.1.1.tar.gz` para:
   - Google Drive (compartilhamento privado)
   - Dropbox
   - OneDrive

3. Gerar link de download direto

4. Enviar para cliente:
   ```bash
   curl -L "LINK_DO_GOOGLE_DRIVE" -o chatwoot-sdr-ia.tar.gz && \
   tar -xzf chatwoot-sdr-ia.tar.gz && \
   cd chatwoot-sdr-ia-v2.1.1 && \
   sudo ./install.sh
   ```

---

### Opção 2: Seu Próprio Servidor (Mais Profissional)

**Setup (uma vez):**

```bash
# No seu servidor web
mkdir -p /var/www/downloads/sdr-ia
cp /root/builds/chatwoot-sdr-ia-v2.1.1.tar.gz /var/www/downloads/sdr-ia/

# Configurar nginx/apache para servir o arquivo
```

**Cliente executa:**

```bash
curl -fsSL https://downloads.seudominio.com/sdr-ia/chatwoot-sdr-ia-v2.1.1.tar.gz | tar -xz -C /tmp && \
cd /tmp/chatwoot-sdr-ia-v2.1.1 && \
sudo ./install.sh && \
cd - && rm -rf /tmp/chatwoot-sdr-ia-v2.1.1
```

---

### Opção 3: Email com Anexo (Mais Simples)

**Você faz:**

1. Anexar `/root/builds/chatwoot-sdr-ia-v2.1.1.tar.gz` no email

2. Cliente recebe e faz upload para servidor via SCP:
   ```bash
   scp chatwoot-sdr-ia-v2.1.1.tar.gz root@servidor:/root/
   ```

3. Cliente executa no servidor:
   ```bash
   cd /root && \
   tar -xzf chatwoot-sdr-ia-v2.1.1.tar.gz && \
   cd chatwoot-sdr-ia-v2.1.1 && \
   sudo ./install.sh
   ```

---

## 🔒 Sistema de Licenciamento (Opcional)

Se quiser controlar quem instala:

### 1. Gerar Token Único por Cliente

```bash
# Gerar token único
TOKEN=$(openssl rand -hex 16)
echo "Cliente: João Silva - Token: $TOKEN" >> /root/clientes-tokens.txt
```

### 2. Modificar `install.sh` para Validar Token

Adicione no início do `install.sh`:

```bash
# Validar token
read -p "Digite seu TOKEN de instalação: " CLIENT_TOKEN
curl -s "https://api.seudominio.com/validate?token=$CLIENT_TOKEN" | grep -q "valid" || exit 1
```

### 3. API Simples de Validação

Crie uma API que valida tokens:
- Token válido → return "valid"
- Token inválido → return "invalid"
- Log todas as tentativas

---

## 📊 Rastreamento de Instalações

### Adicionar ao `install.sh`:

```bash
# No final do install.sh, adicione:
curl -s "https://api.seudominio.com/install-log" \
  -d "version=2.1.1" \
  -d "client_token=$CLIENT_TOKEN" \
  -d "timestamp=$(date)" >/dev/null 2>&1 || true
```

Você recebe notificação cada vez que alguém instala!

---

## 💰 Modelos de Venda

### 1. Venda Única + Suporte

- Cliente paga uma vez
- Recebe pacote v2.1.1
- Suporte por 30 dias incluído
- Atualizações pagas separadamente

### 2. Assinatura Mensal

- Cliente paga mensalmente
- Acesso a atualizações automáticas
- Suporte contínuo
- Token expira se não pagar

### 3. Licença por Servidor

- Cliente paga por servidor instalado
- Token único por servidor
- Você controla quantos servidores cada cliente tem

---

## 📝 Documentação para o Cliente

### Instruções Simples (WhatsApp/Email):

```
🚀 INSTALAÇÃO DO CHATWOOT SDR IA v2.1.1

1. Conecte ao seu servidor via SSH:
   ssh root@seu-servidor

2. Execute este comando (copie e cole tudo):
   [COMANDO AQUI]

3. Quando pedir, digite sua API Key da OpenAI

4. Pronto! O sistema está instalado.

Após instalar:
- Acesse Chatwoot → Settings → Inboxes
- Configure o SDR IA no seu inbox
- Adicione os closers que receberão leads

Dúvidas? Entre em contato: seu@email.com
```

---

## 🎯 Recomendação Final

**Para começar rápido:**
- Use Google Drive + link direto
- Comando inline de 1 linha
- Instruções por WhatsApp/Email

**Para escalar:**
- Setup servidor próprio
- Sistema de tokens/licenças
- API de rastreamento
- Portal do cliente

---

## 📦 Pacote Atual

**Arquivo:** `/root/builds/chatwoot-sdr-ia-v2.1.1.tar.gz`
**Tamanho:** 36KB
**SHA256:** `5d1f5f4bc245a7765eda42e9964ac8c622a9e91e0b67adba95a84008f4819369`

**Contém:**
- Plugin completo
- Instalador automático
- Documentação completa
- Tudo necessário

---

**Pronto para vender! 🚀**
