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

module Forums
  module Topics
    class SortMenuComponent < ApplicationComponent
      ORDERS = [
        [:recent_activity, "updated_at", false],
        [:oldest_activity, "updated_at", true],
        [:newest, "created_at", false],
        [:oldest, "created_at", true],
        [:most_replies, "replies", false],
        [:fewest_replies, "replies", true]
      ].freeze

      options :forum
      options :sort_criteria

      def call
        render(Primer::Alpha::ActionMenu.new(select_variant: :single,
                                             dynamic_label: true,
                                             dynamic_label_prefix: I18n.t(:label_sort),
                                             test_selector: "forum-topics-sort")) do |menu|
          menu.with_show_button do |button|
            button.with_trailing_action_icon(icon: :"triangle-down")
            active_label
          end

          ORDERS.each do |key, column, asc|
            menu.with_item(label: label(key), href: sort_path(column, asc), active: active?(column, asc))
          end
        end
      end

      private

      def label(key) = I18n.t("forums.show.sort.#{key}")

      def sort_path(column, asc)
        project_forum_path(forum.project, forum, sort: asc ? column : "#{column}:desc")
      end

      def active?(column, asc)
        sort_criteria.first_key == column && sort_criteria.first_asc? == asc
      end

      def active_label
        key, = ORDERS.find { |_key, column, asc| active?(column, asc) } || ORDERS.first
        label(key)
      end
    end
  end
end
