class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :rnc, null: false
      t.string :razon_social
      t.string :nombre_comercial
      t.string :email
      t.string :telefono
      t.boolean :activa, default: true, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :companies, :rnc, unique: true
    add_index :companies, :deleted_at
  end
end