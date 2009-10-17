class AddMissingIndexesToDocuments < ActiveRecord::Migration
  def self.up
    add_index :documents, :category_id
  end

  def self.down
    remove_index :documents, :category_id
  end
end
