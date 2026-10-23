class AddTokenDigestToAuthTokens < ActiveRecord::Migration[8.0]
  def up
    add_column :auth_tokens, :token_digest, :string

    AuthToken.reset_column_information
    AuthToken.find_each do |record|
      # Backfill from legacy plaintext token column if present.
      if record.respond_to?(:token) && record[:token].present?
        record.update_column(:token_digest, Digest::SHA256.hexdigest(record[:token]))
      end
    end

    remove_column :auth_tokens, :token if column_exists?(:auth_tokens, :token)
    change_column_null :auth_tokens, :token_digest, false
    add_index :auth_tokens, :token_digest, unique: true
  end

  def down
    add_column :auth_tokens, :token, :string
    AuthToken.reset_column_information
    # Cannot recover original plaintext tokens; leave null.
    remove_column :auth_tokens, :token_digest
  end
end
