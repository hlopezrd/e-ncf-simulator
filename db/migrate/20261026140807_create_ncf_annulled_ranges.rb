class CreateNcfAnnulledRanges < ActiveRecord::Migration[8.0]
  def change
    create_table :ncf_annulled_ranges do |t|
      t.string :rnc, null: false
      t.integer :tipo, null: false
      t.integer :desde, null: false
      t.integer :hasta, null: false
      t.references :ncf_annulation, null: true, foreign_key: true

      t.timestamps
    end
    add_index :ncf_annulled_ranges, [ :rnc, :tipo ]
  end
end
