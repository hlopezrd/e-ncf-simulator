class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.references :role, null: false, foreign_key: true
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
