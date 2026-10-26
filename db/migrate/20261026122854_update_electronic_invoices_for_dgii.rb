class UpdateElectronicInvoicesForDgii < ActiveRecord::Migration[8.0]
  def up
    add_column :electronic_invoices, :rnc_comprador, :string
    add_column :electronic_invoices, :monto_total, :decimal, precision: 18, scale: 2
    add_column :electronic_invoices, :total_itbis, :decimal, precision: 18, scale: 2
    add_column :electronic_invoices, :fecha_firma, :string
    add_column :electronic_invoices, :codigo_seguridad, :string
    add_column :electronic_invoices, :secuencia_utilizada, :boolean, default: true, null: false

    remove_index :electronic_invoices, name: "index_electronic_invoices_on_rnc_emisor_and_encf"
    add_index :electronic_invoices, [ :rnc_emisor, :encf ]
  end

  def down
    remove_index :electronic_invoices, [ :rnc_emisor, :encf ]
    add_index :electronic_invoices, [ :rnc_emisor, :encf ], unique: true, name: "index_electronic_invoices_on_rnc_emisor_and_encf"
    remove_column :electronic_invoices, :secuencia_utilizada
    remove_column :electronic_invoices, :codigo_seguridad
    remove_column :electronic_invoices, :fecha_firma
    remove_column :electronic_invoices, :total_itbis
    remove_column :electronic_invoices, :monto_total
    remove_column :electronic_invoices, :rnc_comprador
  end
end
