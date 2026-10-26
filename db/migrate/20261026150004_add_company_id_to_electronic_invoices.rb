class AddCompanyIdToElectronicInvoices < ActiveRecord::Migration[8.0]
  def change
    add_reference :electronic_invoices, :company, null: true, foreign_key: true
    add_index :electronic_invoices, [:company_id, :rnc_emisor]
  end
end