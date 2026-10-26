class AddAnuladaToNcfSequences < ActiveRecord::Migration[8.0]
  def change
    add_column :ncf_sequences, :anulada, :boolean, null: false, default: false
  end
end
