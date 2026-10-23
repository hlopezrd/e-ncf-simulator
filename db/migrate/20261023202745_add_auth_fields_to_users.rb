class AddAuthFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :rnc, :string
    add_column :users, :username, :string
    add_column :users, :password_digest, :string

    add_index :users, :username, unique: true
    add_index :users, [ :rnc, :username ], unique: true
  end
end
