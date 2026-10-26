class CreateNcfSequences < ActiveRecord::Migration[8.0]
  def change
    create_table :ncf_sequences do |t|
      t.string :rnc, null: false
      t.integer :tipo, null: false
      t.integer :desde, null: false
      t.integer :hasta, null: false
      t.date :fecha_vencimiento, null: false
      t.boolean :activa, null: false, default: true

      t.timestamps
    end
    add_index :ncf_sequences, [ :rnc, :tipo ]
  end
end
