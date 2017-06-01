class WikiMenuTitlesToSlug < ActiveRecord::Migration[4.2]
  def up
    migrate_menu_items
  end

  def down
    rollback_menu_items
  end

  ##
  # Fix lookup of wiki pages in menu items by referencing the actual slug in the title attribute.
  # As the title attribute is fixed from MenuItem, and the name was used, swap the two around
  # to avoid confusing the actual title of the menu item (previously == name).
  def migrate_menu_items
    ActiveRecord::Base.transaction do
      ::MenuItems::WikiMenuItem.includes(:wiki).find_each do |item|

        # We need the associated wiki to be present
        wiki = item.wiki
        next if wiki.nil?

        # Find the page
        wiki_page = wiki.find_page(item.title)

        # Set the title to the actual slug
        # If the page could not be found, migrate the title to form a slug
        slug = wiki_page.nil? ? item.title.to_url : wiki_page.slug

        # Use the name to set the title.
        # This clears up the previously irritating mixup of the two.
        menu_item_title = item.name

        item.update_columns(title: menu_item_title, name: slug)
      end
    end
  end

  ##
  #
  # Restore the old title wherever possible
  # This tries to remove the slug usages without guaranteeing that links
  # will be valid afterwards.
  def rollback_menu_items
    ActiveRecord::Base.transaction do
      ::MenuItems::WikiMenuItem.includes(:wiki).find_each do |item|
        # Find the page
        wiki_page = item.wiki.find_page(item.title)

        # Restore the switch of title and name
        old_name = item.title
        old_title =
          if wiki_page.present?
            wiki_page.title
          else
            item.name
          end

        item.update_columns(title: old_title, name: old_name)
      end
    end
  end
end
