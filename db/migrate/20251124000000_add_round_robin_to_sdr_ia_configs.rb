# frozen_string_literal: true

class AddRoundRobinToSdrIaConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :sdr_ia_configs, :enable_round_robin, :boolean, default: false
    add_column :sdr_ia_configs, :round_robin_closers, :jsonb, default: []
    add_column :sdr_ia_configs, :last_assigned_closer_index, :integer, default: -1

    # Adicionar comentários para documentar
    add_column :sdr_ia_configs, :round_robin_strategy, :string, default: 'sequential', comment: 'sequential, random, weighted'
  end
end
