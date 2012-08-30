class CreateWikiMenuItems < ActiveRecord::Migration
  def self.up
    create_table :wiki_menu_items do |t|
      t.column :name, :string
      t.column :title, :string
      t.column :parent_id, :integer
      t.column :options, :text

      t.belongs_to :wiki
    end
  end

  def self.down
    puts "You cannot safely undo this migration!"
  end
end
