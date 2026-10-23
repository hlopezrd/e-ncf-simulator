class AddDeletedAtToAllTables < ActiveRecord::Migration[8.0]
  def change
    %i[auth_tokens electronic_invoices validation_errors certificates simulation_rules users roles audit_logs allowed_origins].each do |table|
      add_column table, :deleted_at, :datetime
      add_index table, :deleted_at
    end
  end
end
