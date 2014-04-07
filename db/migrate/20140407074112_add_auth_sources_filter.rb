class AddAuthSourcesFilter < ActiveRecord::Migration
  def up
    add_column :auth_sources, :filter, :string
  end

  def down
    remove_column :auth_sources, :filter
  end
end
