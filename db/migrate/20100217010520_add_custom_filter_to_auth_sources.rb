#-- encoding: UTF-8
class AddCustomFilterToAuthSources < ActiveRecord::Migration
  def self.up
    add_column :auth_sources, :custom_filter, :string
  end

  def self.down
    remove_column :auth_sources, :custom_filter
  end
end
