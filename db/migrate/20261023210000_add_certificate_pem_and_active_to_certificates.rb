class AddCertificatePemAndActiveToCertificates < ActiveRecord::Migration[8.0]
  def up
    add_column :certificates, :certificate_pem, :text
    add_column :certificates, :active, :boolean, default: true, null: false

    # Empezamos desde cero: los registros anteriores no tenian el PEM real.
    Certificate.delete_all

    add_index :certificates, :rnc,
              unique: true,
              where: "active = 1 AND deleted_at IS NULL",
              name: "index_certificates_active_rnc"
  end

  def down
    remove_index :certificates, name: "index_certificates_active_rnc"
    remove_column :certificates, :active
    remove_column :certificates, :certificate_pem
  end
end
