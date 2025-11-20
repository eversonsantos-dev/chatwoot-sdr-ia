# Chatwoot SDR IA Module

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Chatwoot](https://img.shields.io/badge/chatwoot-v4.1.0-green.svg)
![Ruby](https://img.shields.io/badge/ruby-3.3.3-red.svg)
![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4-purple.svg)

Módulo de **Qualificação Automática de Leads** para Chatwoot usando Inteligência Artificial (OpenAI GPT-4).

## 📋 Índice

- [Sobre](#sobre)
- [Características](#características)
- [Arquitetura](#arquitetura)
- [Instalação](#instalação)
- [Configuração](#configuração)
- [Interface Administrativa](#interface-administrativa)
- [Como Funciona](#como-funciona)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Documentação](#documentação)
- [Requisitos](#requisitos)
- [Licença](#licença)

## 🎯 Sobre

O **SDR IA Module** é um plugin modular e não-invasivo para Chatwoot que automatiza a qualificação de leads usando GPT-4. Ele analisa conversas em tempo real, extrai informações-chave e classifica leads automaticamente.

**Características Principais:**
- ✅ **100% Isolado** - Todo código em `/plugins/sdr_ia/`
- ✅ **Não-Invasivo** - Zero modificações no código core do Chatwoot
- ✅ **Reversível** - Pode ser desativado ou removido facilmente
- ✅ **Assíncrono** - Não bloqueia conversas (usa Sidekiq)
- ✅ **Interface Administrativa** - Gerenciamento visual completo

## ✨ Características

### Qualificação Automática
- Extração de informações do lead (nome, interesse, urgência, localização)
- Score de 0-100 baseado em múltiplos critérios
- Classificação por temperatura: Quente, Morno, Frio, Muito Frio
- Análise de comportamento (cooperativo, evasivo, resistente)

### Atribuição Inteligente
- Atribuição automática para times baseada na temperatura
- Aplicação automática de labels/tags
- Recomendação de próximos passos

### Interface Administrativa
- Dashboard com estatísticas em tempo real
- Configuração visual de todos os parâmetros
- Teste manual de qualificação
- Ajuste de thresholds e pesos de scoring

### Integração OpenAI
- Suporte a GPT-4 Turbo, GPT-4 e GPT-3.5
- Prompts personalizáveis via YAML
- Resposta estruturada em JSON

## 🏗️ Arquitetura

```
┌─────────────┐
│   WhatsApp  │
│   Message   │
└──────┬──────┘
       │
       v
┌─────────────────┐
│   Chatwoot      │
│   (Dispatcher)  │
└──────┬──────────┘
       │
       v
┌─────────────────┐
│  SDR IA         │
│  Listener       │
└──────┬──────────┘
       │
       v
┌─────────────────┐
│  Sidekiq Job    │
│  (Async)        │
└──────┬──────────┘
       │
       v
┌─────────────────┐
│  LeadQualifier  │
│  Service        │
└──────┬──────────┘
       │
       v
┌─────────────────┐
│  OpenAI Client  │
│  (GPT-4)        │
└──────┬──────────┘
       │
       v
┌─────────────────┐
│  PostgreSQL     │
│  (Update)       │
└─────────────────┘
```

## 📦 Instalação

### Método 1: Docker Build ⭐ (Recomendado para Produção)

**Método mais profissional e fácil de manter!**

```bash
# 1. Clone o repositório
git clone https://github.com/eversonsantos-dev/chatwoot-sdr-ia.git
cd chatwoot-sdr-ia

# 2. Build da imagem customizada
./rebuild.sh

# 3. Deploy no seu ambiente
./deploy.sh
```

**Pronto! ✅** O processo automaticamente:
- ✅ Cria imagem Docker customizada do Chatwoot
- ✅ Inclui todos os arquivos do módulo SDR IA
- ✅ Compila assets frontend corretamente
- ✅ Atualiza os serviços no Docker Swarm
- ✅ Verifica se o módulo carregou

**Vantagens:**
- 🎯 **Profissional** - Jeito correto para produção
- 🔄 **Persistente** - Sobrevive a restarts
- 📦 **Versionado** - Fácil rollback
- 🚀 **Rápido de atualizar** - Só rebuild e redeploy

**Documentação completa:** [DEPLOY.md](DEPLOY.md)

**Tempo total:** ~10-15 minutos

---

### Método 2: Script Automatizado (Desenvolvimento/Teste)

**Útil para testar rapidamente, mas não recomendado para produção**

```bash
# 1. Clone o repositório
git clone https://github.com/eversonsantos-dev/chatwoot-sdr-ia.git
cd chatwoot-sdr-ia

# 2. Execute o instalador
./install.sh
```

⚠️ **Limitação:** Arquivos são copiados para o container em execução e podem ser perdidos ao reiniciar.

---

### Método 3: Instalação Manual

<details>
<summary>Clique para ver instruções manuais</summary>

#### 1. Copiar Arquivos

```bash
# Copiar plugin para o Chatwoot
docker cp plugins/sdr_ia <CONTAINER_ID>:/app/plugins/

# Copiar controller
docker cp controllers/api/v1/accounts/sdr_ia <CONTAINER_ID>:/app/app/controllers/api/v1/accounts/

# Copiar initializer
docker cp config_initializers_sdr_ia.rb <CONTAINER_ID>:/app/config/initializers/sdr_ia.rb

# Copiar frontend
docker cp frontend/routes/dashboard/settings/sdr-ia <CONTAINER_ID>:/app/app/javascript/dashboard/routes/dashboard/settings/
```

#### 2. Executar Script de Instalação

```bash
docker exec <CONTAINER_ID> bundle exec rails runner /app/plugins/sdr_ia/install.rb
```

Este script cria:
- 16 custom attributes no modelo Contact
- 14 labels para categorização automática

</details>

### 3. Configurar OpenAI API Key

Edite o `chatwoot.yaml` (ou docker-compose.yml):

```yaml
services:
  chatwoot_app:
    environment:
      - OPENAI_API_KEY=sk-proj-SUA_CHAVE_AQUI

  chatwoot_sidekiq:
    environment:
      - OPENAI_API_KEY=sk-proj-SUA_CHAVE_AQUI
```

### 4. Reiniciar Serviços

```bash
docker stack deploy -c chatwoot.yaml chatwoot
# ou
docker-compose up -d
```

## ⚙️ Configuração

### Arquivo Principal: `plugins/sdr_ia/config/settings.yml`

```yaml
sdr_ia:
  enabled: true
  debug_mode: false

  openai:
    model: "gpt-4-turbo-preview"
    max_tokens: 2000
    temperature: 0.3

  scoring:
    weights:
      urgencia:
        esta_semana: 30
        proximas_2_semanas: 25
      conhecimento:
        conhece_valores: 25

  temperature_thresholds:
    quente: 70
    morno: 40
    frio: 20

  teams:
    quente_team_id: null
    morno_team_id: null
```

### Personalizar Prompts: `plugins/sdr_ia/config/prompts.yml`

```yaml
prompts:
  system: |
    Você é um SDR virtual...

  analysis: |
    Analise a conversa e extraia...
```

## 🎨 Interface Administrativa

Acesse via: **Configurações → SDR IA**

### Recursos da Interface

- 📊 **Dashboard**: Estatísticas de leads qualificados
- ⚙️ **Configurações**: Ativar/desativar, escolher modelo OpenAI
- 🌡️ **Thresholds**: Ajustar limites de temperatura
- 👥 **Times**: Configurar atribuição automática
- 🧪 **Testes**: Testar qualificação manual com qualquer contato

## 🔄 Como Funciona

1. **Lead inicia conversa** via WhatsApp
2. **Listener captura evento** `conversation_created`
3. **Status definido** como `em_andamento`
4. **Cada mensagem nova** dispara o evento `message_created`
5. **Job agendado** com delay de 2 segundos (Sidekiq)
6. **LeadQualifier analisa** histórico completo da conversa
7. **OpenAI retorna** análise estruturada em JSON
8. **Contact atualizado** com temperatura, score, e todos os dados
9. **Labels aplicadas** automaticamente
10. **Time atribuído** se temperatura = quente/morno

## 📁 Estrutura do Projeto

```
chatwoot-sdr-ia/
├── plugins/sdr_ia/              # Plugin principal
│   ├── app/
│   │   ├── services/
│   │   │   ├── openai_client.rb
│   │   │   └── lead_qualifier.rb
│   │   ├── jobs/
│   │   │   └── qualify_lead_job.rb
│   │   └── listeners/
│   │       └── sdr_ia_listener.rb
│   ├── config/
│   │   ├── settings.yml
│   │   ├── prompts.yml
│   │   └── routes.rb
│   ├── lib/
│   │   └── sdr_ia.rb
│   └── install.rb
│
├── controllers/                 # Controller da API
│   └── api/v1/accounts/sdr_ia/
│       └── settings_controller.rb
│
├── frontend/                    # Interface Vue.js
│   ├── routes/dashboard/settings/sdr-ia/
│   │   ├── Index.vue
│   │   └── sdr-ia.routes.js
│   └── i18n/                    # Traduções
│
├── docs/                        # Documentação
│   ├── SDR_IA_MODULE_DOCUMENTATION.md
│   ├── SDR_IA_ADMIN_INTERFACE.md
│   └── testar_sdr_ia.sh
│
├── config_initializers_sdr_ia.rb
└── README.md
```

## 📚 Documentação

- [Documentação Completa do Módulo](docs/SDR_IA_MODULE_DOCUMENTATION.md)
- [Guia da Interface Administrativa](docs/SDR_IA_ADMIN_INTERFACE.md)
- [Script de Teste](docs/testar_sdr_ia.sh)

## 🔧 Requisitos

- **Chatwoot**: v4.1.0 ou superior (Core 3.13.0+)
- **Ruby**: 3.3.3
- **Rails**: 7.0.8+
- **PostgreSQL**: 12+
- **Redis**: 6+
- **OpenAI API Key**: Com acesso a GPT-4 ou GPT-3.5

## 🧪 Teste

Execute o script de teste incluído:

```bash
bash docs/testar_sdr_ia.sh
```

O script verifica:
- ✅ Instalação do módulo
- ✅ Status (habilitado/desabilitado)
- ✅ OpenAI API Key configurada
- ✅ Custom attributes criados
- ✅ Labels criadas
- ✅ Teste de qualificação com último contato

## 🔄 Atualização

### Método Docker Build (Recomendado) ⭐

Quando houver uma nova versão disponível no GitHub:

```bash
# No diretório do projeto
cd /root/chatwoot-sdr-ia

# 1. Atualizar código
git pull origin main

# 2. Rebuild da imagem
./rebuild.sh

# 3. Deploy
./deploy.sh
```

**Tempo total:** ~10-15 minutos
**Zero downtime:** Deploy usa rolling update

---

### Método Script (Desenvolvimento)

```bash
# No diretório do projeto
./update.sh
```

⚠️ **Atenção:** Mudanças podem ser perdidas ao reiniciar containers.

---

**Ver detalhes:** [DEPLOY.md](DEPLOY.md#atualização)

## 🗑️ Desinstalação

### Script Automatizado ⭐

Para remover completamente o módulo:

```bash
./uninstall.sh
```

O script irá:
- Fazer backup final
- Remover todos os arquivos do módulo
- Limpar configurações e menu
- Remover custom attributes e labels
- Reverter modificações no Chatwoot

**ATENÇÃO:** Digite `REMOVER` para confirmar.

**Opções:**
```bash
./uninstall.sh --help                  # Ver opções
./uninstall.sh --keep-data             # Manter custom attributes e labels
./uninstall.sh --force                 # Não pedir confirmação
```

### Desativar Temporariamente

Se quiser apenas desabilitar sem remover:

Edite `settings.yml`:

```yaml
sdr_ia:
  enabled: false
```

E reinicie os serviços.

## 🐛 Troubleshooting

### Logs do Módulo

```bash
docker service logs chatwoot_chatwoot_app -f | grep "SDR IA"
docker service logs chatwoot_chatwoot_sidekiq -f | grep "SDR IA"
```

### Padrões de Log

```
[SDR IA] Nova conversa detectada: conversation_id=123
[SDR IA] Nova mensagem incoming: contact_id=456
[SDR IA Job] Processando contact_id=456
[SDR IA] Qualificação concluída: quente - Score: 85
```

### Problemas Comuns

| Problema | Solução |
|----------|---------|
| Módulo não aparece no menu | Hard refresh (Ctrl+Shift+R) |
| Erro 500 na API | Verificar se OpenAI API Key está configurada |
| Jobs não executam | Verificar se Sidekiq está rodando |
| Labels não aplicam | Verificar se labels foram criadas pelo install.rb |

## 📈 Performance

- **Custo por lead**: ~$0.02 - $0.05 (OpenAI GPT-4 Turbo)
- **Tempo de processamento**: 2-5 segundos por qualificação
- **Async**: Não bloqueia UI ou conversa

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👤 Autor

**Everson Santos**
- GitHub: [@eversonsantos-dev](https://github.com/eversonsantos-dev)

## 🙏 Agradecimentos

- [Chatwoot](https://www.chatwoot.com/) - Plataforma de atendimento open-source
- [OpenAI](https://openai.com/) - API GPT-4 para análise de conversas
- Comunidade Ruby on Rails

---

**Desenvolvido com ❤️ para automatizar qualificação de leads**
