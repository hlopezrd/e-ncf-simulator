class SeedDefaultRoles < ActiveRecord::Migration[8.0]
  def up
    %w[admin operator viewer].each do |name|
      Role.find_or_create_by!(name: name) do |r|
        r.description = name.capitalize
      end
    end
  end

  def down
    Role.where(name: %w[admin operator viewer]).destroy_all
  end
end
