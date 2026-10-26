class CreateNcfUsages < ActiveRecord::Migration[8.0]
  def change
    create_table :ncf_usages do |t|
      t.string :rnc, null: false
      t.string :encf, null: false
      t.string :track_id, null: false

      t.timestamps
    end
    add_index :ncf_usages, [ :rnc, :encf ]
  end
end
