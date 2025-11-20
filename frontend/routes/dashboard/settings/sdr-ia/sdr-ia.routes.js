import { frontendURL } from '../../../../helper/URLHelper';

const SettingsContent = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/sdr-ia'),
      name: 'sdr_ia_settings',
      meta: {
        permissions: ['administrator'],
      },
      component: SettingsContent,
    },
  ],
};
