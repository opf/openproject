class AddRepositoriesLogEncoding < ActiveRecord::Migration
  def self.up
    add_column :repositories, :log_encoding, :string, :limit => 64, :default => nil
  end

  def self.down
    remove_column :repositories, :log_encoding
  end
end
