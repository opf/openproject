class AddFilterToLdap < ActiveRecord::Migration[6.0]
  def change
    add_column :auth_sources, :filter_string, :text, null: true
  end
end
