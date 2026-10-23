class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.string :actor, null: false
      t.string :action, null: false
      t.string :target
      t.text :details

      t.timestamps
    end
    add_index :audit_logs, :actor
    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
  end
end
