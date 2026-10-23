class CreateSimulationRules < ActiveRecord::Migration[8.0]
  def change
    create_table :simulation_rules do |t|
      t.string :name, null: false
      t.text :description
      t.string :rule_type, null: false
      t.boolean :active, null: false, default: true
      t.string :value

      t.timestamps
    end
    add_index :simulation_rules, :rule_type
    add_index :simulation_rules, :active
  end
end
