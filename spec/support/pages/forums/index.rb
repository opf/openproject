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

require "support/pages/page"

module Pages
  module Forums
    class Index < ::Pages::Page
      attr_reader :project

      def initialize(project)
        super()
        @project = project
      end

      def path = project_forums_path(project)

      def expect_listed(*names, first_rowindex: 2)
        expect(page).to have_css(row_selector, count: names.size)
        names.each.with_index(first_rowindex) do |name, rowindex|
          expect(page).to have_selector(:row, name, rowindex:)
        end
      end

      def within_forum(forum, &)
        within_test_selector("forum-row-#{forum.id}", &)
      end

      def click_forum_action(forum, action:)
        within_forum(forum) do
          click_on accessible_name: "Forum actions"
          click_on action
        end
      end

      def drag_forum(from_index:, to_index:)
        drag_and_drop_list(from: from_index, to: to_index, elements: row_selector, handler: ".DragHandle")
      end

      private

      def row_selector = "[data-test-selector^='forum-row-']"
    end
  end
end
