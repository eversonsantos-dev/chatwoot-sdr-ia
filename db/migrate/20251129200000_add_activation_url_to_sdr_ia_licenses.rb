# frozen_string_literal: true

class AddActivationUrlToSdrIaLicenses < ActiveRecord::Migration[7.0]
  def change
    # Adiciona campo apenas se a tabela existir e o campo não existir
    return unless table_exists?(:sdr_ia_licenses)
    return if column_exists?(:sdr_ia_licenses, :activation_url)

    add_column :sdr_ia_licenses, :activation_url, :string
  end
end
