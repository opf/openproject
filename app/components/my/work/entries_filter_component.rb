# frozen_string_literal: true

# -- copyright
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
# ++

module My
  module Work
    class EntriesFilterComponent < ApplicationComponent
      FILTERS = %i[all logged allocated].freeze

      ICONS = {
        all: :tasklist,
        logged: :clock,
        allocated: :"op-person-assigned"
      }.freeze

      options :current_entries,
              :path_builder
      options link_data: {}

      def call
        render(Primer::Alpha::ActionMenu.new(menu_id: "my-work-entries-filter")) do |menu|
          menu.with_show_button do |button|
            button.with_leading_visual_icon(icon: ICONS.fetch(current_entries))
            button.with_trailing_action_icon(icon: :"triangle-down")
            label_for(current_entries)
          end

          FILTERS.each { menu_item_for(menu, it) }
        end
      end

      private

      def menu_item_for(menu, entries)
        menu.with_item(tag: :a,
                       href: path_builder.call(entries),
                       active: entries == current_entries,
                       content_arguments: { data: link_data },
                       label: label_for(entries)) do |item|
          item.with_leading_visual_icon(icon: ICONS.fetch(entries))
        end
      end

      def label_for(entries)
        t("my.work.entries_filter.#{entries}")
      end
    end
  end
end
