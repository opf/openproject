class CreateWikiPages < ActiveRecord::Migration
  def self.up
    create_table :wiki_pages do |t|
      t.column :wiki_id, :integer, :null => false
      t.column :title, :string, :limit => 255, :null => false
      t.column :created_on, :datetime, :null => false    
    end
    add_index :wiki_pages, [:wiki_id, :title], :name => :wiki_pages_wiki_id_title
  end

  def self.down
    drop_table :wiki_pages
  end
end
