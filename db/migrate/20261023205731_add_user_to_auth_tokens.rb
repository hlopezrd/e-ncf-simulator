class AddUserToAuthTokens < ActiveRecord::Migration[8.0]
  def change
    add_reference :auth_tokens, :user, null: true, foreign_key: true
  end
end
