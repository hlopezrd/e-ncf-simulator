class CreateElectronicInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :electronic_invoices do |t|
      t.string :track_id, null: false
      t.string :rnc_emisor, null: false
      t.string :encf, null: false
      t.string :tipo_comprobante
      t.date :fecha_emision
      t.text :xml_content
      t.string :estado, null: false
      t.datetime :fecha_recepcion, null: false

      t.timestamps
    end
    add_index :electronic_invoices, :track_id, unique: true
    add_index :electronic_invoices, :rnc_emisor
    add_index :electronic_invoices, :encf
    add_index :electronic_invoices, [ :rnc_emisor, :encf ], unique: true
  end
end
