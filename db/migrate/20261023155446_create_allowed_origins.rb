class CreateAllowedOrigins < ActiveRecord::Migration[8.0]
  def change
    create_table :allowed_origins do |t|
      t.string :origin, null: false

      t.timestamps
    end
    add_index :allowed_origins, :origin, unique: true
  end
end
