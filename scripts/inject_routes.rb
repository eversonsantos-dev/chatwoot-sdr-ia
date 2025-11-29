#!/usr/bin/env ruby
# frozen_string_literal: true

# ============================================================
# Script de Injeção Dinâmica de Rotas SDR IA
# ============================================================
# Este script adiciona as rotas do SDR IA ao routes.rb do Chatwoot
# de forma dinâmica, sem sobrescrever o arquivo original.
# Funciona com qualquer versão do Chatwoot.
# ============================================================

require 'fileutils'

ROUTES_FILE = Rails.root.join('config/routes.rb')
BACKUP_FILE = Rails.root.join('config/routes.rb.backup')
MARKER = '# SDR_IA_ROUTES_INJECTED'

# Rotas do SDR IA a serem injetadas
SDR_IA_ROUTES = <<~ROUTES
          # SDR IA - Qualificação Automática de Leads (SaaS Multi-tenant)
          # #{MARKER}
          namespace :sdr_ia do
            get 'settings', to: 'settings#show'
            put 'settings', to: 'settings#update'
            post 'test', to: 'settings#test_qualification'
            get 'stats', to: 'settings#stats'
            get 'teams', to: 'settings#teams'
            get 'license', to: 'settings#license_info'
          end
ROUTES

# Rotas do Super Admin para gerenciar licenças
SUPER_ADMIN_ROUTES = <<~ROUTES
      # SDR IA License Management
      # #{MARKER}
      resources :sdr_ia_licenses do
        member do
          post :suspend
          post :reactivate
          post :extend_trial
          post :reset_usage
          post :upgrade
        end
        collection do
          get :stats
          get :accounts_without_license
          post :create_trial
          post :bulk_create_trials
          post :expire_trials
          post :reset_all_usage
        end
      end
ROUTES

def log(message)
  puts "[SDR IA Routes] #{message}"
end

def routes_already_injected?
  content = File.read(ROUTES_FILE)
  content.include?(MARKER)
end

def find_injection_point(content, pattern)
  lines = content.lines
  lines.each_with_index do |line, index|
    return index if line.match?(pattern)
  end
  nil
end

def inject_routes!
  log "Verificando rotas em #{ROUTES_FILE}..."

  unless File.exist?(ROUTES_FILE)
    log "ERRO: Arquivo routes.rb não encontrado!"
    return false
  end

  if routes_already_injected?
    log "Rotas SDR IA já estão injetadas. Pulando..."
    return true
  end

  # Fazer backup
  FileUtils.cp(ROUTES_FILE, BACKUP_FILE)
  log "Backup criado em #{BACKUP_FILE}"

  content = File.read(ROUTES_FILE)
  lines = content.lines

  # Encontrar ponto de injeção para rotas da API (após namespace :integrations dentro de accounts)
  # Procuramos por "resources :working_hours" que geralmente vem depois do namespace :integrations
  api_injection_point = nil
  in_accounts_block = false
  in_scope_module = false

  lines.each_with_index do |line, index|
    # Detectar início do bloco de accounts com scope module
    if line.include?('scope module: :accounts do')
      in_scope_module = true
    end

    # Detectar resources :working_hours dentro do escopo correto
    if in_scope_module && line.include?('resources :working_hours')
      api_injection_point = index
      break
    end
  end

  # Encontrar ponto de injeção para rotas do Super Admin
  super_admin_injection_point = nil
  in_super_admin = false

  lines.each_with_index do |line, index|
    if line.include?('namespace :super_admin do')
      in_super_admin = true
    end

    # Inserir antes de 'resources :account_users' ou no final do namespace super_admin
    if in_super_admin && line.include?('resources :account_users')
      super_admin_injection_point = index
      break
    end
  end

  # Injetar rotas da API
  if api_injection_point
    log "Injetando rotas da API na linha #{api_injection_point}..."
    lines.insert(api_injection_point, "\n#{SDR_IA_ROUTES}\n")
  else
    log "AVISO: Não foi possível encontrar ponto de injeção para rotas da API"
    log "As rotas precisarão ser adicionadas manualmente"
  end

  # Recalcular posição após primeira injeção
  if super_admin_injection_point && api_injection_point
    super_admin_injection_point += SDR_IA_ROUTES.lines.count + 2
  end

  # Injetar rotas do Super Admin
  if super_admin_injection_point
    log "Injetando rotas do Super Admin na linha #{super_admin_injection_point}..."
    lines.insert(super_admin_injection_point, "\n#{SUPER_ADMIN_ROUTES}\n")
  else
    log "AVISO: Não foi possível encontrar ponto de injeção para rotas do Super Admin"
  end

  # Salvar arquivo atualizado
  File.write(ROUTES_FILE, lines.join)
  log "Rotas injetadas com sucesso!"

  true
rescue StandardError => e
  log "ERRO ao injetar rotas: #{e.message}"
  log e.backtrace.first(5).join("\n")

  # Restaurar backup em caso de erro
  if File.exist?(BACKUP_FILE)
    FileUtils.cp(BACKUP_FILE, ROUTES_FILE)
    log "Backup restaurado devido a erro"
  end

  false
end

def verify_routes!
  log "Verificando se rotas foram carregadas corretamente..."

  begin
    Rails.application.reload_routes!

    # Verificar se rotas do SDR IA existem
    routes = Rails.application.routes.routes
    sdr_ia_routes = routes.select { |r| r.path.spec.to_s.include?('sdr_ia') }

    if sdr_ia_routes.any?
      log "✓ #{sdr_ia_routes.count} rotas SDR IA encontradas"
      sdr_ia_routes.first(5).each do |route|
        log "  - #{route.verb.source.gsub(/[^A-Z]/, '')} #{route.path.spec}"
      end
    else
      log "✗ Nenhuma rota SDR IA encontrada"
    end
  rescue StandardError => e
    log "Não foi possível verificar rotas: #{e.message}"
  end
end

# Executar
if inject_routes!
  verify_routes!
end
