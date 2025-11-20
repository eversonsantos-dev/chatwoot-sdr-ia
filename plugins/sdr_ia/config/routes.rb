# frozen_string_literal: true

# SDR IA Routes Configuration
# This file is loaded by config/initializers/sdr_ia.rb

Rails.application.routes.draw do
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      resources :accounts, only: [] do
        scope module: :sdr_ia do
          get 'sdr_ia/settings', to: 'settings#show', as: 'sdr_ia_settings'
          put 'sdr_ia/settings', to: 'settings#update'
          post 'sdr_ia/test', to: 'settings#test_qualification', as: 'sdr_ia_test'
          get 'sdr_ia/stats', to: 'settings#stats', as: 'sdr_ia_stats'
          get 'sdr_ia/teams', to: 'settings#teams', as: 'sdr_ia_teams'
        end
      end
    end
  end
end
