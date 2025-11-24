# 🚀 Instalação Rápida - Chatwoot SDR IA v2.1.1

Instalação automática do plugin SDR IA em qualquer servidor Chatwoot.

---

## 📋 Requisitos

- Chatwoot instalado (versão 2.x ou superior)
- Acesso root ao servidor
- Git instalado
- API Key da OpenAI

---

## ⚡ Instalação com 1 Comando

```bash
curl -fsSL https://raw.githubusercontent.com/eversonsantos-dev/chatwoot-sdr-ia/main/install.sh | sudo bash
```

### Ou instalação manual:

```bash
# 1. Baixar o script
wget https://raw.githubusercontent.com/eversonsantos-dev/chatwoot-sdr-ia/main/install.sh

# 2. Dar permissão de execução
chmod +x install.sh

# 3. Executar
sudo ./install.sh
```

---

## 🔧 O que o script faz?

1. ✅ Detecta automaticamente a instalação do Chatwoot
2. ✅ Cria backup completo antes de instalar
3. ✅ Baixa o plugin SDR IA v2.1.1 do GitHub
4. ✅ Copia arquivos para o Chatwoot
5. ✅ Configura variáveis de ambiente
6. ✅ Executa migrations do banco (se instalação local)
7. ✅ Cria documentação de configuração
8. ✅ Instrui sobre próximos passos

---

## 📝 Durante a Instalação

O script vai solicitar:

1. **Caminho do Chatwoot** (detecta automaticamente em /root/chatwoot ou /home/chatwoot)
2. **API Key da OpenAI** (necessária para IA e transcrição de áudio)

---

## 🎯 Após a Instalação

### 1. Configurar no Chatwoot

1. Faça login no Chatwoot como **Super Admin**
2. Vá em **Settings** → **Inboxes** → Selecione seu inbox
3. Configure na aba **SDR IA**:
   - ✅ Ativar SDR IA
   - 📝 Nome da Clínica
   - 📍 Endereço Completo
   - 🔗 Link de Agendamento
   - 👥 Closers (agentes que receberão leads)

### 2. Testar

- Envie uma mensagem de texto
- Envie um áudio
- Verifique os logs

---

## 🐳 Instalação Docker

Se o Chatwoot está rodando em Docker, após o script você precisa:

```bash
# 1. Rebuild da imagem
cd /caminho/do/chatwoot
docker build -t seu-usuario/chatwoot:sdr-ia .

# 2. Executar migrations
docker exec -it chatwoot_app bundle exec rails db:migrate

# 3. Reiniciar containers
docker-compose restart
```

**Docker Swarm:**
```bash
docker service update --force chatwoot_app
docker service update --force chatwoot_sidekiq
```

---

## 📊 Funcionalidades

- 🤖 **IA Conversacional** - Responde automaticamente aos leads
- 🎤 **Transcrição de Áudio** - Áudios do WhatsApp transcritos automaticamente
- 📈 **Qualificação Inteligente** - Sistema de pontuação 0-130 pontos
- 🎯 **Round Robin** - Distribuição automática de leads entre closers
- ⏱️ **Buffer de Mensagens** - Agrupa mensagens em 35s (reduz custos)

---

## 🔐 Segurança

- Backup automático antes da instalação
- API Key armazenada apenas no .env
- Validação de todos os caminhos
- Logs detalhados de todas as operações

---

## 📚 Documentação Completa

- **GitHub:** https://github.com/eversonsantos-dev/chatwoot-sdr-ia
- **CHANGELOG:** https://github.com/eversonsantos-dev/chatwoot-sdr-ia/blob/main/CHANGELOG.md
- **Erros e Correções:** https://github.com/eversonsantos-dev/chatwoot-sdr-ia/blob/main/ERROS_E_CORRECOES_COMPLETO.md
- **Release v2.1.1:** https://github.com/eversonsantos-dev/chatwoot-sdr-ia/releases/tag/v2.1.1

---

## 🆘 Suporte

- **Issues:** https://github.com/eversonsantos-dev/chatwoot-sdr-ia/issues
- **Documentação:** Após instalação, veja `SDR_IA_CONFIG.md` no diretório do Chatwoot

---

## ⚠️ Troubleshooting

### Erro: "Chatwoot não encontrado"
- O script detecta automaticamente em `/root/chatwoot` ou `/home/chatwoot`
- Se está em outro local, o script vai solicitar o caminho

### Erro: "Permission denied"
- Execute com `sudo`: `sudo ./install.sh`

### IA não responde
1. Verifique se está ativado no inbox: Settings → Inboxes → SDR IA
2. Verifique se a API Key está configurada no `.env`
3. Verifique os logs: `tail -f log/production.log | grep "\[SDR IA\]"`

### Áudio não transcreve
1. Verifique se a API Key da OpenAI está correta
2. Verifique logs: `tail -f log/production.log | grep "\[Audio\]"`
3. Confirme que o formato é suportado (MP3, M4A, WAV, OGG)

---

## 💡 Dicas

- O backup é salvo em `/root/backups/`
- A documentação é criada em `SDR_IA_CONFIG.md`
- Logs sempre com tag `[SDR IA]` para fácil busca
- Buffer de 35s reduz custo de API em ~70%

---

**Desenvolvido com ❤️ por [@eversonsantos-dev](https://github.com/eversonsantos-dev)**

**Versão:** v2.1.1 | **Status:** ✅ Estável e Validado em Produção
