class AddCompanyIdToNcfSequences < ActiveRecord::Migration[8.0]
  def change
    add_reference :ncf_sequences, :company, null: true, foreign_key: true
    add_index :ncf_sequences, [ :company_id, :tipo ]
  end
end
