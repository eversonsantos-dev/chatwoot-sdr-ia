# frozen_string_literal: true

class AddKnowledgeBaseToSdrIaConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :sdr_ia_configs, :knowledge_base, :text, default: ''
  end
end
