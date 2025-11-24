# ÍNDICE COMPLETO - Chatwoot SDR IA

**Data:** 22 de Novembro de 2025
**Versão:** v2.0.0-patch2 (aa4bd4f) - ✅ ESTÁVEL
**Status:** 🟢 Sistema Operacional

---

## 📋 NAVEGAÇÃO RÁPIDA

### 🎯 Para Iniciar
- [Visão Geral do Projeto](#visão-geral-do-projeto)
- [Estado Atual](#estado-atual)
- [Como Usar Este Índice](#como-usar-este-índice)

### 👨‍💻 Para Desenvolvedores
- [Documentação Técnica](#documentação-técnica)
- [Guias de Desenvolvimento](#guias-de-desenvolvimento)
- [Scripts e Ferramentas](#scripts-e-ferramentas)

### 📊 Para Gerentes de Projeto
- [Planejamento](#planejamento)
- [Histórico de Versões](#histórico-de-versões)
- [Métricas e Relatórios](#métricas-e-relatórios)

### 🆘 Resolução de Problemas
- [Troubleshooting](#troubleshooting)
- [Backups e Restauração](#backups-e-restauração)

---

## 🎯 VISÃO GERAL DO PROJETO

### O Que É
Sistema de qualificação automática de leads integrado ao Chatwoot, usando GPT-4 para:
- Conversar naturalmente com leads via WhatsApp
- Coletar 5 informações obrigatórias de forma conversacional
- Qualificar leads automaticamente (Quente/Morno/Frio/Muito Frio)
- Distribuir leads qualificados para times especializados
- Reduzir workload do time comercial em até 80%

### Tecnologias
- **Backend:** Ruby on Rails 7.0.8 + Chatwoot v4.1.0
- **Frontend:** Vue.js 3 + Vite
- **IA:** OpenAI GPT-4 Turbo
- **Infraestrutura:** Docker Swarm
- **Database:** PostgreSQL 15
- **WhatsApp:** Integração via WAHA

---

## 📊 ESTADO ATUAL

### Versão em Produção
**v2.0.0-patch2 (commit: aa4bd4f)**

### Status dos Componentes
| Componente | Status | Observação |
|-----------|--------|------------|
| **Conversação IA** | 🟢 Operacional | GPT-4 Turbo funcionando |
| **Qualificação Automática** | 🟢 Operacional | Scoring 0-130 pontos |
| **Distribuição para Times** | 🟢 Operacional | Quente→Close, Morno→Followup |
| **Painel Administrativo** | 🟢 Operacional | Todas as configurações acessíveis |
| **API Endpoints** | 🟢 Operacional | 100% de uptime |
| **Integração WhatsApp** | 🟢 Operacional | WAHA webhooks ativos |

### Problemas Conhecidos
| Problema | Severidade | Status |
|----------|-----------|--------|
| Mensagens duplicadas para leads mornos | Média | ⚠️ Correção planejada (v2.1.0) |
| Assets precisam cópia manual às vezes | Baixa | ⚠️ Workaround disponível |

### Última Sessão
**22/11/2025 (17:00 - 21:06)**
- Tentativa de implementar patches 3-5
- Problema crítico no painel administrativo
- Rollback para versão estável
- Sistema restaurado com sucesso

---

## 📚 DOCUMENTAÇÃO TÉCNICA

### Documentos Principais

#### 1. README.md (Raiz do Projeto)
**Localização:** `/root/chatwoot-sdr-ia/README.md`
**O que é:** Visão geral do projeto e quick start
**Quando consultar:** Primeira vez que acessa o projeto

#### 2. SDR_IA_MODULE_DOCUMENTATION.md
**Localização:** `/root/chatwoot-sdr-ia/docs/SDR_IA_MODULE_DOCUMENTATION.md`
**O que é:** Documentação técnica completa do módulo
**Conteúdo:**
- Arquitetura do sistema
- Fluxo de qualificação
- Estrutura de arquivos
- APIs e integrações
- Configurações

**Quando consultar:**
- Desenvolver nova feature
- Entender código existente
- Debugar problemas técnicos

#### 3. SDR_IA_ADMIN_INTERFACE.md
**Localização:** `/root/chatwoot-sdr-ia/docs/SDR_IA_ADMIN_INTERFACE.md`
**O que é:** Guia completo do painel administrativo
**Conteúdo:**
- Como acessar o painel
- Explicação de cada configuração
- Melhores práticas
- Screenshots

**Quando consultar:**
- Configurar sistema pela primeira vez
- Treinar novos usuários
- Ajustar parâmetros de qualificação

#### 4. TROUBLESHOOTING.md
**Localização:** `/root/chatwoot-sdr-ia/docs/TROUBLESHOOTING.md`
**O que é:** Guia de solução de problemas
**Conteúdo:**
- Problemas comuns e soluções
- Como interpretar logs
- Comandos úteis
- Quando fazer rollback

**Quando consultar:**
- Sistema apresentando erro
- Comportamento inesperado
- Após deploy com problemas

---

## 🗺️ PLANEJAMENTO

### Roadmap Completo
**Localização:** `/root/chatwoot-sdr-ia/docs/PLANO_DESENVOLVIMENTO.md`

**Conteúdo:**
- Visão geral do projeto
- Arquitetura atual
- Roadmap de funcionalidades (v2.1.0 → v3.0.0)
- Pendências técnicas priorizadas
- Melhorias de infraestrutura
- Cronograma detalhado
- Riscos e mitigações
- Stack tecnológico completo
- KPIs e métricas de sucesso

**Próximas Versões Planejadas:**

| Versão | Foco | Prazo Estimado |
|--------|------|----------------|
| **v2.1.0** | Correções e Estabilização | 1-2 semanas |
| **v2.2.0** | Analytics e Relatórios | 3-4 semanas |
| **v2.3.0** | Otimizações de IA | 2-3 semanas |
| **v3.0.0** | Automações Avançadas | 2-3 meses |

---

## 📖 HISTÓRICO DE VERSÕES

### CHANGELOG.md
**Localização:** `/root/chatwoot-sdr-ia/CHANGELOG.md`

**Versões Documentadas:**
- v2.0.0 - Base de Conhecimento + Automações Avançadas
- v2.0.0-patch1 - Qualificação automática em handoff
- v2.0.0-patch2 - Mensagem de fechamento atualizada (ATUAL)
- v2.0.0-patch3 - Correção mensagens duplicadas (REVERTIDO)
- v2.0.0-patch4 - Skip closing message leads quentes (REVERTIDO)
- v2.0.0-patch5 - Limpeza de cache Vite (REVERTIDO)
- v1.2.0 - Melhorias de UX
- v1.1.0 - Primeiro release estável
- v1.0.0 - MVP inicial

### Notas de Release
**Localização:** `/root/chatwoot-sdr-ia/`

Arquivos:
- `RELEASE_NOTES_v2.0.0.md` - Release atual
- `RELEASE_NOTES_v2.0.0-patch1.md`
- `RELEASE_NOTES_v1.2.0.md`
- `RELEASE_NOTES_v1.1.2.md`
- `RELEASE_NOTES_v1.1.0.md`
- `RELEASE_NOTES_v1.0.0.md`

---

## 📊 SESSÕES DE DESENVOLVIMENTO

### Relatórios de Sessões
**Localização:** `/root/chatwoot-sdr-ia/docs/sessoes/`

#### SESSAO_2025-11-22.md
**Data:** 22 de Novembro de 2025 (17:00 - 21:06)
**Duração:** 4h 06min

**Resumo:**
- Implementação de 3 patches (correção mensagens duplicadas)
- Problema crítico no painel administrativo
- Análise detalhada de logs
- Rollback para versão estável
- Sistema restaurado com sucesso

**Commits:**
- `def2a5b` - Patch3 (REVERTIDO)
- `2e7b8a9` - Patch4 (REVERTIDO)
- `9207219` - Patch5 (REVERTIDO)
- Rollback para `aa4bd4f` ✅

**Aprendizados:**
- Necessidade de ambiente de staging
- Testar patches isoladamente
- Importância de backups

---

## 🔧 PATCHES

### Documentação Detalhada
**Localização:** `/root/chatwoot-sdr-ia/docs/patches/`

#### PATCH_v2.0.0-patch3.md (REVERTIDO)
**Problema:** Mensagens duplicadas para leads mornos
**Solução Tentada:** Não enviar resposta conversacional se for handoff
**Status:** ❌ Revertido (causou problema no painel)
**Documentação:** 333 linhas

#### PATCH_v2.0.0-patch4.md (REVERTIDO)
**Problema:** Mensagem redundante para leads quentes
**Solução Tentada:** Skip `send_closing_message()` para temperatura='quente'
**Status:** ❌ Revertido (conjunto de patches incompatível)
**Documentação:** 456 linhas

---

## 🛠️ GUIAS DE DESENVOLVIMENTO

### Como Desenvolver Nova Feature

1. **Planejamento**
   - Adicionar feature no `PLANO_DESENVOLVIMENTO.md`
   - Discutir com time
   - Estimar esforço

2. **Preparação**
   - Fazer backup da versão atual:
     ```bash
     ./scripts/backup-version.sh [TAG] "[descrição]"
     ```
   - Criar branch git:
     ```bash
     git checkout -b feature/[nome-da-feature]
     ```

3. **Desenvolvimento**
   - Ler documentação técnica relevante
   - Implementar mudanças
   - Testar localmente (quando staging disponível)

4. **Documentação**
   - Atualizar `CHANGELOG.md`
   - Criar patch doc se aplicável (em `docs/patches/`)
   - Atualizar docs técnicos se necessário

5. **Deploy**
   - Fazer backup antes do deploy
   - Deploy gradual (1 container primeiro)
   - Monitorar logs por 24h
   - Se estável, deploy completo

6. **Pós-Deploy**
   - Criar relatório de sessão (em `docs/sessoes/`)
   - Atualizar `PLANO_DESENVOLVIMENTO.md` se necessário
   - Criar tag de versão

### Como Aplicar um Patch

1. **Leitura**
   - Ler documentação do patch em `docs/patches/`
   - Entender problema e solução
   - Verificar compatibilidade

2. **Backup**
   ```bash
   ./scripts/backup-version.sh $(git describe --tags) "Antes do patch X"
   ```

3. **Aplicação**
   - Aplicar mudanças manualmente
   - OU `git cherry-pick [COMMIT]` se disponível

4. **Teste**
   - Testar em staging (quando disponível)
   - Validar funcionalidade
   - Verificar sem efeitos colaterais

5. **Deploy**
   - Build: `./rebuild.sh`
   - Deploy: `./deploy.sh`
   - Monitorar logs

6. **Rollback (se necessário)**
   ```bash
   docker service update --image localhost/chatwoot-sdr-ia:[VERSAO_ANTERIOR] chatwoot_chatwoot_app
   docker service update --image localhost/chatwoot-sdr-ia:[VERSAO_ANTERIOR] chatwoot_chatwoot_sidekiq
   ```

---

## 🔧 SCRIPTS E FERRAMENTAS

### Scripts Disponíveis
**Localização:** `/root/chatwoot-sdr-ia/` e `/root/chatwoot-sdr-ia/scripts/`

#### rebuild.sh
**O que faz:** Reconstrói a imagem Docker com código atual
**Uso:**
```bash
./rebuild.sh
```
**Quando usar:** Após modificar código

#### deploy.sh
**O que faz:** Faz deploy da imagem no Docker Swarm
**Uso:**
```bash
./deploy.sh
```
**Quando usar:** Após rebuild bem-sucedido

#### backup-version.sh (NOVO)
**O que faz:** Cria backup completo de uma versão
**Uso:**
```bash
./scripts/backup-version.sh [TAG] "[descrição]"

# Exemplo:
./scripts/backup-version.sh aa4bd4f "Versão estável antes de mudanças"
```
**O que inclui:**
- Código fonte (tar.gz)
- Imagem Docker (tar.gz)
- Manifest JSON com metadados
- README de restauração

**Localização dos Backups:**
`/root/chatwoot-sdr-ia/docs/backups/[TAG]/`

---

## 💾 BACKUPS E RESTAURAÇÃO

### Backups Disponíveis
**Localização:** `/root/chatwoot-sdr-ia/docs/backups/`

#### aa4bd4f (v2.0.0-patch2) - VERSÃO ESTÁVEL ✅
**Criado:** 22/11/2025 21:20:36
**Tamanho:** 850MB
**Descrição:** Versão estável antes dos patches 3-5

**Arquivos:**
- `backup_20251122_212036.tar.gz` (114KB - código)
- `docker_image_20251122_212036.tar.gz` (850MB - imagem)
- `manifest_20251122_212036.json` (metadados)
- `README.md` (instruções de restauração)

**Como Restaurar:**
```bash
# 1. Extrair código (se necessário)
tar -xzf backup_20251122_212036.tar.gz -C /root/chatwoot-sdr-ia

# 2. Carregar imagem Docker
cd /root/chatwoot-sdr-ia/docs/backups/aa4bd4f
gunzip -c docker_image_20251122_212036.tar.gz | docker load

# 3. Atualizar services
docker service update --image localhost/chatwoot-sdr-ia:aa4bd4f chatwoot_chatwoot_app
docker service update --image localhost/chatwoot-sdr-ia:aa4bd4f chatwoot_chatwoot_sidekiq

# 4. Verificar
docker service ps chatwoot_chatwoot_app
docker service ps chatwoot_chatwoot_sidekiq
```

**Ver instruções completas:**
`/root/chatwoot-sdr-ia/docs/backups/aa4bd4f/README.md`

---

## 🆘 TROUBLESHOOTING

### Problemas Comuns

#### 1. Painel Administrativo Branco
**Sintoma:** Tela branca em `/app/accounts/1/settings/sdr-ia`

**Possíveis Causas:**
- Assets desatualizados
- API travando
- Erro JavaScript

**Solução:**
1. Verificar logs:
   ```bash
   docker service logs chatwoot_chatwoot_app --tail 50
   ```

2. Testar API:
   ```bash
   curl https://chatteste.nexusatemporal.com/api/v1/accounts/1/sdr_ia/settings
   ```

3. Se não funcionar, fazer rollback:
   ```bash
   docker service update --image localhost/chatwoot-sdr-ia:aa4bd4f chatwoot_chatwoot_app
   ```

#### 2. Mensagens Duplicadas
**Sintoma:** Lead recebe 2 mensagens idênticas

**Status:** ⚠️ Bug conhecido (correção planejada v2.1.0)

**Workaround:** Não há workaround no momento

**Impacto:** Médio (UX degradada, mas sistema funcional)

#### 3. Assets Não Atualizando
**Sintoma:** Frontend mostra código antigo após rebuild

**Solução:**
```bash
# Copiar assets da imagem para volume
docker run --rm -v chatwoot_public:/target localhost/chatwoot-sdr-ia:latest \
  sh -c "rm -rf /target/vite/* && cp -r /app/public/vite/* /target/vite/"

# Reiniciar app
docker service update --force chatwoot_chatwoot_app
```

### Comandos Úteis

#### Ver Logs
```bash
# App
docker service logs chatwoot_chatwoot_app --tail 100 --follow

# Sidekiq
docker service logs chatwoot_chatwoot_sidekiq --tail 100 --follow

# Filtrar por SDR IA
docker service logs chatwoot_chatwoot_sidekiq | grep "SDR IA"
```

#### Verificar Containers
```bash
# Listar services
docker service ls

# Ver status detalhado
docker service ps chatwoot_chatwoot_app
docker service ps chatwoot_chatwoot_sidekiq

# Ver imagem em uso
docker ps --filter "name=chatwoot" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
```

#### Testar Endpoints
```bash
# Health check
curl https://chatteste.nexusatemporal.com/health

# SDR IA Settings
curl https://chatteste.nexusatemporal.com/api/v1/accounts/1/sdr_ia/settings

# SDR IA Stats
curl https://chatteste.nexusatemporal.com/api/v1/accounts/1/sdr_ia/stats
```

---

## 📞 INFORMAÇÕES DE CONTATO

### Time
- **Product Owner:** Everson Santos
- **Desenvolvedor:** Claude (Anthropic AI)
- **QA:** Everson Santos

### URLs Importantes
- **Produção:** https://chatteste.nexusatemporal.com
- **Painel SDR IA:** https://chatteste.nexusatemporal.com/app/accounts/1/settings/sdr-ia
- **API Base:** https://chatteste.nexusatemporal.com/api/v1/accounts/1/sdr_ia/

### Recursos
- **Documentação:** `/root/chatwoot-sdr-ia/docs/`
- **Backups:** `/root/chatwoot-sdr-ia/docs/backups/`
- **Scripts:** `/root/chatwoot-sdr-ia/scripts/`

---

## 📝 CHECKLIST DE FINALIZAÇÃO DE SESSÃO

Ao finalizar uma sessão de desenvolvimento, certifique-se de:

- [ ] Criar relatório em `docs/sessoes/SESSAO_[DATA].md`
- [ ] Atualizar `CHANGELOG.md`
- [ ] Documentar patches em `docs/patches/` (se aplicável)
- [ ] Fazer backup da versão estável
- [ ] Atualizar `PLANO_DESENVOLVIMENTO.md` se necessário
- [ ] Atualizar este INDICE_COMPLETO.md
- [ ] Verificar que sistema está estável
- [ ] Commit e push de toda documentação

---

## 🎯 QUICK REFERENCE

### Comandos Essenciais
```bash
# Ver versão atual
git describe --tags

# Fazer backup
./scripts/backup-version.sh [TAG] "[descrição]"

# Rebuild
./rebuild.sh

# Deploy
./deploy.sh

# Ver logs
docker service logs chatwoot_chatwoot_app --tail 50

# Rollback
docker service update --image localhost/chatwoot-sdr-ia:[TAG] chatwoot_chatwoot_app
docker service update --image localhost/chatwoot-sdr-ia:[TAG] chatwoot_chatwoot_sidekiq
```

### Arquivos Mais Importantes
1. `docs/PLANO_DESENVOLVIMENTO.md` - Roadmap completo
2. `docs/SDR_IA_MODULE_DOCUMENTATION.md` - Docs técnicas
3. `docs/TROUBLESHOOTING.md` - Solução de problemas
4. `CHANGELOG.md` - Histórico de versões
5. `docs/sessoes/SESSAO_*.md` - Relatórios de sessões

---

**FIM DO ÍNDICE COMPLETO**

*Este documento é o ponto de partida para navegar toda a documentação do projeto.*

*Última atualização: 22 de Novembro de 2025, 21:30h*
*Versão do Índice: 1.0*
