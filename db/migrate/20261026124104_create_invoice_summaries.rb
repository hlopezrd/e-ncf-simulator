class CreateInvoiceSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_summaries do |t|
      t.string :rnc_emisor
      t.string :encf
      t.integer :codigo
      t.string :estado
      t.boolean :secuencia_utilizada
      t.text :xml_content

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
