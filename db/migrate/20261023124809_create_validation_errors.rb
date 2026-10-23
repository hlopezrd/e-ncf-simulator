class CreateValidationErrors < ActiveRecord::Migration[8.0]
  def change
    create_table :validation_errors do |t|
      t.references :electronic_invoice, null: false, foreign_key: true
      t.string :codigo, null: false
      t.string :campo, null: false
      t.text :mensaje, null: false
      t.string :severidad, null: false

      t.timestamps
    end
    add_index :validation_errors, :codigo
  end
end
