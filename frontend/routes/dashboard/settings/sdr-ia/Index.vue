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

// Settings form
const settings = ref({
  sdr_ia: {
    enabled: true,
    debug_mode: false,
    openai: {
      model: 'gpt-4-turbo-preview',
      max_tokens: 2000,
      temperature: 0.3
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
    }
  }
});

const testContactId = ref('');
const testResult = ref(null);

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

    <div v-else class="p-8 max-w-5xl">
      <!-- Estatísticas -->
      <div v-if="stats" class="mb-8 grid grid-cols-1 md:grid-cols-5 gap-4">
        <div class="bg-white dark:bg-slate-800 p-4 rounded-lg shadow">
          <div class="text-sm text-slate-600 dark:text-slate-400">Total Qualificados</div>
          <div class="text-2xl font-bold text-slate-900 dark:text-slate-100">
            {{ stats.total_qualificados }}
          </div>
        </div>
        <div class="bg-red-50 dark:bg-red-900/20 p-4 rounded-lg shadow">
          <div class="text-sm text-red-600 dark:text-red-400">Quentes</div>
          <div class="text-2xl font-bold text-red-700 dark:text-red-300">
            {{ stats.distribuicao?.quente || 0 }}
          </div>
        </div>
        <div class="bg-orange-50 dark:bg-orange-900/20 p-4 rounded-lg shadow">
          <div class="text-sm text-orange-600 dark:text-orange-400">Mornos</div>
          <div class="text-2xl font-bold text-orange-700 dark:text-orange-300">
            {{ stats.distribuicao?.morno || 0 }}
          </div>
        </div>
        <div class="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-lg shadow">
          <div class="text-sm text-blue-600 dark:text-blue-400">Frios</div>
          <div class="text-2xl font-bold text-blue-700 dark:text-blue-300">
            {{ stats.distribuicao?.frio || 0 }}
          </div>
        </div>
        <div class="bg-slate-50 dark:bg-slate-900/20 p-4 rounded-lg shadow">
          <div class="text-sm text-slate-600 dark:text-slate-400">Muito Frios</div>
          <div class="text-2xl font-bold text-slate-700 dark:text-slate-300">
            {{ stats.distribuicao?.muito_frio || 0 }}
          </div>
        </div>
      </div>

      <!-- Configurações -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow p-6 mb-6">
        <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-4">
          Configurações Gerais
        </h3>

        <div class="space-y-4">
          <!-- Enable/Disable -->
          <div class="flex items-center justify-between">
            <label class="text-sm font-medium text-slate-700 dark:text-slate-300">
              Módulo Ativo
            </label>
            <input
              v-model="settings.sdr_ia.enabled"
              type="checkbox"
              class="rounded"
            />
          </div>

          <!-- Debug Mode -->
          <div class="flex items-center justify-between">
            <label class="text-sm font-medium text-slate-700 dark:text-slate-300">
              Modo Debug
            </label>
            <input
              v-model="settings.sdr_ia.debug_mode"
              type="checkbox"
              class="rounded"
            />
          </div>

          <!-- OpenAI Model -->
          <div>
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
              Modelo OpenAI
            </label>
            <select
              v-model="settings.sdr_ia.openai.model"
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
            >
              <option value="gpt-4-turbo-preview">GPT-4 Turbo</option>
              <option value="gpt-4">GPT-4</option>
              <option value="gpt-3.5-turbo">GPT-3.5 Turbo</option>
            </select>
          </div>

          <!-- Temperature Thresholds -->
          <div class="border-t border-slate-200 dark:border-slate-700 pt-4 mt-4">
            <h4 class="text-sm font-semibold text-slate-900 dark:text-slate-100 mb-3">
              Limites de Temperatura (Score)
            </h4>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                  Quente (mínimo)
                </label>
                <input
                  v-model.number="settings.sdr_ia.temperature_thresholds.quente"
                  type="number"
                  min="0"
                  max="100"
                  class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                />
              </div>
              <div>
                <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                  Morno (mínimo)
                </label>
                <input
                  v-model.number="settings.sdr_ia.temperature_thresholds.morno"
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
              Atribuição Automática para Times
            </h4>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                  Time para Leads Quentes
                </label>
                <select
                  v-model.number="settings.sdr_ia.teams.quente_team_id"
                  class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                >
                  <option :value="null">Não atribuir</option>
                  <option v-for="team in teams" :key="team.id" :value="team.id">
                    {{ team.name }}
                  </option>
                </select>
              </div>
              <div>
                <label class="block text-sm text-slate-700 dark:text-slate-300 mb-1">
                  Time para Leads Mornos
                </label>
                <select
                  v-model.number="settings.sdr_ia.teams.morno_team_id"
                  class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                >
                  <option :value="null">Não atribuir</option>
                  <option v-for="team in teams" :key="team.id" :value="team.id">
                    {{ team.name }}
                  </option>
                </select>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-6 flex justify-end">
          <Button
            :label="savingSettings ? 'Salvando...' : 'Salvar Configurações'"
            :disabled="savingSettings"
            @click="saveSettings"
          />
        </div>
      </div>

      <!-- Test Section -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow p-6">
        <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-4">
          Testar Qualificação
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
            :label="testingContact ? 'Testando...' : 'Testar'"
            :disabled="testingContact || !testContactId"
            @click="testQualification"
          />
        </div>

        <div v-if="testResult" class="mt-4 p-4 rounded-lg" :class="testResult.success ? 'bg-green-50 dark:bg-green-900/20' : 'bg-red-50 dark:bg-red-900/20'">
          <div v-if="testResult.success" class="text-green-800 dark:text-green-200">
            <p class="font-semibold mb-2">Qualificação realizada com sucesso!</p>
            <div class="text-sm space-y-1">
              <p><strong>Nome:</strong> {{ testResult.contact?.name }}</p>
              <p><strong>Temperatura:</strong> {{ testResult.contact?.temperatura }}</p>
              <p><strong>Score:</strong> {{ testResult.contact?.score }}</p>
            </div>
          </div>
          <div v-else class="text-red-800 dark:text-red-200">
            <p class="font-semibold">Erro na qualificação</p>
            <p class="text-sm mt-1">{{ testResult.error }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
