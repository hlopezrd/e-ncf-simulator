class CreateAuthTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :auth_tokens do |t|
      t.string :token, null: false
      t.string :rnc, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :auth_tokens, :token, unique: true
    add_index :auth_tokens, :rnc
  end
end
