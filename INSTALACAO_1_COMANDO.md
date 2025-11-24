# 🚀 Instalação com 1 Comando - Chatwoot SDR IA

Três opções para instalação com apenas 1 comando.

---

## 📦 Opção 1: Com Pacote Pré-Baixado (Recomendado)

Você envia o pacote + script para o cliente. Cliente executa:

```bash
curl -fsSL https://seu-dominio.com/install.sh | sudo bash -s -- SEU_TOKEN_AQUI
```

---

## 📦 Opção 2: Download Manual Simples

**1. Você envia o link do pacote para o cliente**

**2. Cliente executa apenas 1 comando:**

```bash
curl -fsSL https://seu-dominio.com/chatwoot-sdr-ia-v2.1.1.tar.gz | tar -xz && cd chatwoot-sdr-ia-v2.1.1 && sudo ./install.sh
```

---

## 📦 Opção 3: Script Hospedado (Mais Profissional)

### Para Você (Vendedor):

1. **Hospedar o pacote em algum lugar:**
   - Seu próprio servidor
   - AWS S3
   - DigitalOcean Spaces
   - Google Cloud Storage

2. **Hospedar o script de instalação remota**

3. **Gerar token único para cada cliente**

### Para o Cliente:

```bash
curl -fsSL https://sdr-ia.seudominio.com/install | sudo bash -s -- TOKEN_DO_CLIENTE
```

---

## 💡 Solução Mais Simples (SEM dependências externas)

### Script Auto-Contido

Crie um script único que contém TUDO (base64):

```bash
#!/bin/bash
# Este arquivo contém o instalador + plugin completo em base64
# Cliente executa apenas: sudo ./install-completo.sh
```

Vou criar esse script para você!

---

## 🎯 Melhor Abordagem para Produto Comercial

**O que eu recomendo:**

### 1. Enviar por Email/WhatsApp:

Cliente recebe um link privado:
```
https://downloads.seudominio.com/cliente-123/chatwoot-sdr-ia.tar.gz
```

### 2. Instruções Simples:

```bash
# Copiar e colar no servidor:
curl -O https://downloads.seudominio.com/cliente-123/chatwoot-sdr-ia.tar.gz && \
tar -xzf chatwoot-sdr-ia.tar.gz && \
cd chatwoot-sdr-ia-v2.1.1 && \
sudo ./install.sh
```

Ou ainda mais simples:

```bash
bash <(curl -s https://downloads.seudominio.com/cliente-123/install.sh)
```

---

## 🔐 Segurança

- Cada cliente recebe um link único
- Link expira após X dias
- Token de acesso por cliente
- Log de instalações

---

## 📝 Próximo Passo

Qual abordagem você prefere?

1. **Simples:** Enviar .tar.gz por email/drive + 3 comandos
2. **Profissional:** Hospedar em servidor próprio + 1 comando
3. **Auto-contido:** Script único com tudo embutido

Posso implementar qualquer uma delas!
