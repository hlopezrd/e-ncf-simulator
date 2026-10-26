class CreateNcfAnnulations < ActiveRecord::Migration[8.0]
  def change
    create_table :ncf_annulations do |t|
      t.string :rnc_emisor
      t.integer :cantidad_anulados
      t.datetime :fecha_hora_anulacion
      t.text :xml_content

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
