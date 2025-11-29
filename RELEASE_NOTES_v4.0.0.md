# Release v4.0.0 - Multi-Tenant SaaS Licensing System

## Highlights

Esta é uma **major release** que transforma o módulo SDR IA em uma solução **SaaS multi-tenant** completa, permitindo que você gerencie múltiplos clientes com controle individual de licenças, limites de uso e features.

## Novas Funcionalidades

### Sistema de Licenciamento SaaS

| Plano | Leads/Mês | Modelos OpenAI | Features Incluídas |
|-------|-----------|----------------|-------------------|
| **Trial** | 50 | GPT-3.5 | Básico (14 dias) |
| **Basic** | 200 | GPT-3.5, GPT-4 | + Prompts customizados |
| **Pro** | 1.000 | GPT-3.5, GPT-4, GPT-4-Turbo | + API + Base de Conhecimento + Round Robin |
| **Enterprise** | Ilimitado | Todos | Tudo + Suporte dedicado |

### Dashboard Super Admin

Nova interface para gerenciamento completo de licenças:

- Listar todas as licenças com filtros
- Criar trials para novas contas
- Upgrade/Downgrade de planos
- Suspender/Reativar licenças
- Resetar contadores de uso
- Estender períodos de trial
- Estatísticas globais de uso

### Compatibilidade Dinâmica com Chatwoot

- **Dockerfile.latest**: Sempre usa a última versão do Chatwoot
- Suporte via `--build-arg CHATWOOT_VERSION=v4.x.x`
- Script de injeção automática de rotas
- Atualizado para **Chatwoot v4.8.0**

## Arquivos Novos

```
db/migrate/20251129000001_create_sdr_ia_licenses.rb
models/sdr_ia_license.rb
plugins/sdr_ia/app/services/license_validator.rb
super_admin/dashboards/sdr_ia_license_dashboard.rb
super_admin/controllers/sdr_ia_licenses_controller.rb
super_admin/views/sdr_ia_licenses/_actions.html.erb
super_admin/views/sdr_ia_licenses/stats.html.erb
scripts/inject_routes.rb
Dockerfile.latest
build-and-push.sh
```

## Novos Endpoints API

### Para Clientes
```
GET /api/v1/accounts/:id/sdr_ia/license  # Informações da licença
```

### Para Super Admin
```
GET    /super_admin/sdr_ia_licenses           # Listar licenças
POST   /super_admin/sdr_ia_licenses           # Criar licença
GET    /super_admin/sdr_ia_licenses/stats     # Estatísticas
POST   /super_admin/sdr_ia_licenses/:id/suspend      # Suspender
POST   /super_admin/sdr_ia_licenses/:id/reactivate   # Reativar
POST   /super_admin/sdr_ia_licenses/:id/upgrade      # Upgrade
POST   /super_admin/sdr_ia_licenses/:id/extend_trial # Estender trial
POST   /super_admin/sdr_ia_licenses/:id/reset_usage  # Resetar uso
```

## Docker

### Nova Imagem
```bash
# Imagem que sempre usa última versão do Chatwoot
docker pull eversonsantosdev/chatwoot-sdr-ia-latest
```

### Build Manual
```bash
# Com versão padrão (v4.8.0)
docker build -f Dockerfile.latest -t eversonsantosdev/chatwoot-sdr-ia-latest .

# Com versão específica
docker build -f Dockerfile.latest \
  --build-arg CHATWOOT_VERSION=v4.8.0 \
  -t eversonsantosdev/chatwoot-sdr-ia-latest .
```

## Breaking Changes

- **Licença Obrigatória**: Accounts agora precisam de uma licença para usar o SDR IA
- **Nova Migration**: Tabela `sdr_ia_licenses` é obrigatória
- **Validação de Features**: Features como Round Robin e Base de Conhecimento são controladas pelo plano

## Guia de Upgrade

### De versões anteriores (< v4.0.0):

1. **Backup do Banco**
```bash
docker exec <postgres_container> pg_dump -U postgres chatwoot_production > backup.sql
```

2. **Atualizar Imagem**
```bash
docker pull eversonsantosdev/chatwoot-sdr-ia-latest:4.0.0
```

3. **Executar Migrations**
```bash
docker exec <chatwoot_app> bundle exec rails db:migrate
```

4. **Criar Licenças para Contas Existentes**
   - Acesse Super Admin > SDR IA Licenses
   - Use "Criar Trial" para cada conta ou
   - Use "Bulk Create Trials" para todas

## Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `SDR_IA_SKIP_LICENSE_CHECK` | Desabilita validação de licença (dev) | `false` |

## Stack de Deploy Atualizada

```yaml
services:
  chatwoot_app:
    image: eversonsantosdev/chatwoot-sdr-ia-latest:4.0.0
    # ... resto da configuração

  chatwoot_sidekiq:
    image: eversonsantosdev/chatwoot-sdr-ia-latest:4.0.0
    # ... resto da configuração
```

## Suporte

- GitHub Issues: https://github.com/eversonsantos-dev/chatwoot-sdr-ia/issues
- Documentação: Ver CHANGELOG.md

---

**Desenvolvido por Everson Santos** (@eversonsantos-dev)
