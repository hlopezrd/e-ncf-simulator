class AddDeletedAtToNcfSequences < ActiveRecord::Migration[8.0]
  def change
    add_column :ncf_sequences, :deleted_at, :datetime
  end
end
