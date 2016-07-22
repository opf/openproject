class AddSlugToWikiPages < ActiveRecord::Migration
  def up
    add_column :wiki_pages, :slug, :string
    add_index :wiki_pages, [:wiki_id, :slug], name: 'wiki_pages_wiki_id_slug', unique: true

    migrate_titles
    change_column_null :wiki_pages, :slug, true
  end

  def down
    remove_column :wiki_pages, :slug

    # Restore the old title
    ActiveRecord::Base.transaction do
      WikiPage.select(:id, :wiki_id, :title).find_each do |page|
        # Save the title with spaces restored
        # And generate the url slug
        old_title = page.title.gsub(' ', '_')

        page.update_columns(title: old_title)
        WikiRedirect.where(wiki_id: page.wiki_id, title: old_title).delete_all
      end
    end
  end


  ##
  # OpenProject < 6.0.0 processed wiki titles in a specific fashion (#titleize)
  # replacing spaces with underscores and removing some characters.
  # With OpenProject 6.0.0, titles were allowed to contain any chars.
  # This causes issues since a title `foo bar` was saved as `foo_bar`, but displayed with spaces again
  # and in turn, many page links actualy use [[foo bar]] instead of the actual title.
  # Spaces were no longer matching the existing pages.
  #
  # Additionally, not all characters can be properly detected in the `parse_wiki_links` steps
  # and this makes it impossible to link to some pages.
  #
  # To remove this issue, we introduce wiki slugs to create proper permalinks that can be linked
  # to, and only fall back to finding by titles for the old pages.
  def migrate_titles
    # Create a redirect for all old titles
    ActiveRecord::Base.transaction do
      WikiPage.select(:id, :wiki_id, :title).find_each do |page|
        # Restore the spaces in the old title (`pretty_title` in wiki.rb)
        pretty_title = page.title.gsub('_', ' ')

        # Generate a URL slug from the title using stringex
        slug = pretty_title.to_url

        # Generate a redirect from the old title to the slug
        if page.title != slug
          WikiRedirect.create(title: page.title, wiki_id: page.wiki_id, redirects_to: slug)
        end

        # Save the title with spaces restored
        # And generate the url slug
        page.update_columns(title: pretty_title, slug: slug)
      end
    end
  end
end
