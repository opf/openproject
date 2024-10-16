class SetVersionsNameCollation < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL.squish
      CREATE COLLATION IF NOT EXISTS versions_name (provider = icu, locale = 'und-u-kn-true');
    SQL

    change_column :versions, :name, :string, collation: "versions_name"
  end

  def down
    change_column :versions, :name, :string
  end
end
