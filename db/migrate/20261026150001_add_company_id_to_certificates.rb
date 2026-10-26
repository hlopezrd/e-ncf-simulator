class AddCompanyIdToCertificates < ActiveRecord::Migration[8.0]
  def change
    add_reference :certificates, :company, null: true, foreign_key: true
    add_index :certificates, [ :company_id, :active ]
  end
end
