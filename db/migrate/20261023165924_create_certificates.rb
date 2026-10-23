class CreateCertificates < ActiveRecord::Migration[8.0]
  def change
    create_table :certificates do |t|
      t.string :rnc, null: false
      t.string :alias_name
      t.string :subject
      t.string :issuer
      t.string :serial
      t.datetime :not_before
      t.datetime :not_after
      t.string :thumbprint

      t.timestamps
    end
    add_index :certificates, :rnc
    add_index :certificates, :thumbprint, unique: true
  end
end
