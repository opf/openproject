class CreateWikiMenuItemForExistingWikis < ActiveRecord::Migration
  def self.up
    Wiki.all.each do |wiki|

      page = wiki.find_page(wiki.start_page, :with_redirects => true)

      current_title = page.present? ?
                        page.title :
                        wiki.start_page

      menu_item = WikiMenuItem.new
      menu_item.name = wiki.start_page
      menu_item.title = current_title
      menu_item.wiki_id = wiki.id
      menu_item.index_page = true
      menu_item.new_wiki_page = true

      menu_item.save!
    end
  end

  def self.down
    puts "You cannot safely undo this migration!"
  end
end
