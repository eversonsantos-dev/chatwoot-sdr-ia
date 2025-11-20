<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useAdmin } from 'dashboard/composables/useAdmin';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import accountAPI from 'dashboard/api/account';

const { t } = useI18n();
const store = useStore();
const { isAdmin } = useAdmin();
const getters = useStoreGetters();

const currentAccount = computed(() => getters['getCurrentAccount'].value);

const loading = ref(false);
const savingSettings = ref(false);
const testingContact = ref(false);
const stats = ref(null);
const teams = ref([]);
const activeTab = ref('general'); // general, prompts, questions, scoring

// Settings form
const settings = ref({
  sdr_ia: {
    enabled: true,
    debug_mode: false,
    openai: {
      api_key: '',
      model: 'gpt-4-turbo-preview',
      max_tokens: 2000,
      temperature: 0.3
    },
    prompts: {
      system: '',
      analysis: ''
    },
    perguntas_etapas: {
      nome: 'Qual é o seu nome?',
      interesse: 'Qual procedimento você tem interesse?',
      urgencia: 'Para quando você está pensando em fazer?',
      conhecimento: 'Você já pesquisou sobre valores?',
      motivacao: 'Qual é o seu principal objetivo com esse procedimento?',
      localizacao: 'De qual região/bairro você é?'
    },
    procedimentos: [],
    scoring: {
      weights: {
        urgencia: {
          esta_semana: 30,
          proximas_2_semanas: 25,
          ate_30_dias: 15,
          acima_30_dias: 5,
          pesquisando: 0
        },
        conhecimento: {
          conhece_valores: 25,
          tem_duvidas: 15,
          primeira_pesquisa: 5
        },
        interesse_definido: 20,
        motivacao_clara: 20
      }
    },
    temperature_thresholds: {
      quente: 70,
      morno: 40,
      frio: 20,
      muito_frio: 0
    },
    teams: {
      quente_team_id: null,
      morno_team_id: null
    },
    reconduzir: {
      max_tentativas: 3,
      delay_segundos: 2
    }
  }
});

const testContactId = ref('');
const testResult = ref(null);
const newProcedimento = ref('');

// Tab management
const tabs = [
  { id: 'general', label: 'Configurações Gerais', icon: '⚙️' },
  { id: 'prompts', label: 'Prompts da IA', icon: '🤖' },
  { id: 'questions', label: 'Perguntas por Etapa', icon: '❓' },
  { id: 'scoring', label: 'Sistema de Scoring', icon: '📊' }
];

// Load settings
const loadSettings = async () => {
  loading.value = true;
  try {
    const response = await accountAPI.get(`${currentAccount.value.id}/sdr_ia/settings`);
    if (response.data.settings) {
      settings.value = response.data.settings;
    }
  } catch (error) {
    console.error('Erro ao carregar configurações:', error);
    useAlert('Erro ao carregar configurações do SDR IA');
  } finally {
    loading.value = false;
  }
};

// Load stats
const loadStats = async () => {
  try {
    const response = await accountAPI.get(`${currentAccount.value.id}/sdr_ia/stats`);
    stats.value = response.data;
  } catch (error) {
    console.error('Erro ao carregar estatísticas:', error);
  }
};

// Load teams
const loadTeams = async () => {
  try {
    const response = await accountAPI.get(`${currentAccount.value.id}/sdr_ia/teams`);
    teams.value = response.data.teams || [];
  } catch (error) {
    console.error('Erro ao carregar times:', error);
  }
};

// Save settings
const saveSettings = async () => {
  savingSettings.value = true;
  try {
    const response = await accountAPI.put(
      `${currentAccount.value.id}/sdr_ia/settings`,
      { settings: settings.value }
    );

    if (response.data.success) {
      useAlert('Configurações salvas com sucesso!');
      await loadStats();
    } else {
      useAlert(response.data.error || 'Erro ao salvar configurações');
    }
  } catch (error) {
    console.error('Erro ao salvar:', error);
    useAlert('Erro ao salvar configurações do SDR IA');
  } finally {
    savingSettings.value = false;
  }
};

// Test qualification
const testQualification = async () => {
  if (!testContactId.value) {
    useAlert('Digite o ID do contato para testar');
    return;
  }

  testingContact.value = true;
  testResult.value = null;

  try {
    const response = await accountAPI.post(
      `${currentAccount.value.id}/sdr_ia/test`,
      { contact_id: testContactId.value }
    );

    testResult.value = response.data;

    if (response.data.success) {
      useAlert('Teste executado com sucesso!');
    } else {
      useAlert(response.data.error || 'Erro no teste de qualificação');
    }
  } catch (error) {
    console.error('Erro ao testar:', error);
    useAlert('Erro ao executar teste de qualificação');
    testResult.value = { success: false, error: error.message };
  } finally {
    testingContact.value = false;
  }
};

// Procedimentos management
const addProcedimento = () => {
  if (newProcedimento.value.trim()) {
    if (!settings.value.sdr_ia.procedimentos) {
      settings.value.sdr_ia.procedimentos = [];
    }
    settings.value.sdr_ia.procedimentos.push(newProcedimento.value.trim());
    newProcedimento.value = '';
  }
};

const removeProcedimento = (index) => {
  settings.value.sdr_ia.procedimentos.splice(index, 1);
};

onMounted(() => {
  if (isAdmin.value) {
    loadSettings();
    loadStats();
    loadTeams();
  }
});
</script>

<template>
  <div class="flex-1 overflow-auto">
    <BaseSettingsHeader
      title="SDR IA - Qualificação Automática"
      description="Configure a qualificação automática de leads usando Inteligência Artificial"
      link-text="Documentação"
      feature-name="sdr_ia"
    />

    <div v-if="!isAdmin" class="p-8">
      <p class="text-slate-600 dark:text-slate-400">
        Apenas administradores podem acessar esta página.
      </p>
    </div>

    <div v-else-if="loading" class="p-8">
      <woot-loading-state message="Carregando configurações..." />
    </div>

    <div v-else class="p-8 max-w-6xl">
      <!-- Estatísticas -->
      <div v-if="stats" class="mb-8 grid grid-cols-1 md:grid-cols-5 gap-4">
        <div class="bg-white dark:bg-slate-800 p-4 rounded-lg shadow">
          <div class="text-sm text-slate-600 dark:text-slate-400">Total Qualificados</div>
          <div class="text-2xl font-bold text-slate-900 dark:text-slate-100">
            {{ stats.total_qualificados }}
          </div>
        </div>
        <div class="bg-red-50 dark:bg-red-900/20 p-4 rounded-lg shadow">
          <div class="text-sm text-red-600 dark:text-red-400">🔥 Quentes</div>
          <div class="text-2xl font-bold text-red-700 dark:text-red-300">
            {{ stats.distribuicao?.quente || 0 }}
          </div>
        </div>
        <div class="bg-orange-50 dark:bg-orange-900/20 p-4 rounded-lg shadow">
          <div class="text-sm text-orange-600 dark:text-orange-400">🌤️ Mornos</div>
          <div class="text-2xl font-bold text-orange-700 dark:text-orange-300">
            {{ stats.distribuicao?.morno || 0 }}
          </div>
        </div>
        <div class="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-lg shadow">
          <div class="text-sm text-blue-600 dark:text-blue-400">❄️ Frios</div>
          <div class="text-2xl font-bold text-blue-700 dark:text-blue-300">
            {{ stats.distribuicao?.frio || 0 }}
          </div>
        </div>
        <div class="bg-slate-50 dark:bg-slate-900/20 p-4 rounded-lg shadow">
          <div class="text-sm text-slate-600 dark:text-slate-400">🧊 Muito Frios</div>
          <div class="text-2xl font-bold text-slate-700 dark:text-slate-300">
            {{ stats.distribuicao?.muito_frio || 0 }}
          </div>
        </div>
      </div>

      <!-- Tabs Navigation -->
      <div class="mb-6 border-b border-slate-200 dark:border-slate-700">
        <div class="flex space-x-8">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            @click="activeTab = tab.id"
            class="py-4 px-2 font-medium text-sm transition-colors relative"
            :class="activeTab === tab.id
              ? 'text-blue-600 dark:text-blue-400'
              : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-200'"
          >
            <span class="mr-2">{{ tab.icon }}</span>
            {{ tab.label }}
            <div
              v-if="activeTab === tab.id"
              class="absolute bottom-0 left-0 right-0 h-0.5 bg-blue-600 dark:bg-blue-400"
            ></div>
          </button>
        </div>
      </div>

      <!-- Tab: Configurações Gerais -->
      <div v-show="activeTab === 'general'" class="space-y-6">
        <div class="bg-white dark:bg-slate-800 rounded-lg shadow p-6">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-4">
            ⚙️ Configurações Gerais
          </h3>

          <div class="space-y-4">
            <!-- Enable/Disable -->
            <div class="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-700/50 rounded-lg">
              <div>
                <label class="text-sm font-medium text-slate-700 dark:text-slate-300">
                  Módulo Ativo
                </label>
                <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
                  Ativa/desativa a qualificação automática de leads
                </p>
              </div>
              <input
                v-model="settings.sdr_ia.enabled"
                type="checkbox"
                class="w-5 h-5 rounded"
              />
            </div>

            <!-- Debug Mode -->
            <div class="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-700/50 rounded-lg">
              <div>
                <label class="text-sm font-medium text-slate-700 dark:text-slate-300">
                  Modo Debug
                </label>
                <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
                  Exibe logs detalhados no console
                </p>
              </div>
              <input
                v-model="settings.sdr_ia.debug_mode"
                type="checkbox"
                class="w-5 h-5 rounded"
              />
            </div>

            <!-- OpenAI API Key -->
            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                🔑 OpenAI API Key
              </label>
              <input
                v-model="settings.sdr_ia.openai.api_key"
                type="password"
                placeholder="sk-proj-..."
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
              />
              <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
                Sua chave de API ficará armazenada com segurança no banco de dados
              </p>
            </div>

            <!-- OpenAI Model -->
            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                🤖 Modelo OpenAI
              </label>
              <select
                v-model="settings.sdr_ia.openai.model"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
              >
                <option value="gpt-4-turbo-preview">GPT-4 Turbo (Recomendado)</option>
                <option value="gpt-4">GPT-4</option>
                <option value="gpt-3.5-turbo">GPT-3.5 Turbo (Mais barato)</option>
              </select>
            </div>

            <!-- Advanced OpenAI Settings -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Max Tokens
                </label>
                <input
                  v-model.number="settings.sdr_ia.openai.max_tokens"
                  type="number"
                  min="100"
                  max="4000"
                  class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Temperature
                </label>
                <input
                  v-model.number="settings.sdr_ia.openai.temperature"
                  type="number"
                  min="0"
                  max="2"
                  step="0.1"
                  class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                />
              </div>
            </div>

            <!-- Temperature Thresholds -->
            <div class="border-t border-slate-200 dark:border-slate-700 pt-4 mt-4">
              <h4 class="text-sm font-semibold text-slate-900 dark:text-slate-100 mb-3">
                🌡️ Limites de Temperatura (Score mínimo)
              </h4>

              <div class="grid grid-cols-4 gap-4">
                <div>
                  <label class="block text-sm text-red-700 dark:text-red-400 mb-1">
                    🔥 Quente
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.temperature_thresholds.quente"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full px-3 py-2 border border-red-300 dark:border-red-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
                <div>
                  <label class="block text-sm text-orange-700 dark:text-orange-400 mb-1">
                    🌤️ Morno
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.temperature_thresholds.morno"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full px-3 py-2 border border-orange-300 dark:border-orange-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
                <div>
                  <label class="block text-sm text-blue-700 dark:text-blue-400 mb-1">
                    ❄️ Frio
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.temperature_thresholds.frio"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full px-3 py-2 border border-blue-300 dark:border-blue-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
                <div>
                  <label class="block text-sm text-slate-700 dark:text-slate-400 mb-1">
                    🧊 Muito Frio
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.temperature_thresholds.muito_frio"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
              </div>
            </div>

            <!-- Team Assignment -->
            <div class="border-t border-slate-200 dark:border-slate-700 pt-4 mt-4">
              <h4 class="text-sm font-semibold text-slate-900 dark:text-slate-100 mb-3">
                👥 Atribuição Automática para Times
              </h4>

              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                    Time para Leads Quentes 🔥
                  </label>
                  <select
                    v-model.number="settings.sdr_ia.teams.quente_team_id"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  >
                    <option :value="null">Não atribuir automaticamente</option>
                    <option v-for="team in teams" :key="team.id" :value="team.id">
                      {{ team.name }}
                    </option>
                  </select>
                </div>
                <div>
                  <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                    Time para Leads Mornos 🌤️
                  </label>
                  <select
                    v-model.number="settings.sdr_ia.teams.morno_team_id"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  >
                    <option :value="null">Não atribuir automaticamente</option>
                    <option v-for="team in teams" :key="team.id" :value="team.id">
                      {{ team.name }}
                    </option>
                  </select>
                </div>
              </div>
            </div>

            <!-- Procedimentos -->
            <div class="border-t border-slate-200 dark:border-slate-700 pt-4 mt-4">
              <h4 class="text-sm font-semibold text-slate-900 dark:text-slate-100 mb-3">
                💉 Procedimentos Disponíveis
              </h4>

              <div class="flex gap-2 mb-3">
                <input
                  v-model="newProcedimento"
                  type="text"
                  placeholder="Nome do procedimento"
                  @keyup.enter="addProcedimento"
                  class="flex-1 px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                />
                <button
                  @click="addProcedimento"
                  class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Adicionar
                </button>
              </div>

              <div class="flex flex-wrap gap-2">
                <div
                  v-for="(proc, index) in settings.sdr_ia.procedimentos"
                  :key="index"
                  class="flex items-center gap-2 px-3 py-1 bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300 rounded-full text-sm"
                >
                  <span>{{ proc }}</span>
                  <button
                    @click="removeProcedimento(index)"
                    class="text-blue-900 dark:text-blue-100 hover:text-red-600 dark:hover:text-red-400"
                  >
                    ×
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Tab: Prompts da IA -->
      <div v-show="activeTab === 'prompts'" class="space-y-6">
        <div class="bg-white dark:bg-slate-800 rounded-lg shadow p-6">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-4">
            🤖 Prompts da Inteligência Artificial
          </h3>

          <div class="space-y-6">
            <!-- System Prompt -->
            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                📝 Prompt do Sistema (Instruções para a IA)
              </label>
              <textarea
                v-model="settings.sdr_ia.prompts.system"
                rows="15"
                placeholder="Defina como a IA deve se comportar..."
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100 font-mono text-sm"
              ></textarea>
              <p class="text-xs text-slate-500 dark:text-slate-400 mt-2">
                Este prompt define o comportamento geral da IA, as regras que ela deve seguir e as perguntas que deve fazer.
              </p>
            </div>

            <!-- Analysis Prompt -->
            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                🔍 Prompt de Análise (Extração de Dados)
              </label>
              <textarea
                v-model="settings.sdr_ia.prompts.analysis"
                rows="20"
                placeholder="Instruções para análise e extração de dados..."
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100 font-mono text-sm"
              ></textarea>
              <p class="text-xs text-slate-500 dark:text-slate-400 mt-2">
                Este prompt instrui a IA sobre como analisar a conversa e extrair informações em formato JSON.
                Use <code class="bg-slate-200 dark:bg-slate-700 px-1 rounded">{conversation_history}</code> para onde o histórico da conversa será inserido.
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Tab: Perguntas por Etapa -->
      <div v-show="activeTab === 'questions'" class="space-y-6">
        <div class="bg-white dark:bg-slate-800 rounded-lg shadow p-6">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-4">
            ❓ Perguntas Personalizadas para Cada Etapa
          </h3>

          <p class="text-sm text-slate-600 dark:text-slate-400 mb-6">
            Configure as perguntas que a IA deve fazer em cada etapa da qualificação.
          </p>

          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                1️⃣ Nome do Lead
              </label>
              <input
                v-model="settings.sdr_ia.perguntas_etapas.nome"
                type="text"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                2️⃣ Interesse (Procedimento)
              </label>
              <input
                v-model="settings.sdr_ia.perguntas_etapas.interesse"
                type="text"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                3️⃣ Urgência (Timing)
              </label>
              <input
                v-model="settings.sdr_ia.perguntas_etapas.urgencia"
                type="text"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                4️⃣ Conhecimento de Mercado
              </label>
              <input
                v-model="settings.sdr_ia.perguntas_etapas.conhecimento"
                type="text"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                5️⃣ Motivação/Objetivo
              </label>
              <input
                v-model="settings.sdr_ia.perguntas_etapas.motivacao"
                type="text"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                6️⃣ Localização
              </label>
              <input
                v-model="settings.sdr_ia.perguntas_etapas.localizacao"
                type="text"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Tab: Sistema de Scoring -->
      <div v-show="activeTab === 'scoring'" class="space-y-6">
        <div class="bg-white dark:bg-slate-800 rounded-lg shadow p-6">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-4">
            📊 Sistema de Scoring (Pesos)
          </h3>

          <p class="text-sm text-slate-600 dark:text-slate-400 mb-6">
            Configure os pesos usados para calcular o score de qualificação (0-100).
          </p>

          <div class="space-y-6">
            <!-- Urgência Weights -->
            <div>
              <h4 class="text-sm font-semibold text-slate-900 dark:text-slate-100 mb-3">
                ⏰ Pontuação por Urgência
              </h4>
              <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
                <div>
                  <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                    Esta Semana
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.scoring.weights.urgencia.esta_semana"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
                <div>
                  <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                    Próximas 2 Semanas
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.scoring.weights.urgencia.proximas_2_semanas"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
                <div>
                  <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                    Até 30 Dias
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.scoring.weights.urgencia.ate_30_dias"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
                <div>
                  <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                    Acima de 30 Dias
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.scoring.weights.urgencia.acima_30_dias"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
                <div>
                  <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                    Só Pesquisando
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.scoring.weights.urgencia.pesquisando"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
              </div>
            </div>

            <!-- Conhecimento Weights -->
            <div class="border-t border-slate-200 dark:border-slate-700 pt-4">
              <h4 class="text-sm font-semibold text-slate-900 dark:text-slate-100 mb-3">
                🧠 Pontuação por Conhecimento
              </h4>
              <div class="grid grid-cols-3 gap-4">
                <div>
                  <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                    Conhece Valores
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.scoring.weights.conhecimento.conhece_valores"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
                <div>
                  <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                    Tem Dúvidas
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.scoring.weights.conhecimento.tem_duvidas"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
                <div>
                  <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                    Primeira Pesquisa
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.scoring.weights.conhecimento.primeira_pesquisa"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
              </div>
            </div>

            <!-- Other Weights -->
            <div class="border-t border-slate-200 dark:border-slate-700 pt-4">
              <h4 class="text-sm font-semibold text-slate-900 dark:text-slate-100 mb-3">
                ✨ Outros Critérios
              </h4>
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                    Interesse Definido
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.scoring.weights.interesse_definido"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
                <div>
                  <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                    Motivação Clara
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.scoring.weights.motivacao_clara"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
              </div>
            </div>

            <!-- Reconduzir Settings -->
            <div class="border-t border-slate-200 dark:border-slate-700 pt-4">
              <h4 class="text-sm font-semibold text-slate-900 dark:text-slate-100 mb-3">
                🔄 Configurações de Recondução
              </h4>
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                    Máximo de Tentativas por Pergunta
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.reconduzir.max_tentativas"
                    type="number"
                    min="1"
                    max="10"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
                <div>
                  <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                    Delay entre Análises (segundos)
                  </label>
                  <input
                    v-model.number="settings.sdr_ia.reconduzir.delay_segundos"
                    type="number"
                    min="1"
                    max="60"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Save Button (always visible) -->
      <div class="sticky bottom-0 bg-white dark:bg-slate-800 border-t border-slate-200 dark:border-slate-700 p-4 rounded-lg shadow-lg">
        <div class="flex justify-between items-center">
          <p class="text-sm text-slate-600 dark:text-slate-400">
            Lembre-se de salvar suas alterações
          </p>
          <Button
            :label="savingSettings ? 'Salvando...' : 'Salvar Todas as Configurações'"
            :disabled="savingSettings"
            @click="saveSettings"
            class="!px-6 !py-3"
          />
        </div>
      </div>

      <!-- Test Section -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow p-6 mt-6">
        <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-4">
          🧪 Testar Qualificação
        </h3>

        <div class="flex gap-4 items-end">
          <div class="flex-1">
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
              ID do Contato
            </label>
            <input
              v-model="testContactId"
              type="text"
              placeholder="Digite o ID do contato"
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
            />
          </div>
          <Button
            :label="testingContact ? 'Testando...' : 'Testar Agora'"
            :disabled="testingContact || !testContactId"
            @click="testQualification"
          />
        </div>

        <div v-if="testResult" class="mt-4 p-4 rounded-lg" :class="testResult.success ? 'bg-green-50 dark:bg-green-900/20' : 'bg-red-50 dark:bg-red-900/20'">
          <div v-if="testResult.success" class="text-green-800 dark:text-green-200">
            <p class="font-semibold mb-2">✅ Qualificação realizada com sucesso!</p>
            <div class="text-sm space-y-1">
              <p><strong>Nome:</strong> {{ testResult.contact?.name }}</p>
              <p><strong>Temperatura:</strong> {{ testResult.contact?.temperatura }}</p>
              <p><strong>Score:</strong> {{ testResult.contact?.score }}</p>
            </div>
          </div>
          <div v-else class="text-red-800 dark:text-red-200">
            <p class="font-semibold">❌ Erro na qualificação</p>
            <p class="text-sm mt-1">{{ testResult.error }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
textarea {
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', 'Consolas', 'source-code-pro', monospace;
}
</style>
