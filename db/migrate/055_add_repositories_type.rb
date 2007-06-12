class AddRepositoriesType < ActiveRecord::Migration
  def self.up
    add_column :repositories, :type, :string    
    # Set class name for existing SVN repositories
    Repository.update_all "type = 'Subversion'"
  end

  def self.down
    remove_column :repositories, :type
  end
end
