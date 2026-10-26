class CreateAuthSeeds < ActiveRecord::Migration[8.0]
  def change
    create_table :auth_seeds do |t|
      t.string :valor, null: false
      t.datetime :fecha, null: false
      t.datetime :expira, null: false
      t.boolean :usado, null: false, default: false
      t.string :rnc

      t.timestamps
    end
    add_index :auth_seeds, :valor, unique: true
  end
end
