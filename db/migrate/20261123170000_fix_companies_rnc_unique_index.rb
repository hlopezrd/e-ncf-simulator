class FixCompaniesRncUniqueIndex < ActiveRecord::Migration[8.0]
  def up
    remove_index :companies, name: "index_companies_on_rnc"
    add_index :companies, :rnc, unique: true,
              where: "deleted_at IS NULL", name: "index_companies_on_rnc_active"
  end

  def down
    remove_index :companies, name: "index_companies_on_rnc_active"
    add_index :companies, :rnc, unique: true, name: "index_companies_on_rnc"
  end
end
