#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

module Projects::Copy
  class WikiDependentService < Dependency
    include ::Copy::Concerns::CopyAttachments

    def self.human_name
      I18n.t(:label_wiki_page_plural)
    end

    protected

    def copy_dependency(params:)
      # Check that the source project has a wiki first
      return if source.wiki.nil?

      target.wiki = target.build_wiki(source.wiki.attributes.dup.except('id', 'project_id'))
      target.wiki.wiki_menu_items.delete_all

      copy_wiki_pages(params)
      copy_wiki_menu_items
    end

    # Copies wiki pages from +project+, requires a wiki to be already set
    def copy_wiki_pages(params)
      wiki_pages_map = {}

      source.wiki.pages.find_each do |page|
        # Skip pages without content
        next if page.content.nil?

        new_wiki_content = WikiContent.new(page.content.attributes.dup.except('id', 'page_id', 'updated_at'))
        attributes = page
          .attributes.dup.except('id', 'wiki_id', 'created_on', 'parent_id')
          .merge(content: new_wiki_content)

        new_wiki_page = target.wiki.pages.create attributes
        wiki_pages_map[page] = new_wiki_page
      end

      # Save the wiki
      target.wiki.save

      # Reproduce page hierarchy
      source.project.wiki.pages.each do |page|
        if page.parent_id && wiki_pages_map[page]
          wiki_pages_map[page].parent = wiki_pages_map[page.parent]
          wiki_pages_map[page].save
        end
      end

      # Copy attachments
      if should_copy?(params, :wiki_page_attachments)
        wiki_pages_map.each do |old_page, new_page|
          copy_attachments(old_page.id, new_page.id, new_page.class.name)
        end
      end
    end

    # Copies wiki_menu_items from +project+, requires a wiki to be already set
    def copy_wiki_menu_items
      wiki_menu_items_map = {}

      source.wiki.wiki_menu_items.each do |item|
        new_item = MenuItems::WikiMenuItem.new
        new_item.attributes = item.attributes.dup.except('id', 'wiki_id', 'parent_id')
        new_item.wiki = target.wiki
        (wiki_menu_items_map[item.id] = new_item.reload) if new_item.save
      end

      source.wiki.wiki_menu_items.each do |item|
        if item.parent_id && (copy = wiki_menu_items_map[item.id])
          copy.parent = wiki_menu_items_map[item.parent_id]
          copy.save
        end
      end
    end
  end
end
