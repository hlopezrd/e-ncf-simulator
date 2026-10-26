class AddDeletedAtToAuthSeeds < ActiveRecord::Migration[8.0]
  def change
    add_column :auth_seeds, :deleted_at, :datetime
  end
end
