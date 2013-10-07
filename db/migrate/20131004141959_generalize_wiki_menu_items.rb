class GeneralizeWikiMenuItems < ActiveRecord::Migration
  def up
  	rename_table :wiki_menu_items, :menu_items
  	add_column :menu_items, :type, :string
  	rename_column :menu_items, :wiki_id, :navigatable_id
    rename_index :menu_items, 'index_wiki_menu_items_on_parent_id', 'index_menu_items_on_parent_id'
    rename_index :menu_items, 'index_wiki_menu_items_on_wiki_id_and_title', 'index_menu_items_on_navigatable_id_and_title'

  	MenuItem.find_each do |menu_item|
  	  menu_item.update_attribute :type, 'MenuItems::WikiMenuItem'
  	end

  	# TODO rename indexes
  end

  def down
  	rename_table :menu_items, :wiki_menu_items
  	remove_column :wiki_menu_items, :type
  	rename_column :wiki_menu_items, :navigatable_id, :wiki_id
    rename_index :wiki_menu_items, 'index_menu_items_on_parent_id', 'index_wiki_menu_items_on_parent_id'
    rename_index :wiki_menu_items, 'index_menu_items_on_navigatable_id_and_title', 'index_wiki_menu_items_on_wiki_id_and_title'
  end
end
