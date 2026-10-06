# frozen_string_literal: true

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

module Settings
  class SearchTree
    Node = Data.define(:key, :label, :description, :href, :children)

    def initialize(view_context,
                   pages: Settings::Pages.all,
                   menu: Settings::Pages.admin_menu,
                   hidden_menu_items: OpenProject::Configuration.hidden_menu_items["admin_menu"] || [])
      @view_context = view_context
      @pages_by_menu_item = pages.group_by(&:menu_item)
      @menu = menu
      @hidden_menu_items = hidden_menu_items.map(&:to_s)
    end

    def nodes
      @nodes ||= build(@menu)
    end

    private

    attr_reader :view_context

    def build(menu_node)
      menu_node.children.filter_map do |item|
        next unless visible_menu_item?(item)

        children = [*page_nodes(item), *build(item)]
        next if children.empty?

        Node.new(key: item.name.to_s, label: item.caption, description: nil, href: view_context.url_for(item.url), children:)
      end
    end

    def page_nodes(item)
      @pages_by_menu_item.fetch(item.name, []).flat_map do |page|
        leaves = setting_nodes(page)

        if page.label && leaves.any?
          [Node.new(key: page.key.to_s,
                    label: view_context.t(page.label),
                    description: nil,
                    href: view_context.url_for(page.url(@menu)),
                    children: leaves)]
        else
          leaves
        end
      end
    end

    def setting_nodes(page)
      page.sections.flat_map(&:visible_entries).map do |entry|
        Node.new(key: "#{page.key}-#{entry.name}",
                 label: entry.label(view_context),
                 description: plain_text(entry.caption(view_context)),
                 href: view_context.url_for(page.url(@menu).merge(highlight: entry.name)),
                 children: [])
      end
    end

    def plain_text(html)
      view_context.strip_tags(html)&.squish.presence
    end

    def visible_menu_item?(item)
      (item.condition.nil? || item.condition.call(nil)) && @hidden_menu_items.exclude?(item.name.to_s)
    end
  end
end
