# 📚 Guias de Instalação e Deploy

Este projeto possui múltiplos guias para diferentes cenários. Escolha o guia apropriado para sua situação:

---

## 🎯 Qual Guia Usar?

### 1. 🆕 INSTALL-PRODUCTION.md

**Use quando**: Você tem um **Chatwoot JÁ EM PRODUÇÃO** e quer adicionar o SDR IA

**Características**:
- ✅ Zero downtime
- ✅ Backup antes de começar
- ✅ Rollback rápido
- ✅ Passo a passo detalhado
- ✅ Troubleshooting extensivo

**Tempo**: 30-45 minutos

**Link**: [INSTALL-PRODUCTION.md](INSTALL-PRODUCTION.md)

---

### 2. 🚀 DEPLOY.md

**Use quando**: Você está fazendo **deploy inicial** do Chatwoot COM SDR IA

**Características**:
- Build da imagem
- Deploy no Docker Swarm
- Configuração inicial
- Scripts automatizados

**Tempo**: 20-30 minutos

**Link**: [DEPLOY.md](DEPLOY.md)

---

### 3. 📖 README.md

**Use quando**: Você quer **entender o projeto** antes de instalar

**Conteúdo**:
- Visão geral do SDR IA
- Funcionalidades
- Arquitetura
- Requisitos
- Links para outros guias

**Link**: [README.md](README.md)

---

## 🗺️ Fluxo Recomendado

### Cenário A: Chatwoot Novo (Primeira Instalação)

```
1. Leia README.md (entender o projeto)
   ↓
2. Siga DEPLOY.md (instalação completa)
   ↓
3. Configure via interface web
   ↓
4. Teste com alguns leads
```

### Cenário B: Chatwoot em Produção (Adicionar SDR IA)

```
1. Leia README.md (entender o projeto)
   ↓
2. Siga INSTALL-PRODUCTION.md (instalação segura)
   ↓
3. Verifique todos os testes
   ↓
4. Configure via interface web
   ↓
5. Ative gradualmente
```

### Cenário C: Atualização do SDR IA (Já Instalado)

```
1. Leia CHANGELOG.md (ver mudanças)
   ↓
2. Faça backup (ver INSTALL-PRODUCTION.md seção 1)
   ↓
3. git pull origin main
   ↓
4. ./rebuild.sh
   ↓
5. docker service update (ver DEPLOY.md)
```

---

## 📄 Documentação Adicional

### Backups

- **README-v1.1.2-BACKUP.md**: Guia completo de restore do backup v1.1.2
- **RESTORE-INSTRUCTIONS.txt**: Instruções rápidas de restore
- **VERSION-HISTORY.md**: Histórico de todas as versões

**Localização**: `/root/backups/` (após criar backup)

### Desenvolvimento

- **docs/**: Documentação técnica detalhada
- **CHANGELOG.md**: Histórico de mudanças
- **CONTRIBUTING.md**: Como contribuir (se existir)

---

## ⚡ Quick Start

### Instalação Rápida (Chatwoot Novo)

```bash
cd /root
git clone https://github.com/eversonsantos-dev/chatwoot-sdr-ia.git
cd chatwoot-sdr-ia
git checkout v1.1.2
docker build -t localhost/chatwoot-sdr-ia:v1.1.2 .
# Seguir DEPLOY.md para deploy
```

### Instalação Segura (Produção)

```bash
cd /root
git clone https://github.com/eversonsantos-dev/chatwoot-sdr-ia.git
cd chatwoot-sdr-ia
git checkout v1.1.2
# Seguir INSTALL-PRODUCTION.md passo a passo
```

---

## 🆘 Quando Algo Dá Errado

### 1. Consulte Troubleshooting

- **INSTALL-PRODUCTION.md**: Seção "Troubleshooting"
- **DEPLOY.md**: Seção "Troubleshooting"

### 2. Verifique Logs

```bash
# Logs do SDR IA
docker service logs -f chatwoot_chatwoot_sidekiq | grep "\[SDR IA\]"

# Logs gerais
docker service logs --tail 100 chatwoot_chatwoot_app
```

### 3. Rollback

- **INSTALL-PRODUCTION.md**: Seção "Rollback"
- **Backup disponível**: `/root/backups/`

### 4. Peça Ajuda

- **GitHub Issues**: https://github.com/eversonsantos-dev/chatwoot-sdr-ia/issues
- **Inclua**: Logs, versão, passos executados

---

## 📊 Comparação dos Guias

| Aspecto | README.md | DEPLOY.md | INSTALL-PRODUCTION.md |
|---------|-----------|-----------|----------------------|
| **Objetivo** | Visão geral | Deploy inicial | Adicionar em produção |
| **Público** | Todos | DevOps | SysAdmin |
| **Pré-requisitos** | Nenhum | Servidor vazio | Chatwoot rodando |
| **Downtime** | N/A | Sim (inicial) | Não (zero downtime) |
| **Rollback** | N/A | Não aplicável | Sim (2 min) |
| **Backup** | N/A | Não | Sim (obrigatório) |
| **Tempo** | 10 min leitura | 20-30 min | 30-45 min |
| **Detalhamento** | Alto nível | Médio | Muito detalhado |
| **Troubleshooting** | Básico | Médio | Extensivo |

---

## 🎯 Recomendações por Experiência

### Iniciante (Primeira vez com Docker/Chatwoot)

1. Leia **README.md** completo
2. Assista vídeos de Docker básico (se necessário)
3. Siga **DEPLOY.md** em ambiente de teste primeiro
4. Depois aplique **INSTALL-PRODUCTION.md** em produção

### Intermediário (Conhece Docker)

1. Leia **README.md** (seções principais)
2. Siga **DEPLOY.md** OU **INSTALL-PRODUCTION.md** (conforme caso)
3. Consulte troubleshooting se necessário

### Avançado (SysAdmin/DevOps)

1. Quick scan do **README.md**
2. Escolha o guia apropriado
3. Execute com confiança
4. Rollback disponível se necessário

---

## 🔄 Ciclo de Vida

```
Instalação (DEPLOY.md ou INSTALL-PRODUCTION.md)
    ↓
Configuração (Interface Web)
    ↓
Uso em Produção (Monitoramento)
    ↓
Atualização (git pull + rebuild + deploy)
    ↓
Rollback (se necessário) via INSTALL-PRODUCTION.md
```

---

## 💡 Dicas

### Antes de Instalar

- ✅ Leia o guia completo primeiro
- ✅ Verifique pré-requisitos
- ✅ Faça backup (produção)
- ✅ Reserve tempo suficiente

### Durante Instalação

- ✅ Siga os passos na ordem
- ✅ Não pule verificações
- ✅ Copie/cole comandos cuidadosamente
- ✅ Verifique logs após cada etapa

### Após Instalação

- ✅ Teste todas as funcionalidades
- ✅ Configure alertas/monitoramento
- ✅ Documente customizações
- ✅ Mantenha backup atualizado

---

## 📞 Suporte

Se você seguiu o guia correto para seu cenário e ainda tem problemas:

1. **Verifique**: Troubleshooting do guia
2. **Colete**: Logs e informações do sistema
3. **Abra**: Issue no GitHub com todos os detalhes
4. **Inclua**: Qual guia seguiu, em qual passo parou, logs relevantes

---

**Última atualização**: 20/11/2025  
**Versão**: 1.0  
**Baseado em**: SDR IA v1.1.2
