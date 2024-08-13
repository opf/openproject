#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects::Copy
  class WikiDependentService < Dependency
    include AttachmentCopier

    attachment_dependent_service ::Projects::Copy::WikiPageAttachmentsDependentService

    def self.human_name
      I18n.t(:label_wiki_page_plural)
    end

    def source_count
      source.wiki && source.wiki.pages.count
    end

    protected

    def copy_dependency(params:)
      # Check that the source project has a wiki first
      return if source.wiki.nil?

      target.wiki = target.build_wiki(source.wiki.attributes.dup.except("id", "project_id"))
      target.wiki.wiki_menu_items.delete_all

      copy_wiki_pages(params)
      copy_wiki_menu_items
    end

    # Copies wiki pages from +project+, requires a wiki to be already set
    def copy_wiki_pages(_params)
      wiki_pages_map = {}

      # Copying top down so that the hierarchy (parent attribute)
      # can be rewritten along the way.
      pages_top_down do |page|
        new_parent_id = wiki_pages_map[page.parent_id]
        new_wiki_page = copy_wiki_page(page, new_parent_id)
        wiki_pages_map[page.id] = new_wiki_page.id if new_wiki_page
      end

      state.wiki_page_id_lookup = wiki_pages_map
    end

    def copy_wiki_page(source_page, new_parent_id)
      # Relying on ActionMailer::Base.perform_deliveries is violating cohesion
      # but the value is currently not otherwise provided
      service_call = WikiPages::CopyService
                     .new(user:, model: source_page, contract_class: WikiPages::CopyContract)
                     .call(wiki: target.wiki,
                           parent_id: new_parent_id,
                           send_notifications: ActionMailer::Base.perform_deliveries,
                           copy_attachments: copy_attachments?)

      if service_call.success?
        service_call.result
      else
        add_error!(source_page, service_call.errors)
        Rails.logger.warn do
          "Project#copy_wiki_page: wiki_page ##{source_page.id} could not be copied: #{service_call.message}"
        end

        nil
      end
    end

    def pages_top_down(&)
      id_by_parent = source.wiki.pages.pluck(:parent_id, :id).inject(Hash.new { [] }) do |h, (k, v)|
        h[k] += [v]
        h
      end

      yield_downwards(id_by_parent, nil, &)
    end

    def yield_downwards(map, current, &)
      map[current].each do |child_id|
        child = source.wiki.pages.find(child_id)

        yield child

        yield_downwards(map, child_id, &)
      end
    end

    # Copies wiki_menu_items from +project+, requires a wiki to be already set
    def copy_wiki_menu_items
      wiki_menu_items_map = {}

      source.wiki.wiki_menu_items.each do |item|
        new_item = MenuItems::WikiMenuItem.new
        new_item.attributes = item.attributes.dup.except("id", "wiki_id", "parent_id")
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
