class CreateCommercialApprovals < ActiveRecord::Migration[8.0]
  def change
    create_table :commercial_approvals do |t|
      t.string :rnc_emisor
      t.string :rnc_comprador
      t.string :encf
      t.integer :estado
      t.string :motivo_rechazo
      t.datetime :fecha_hora_aprobacion
      t.text :xml_content

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
