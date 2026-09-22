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

module Documents
  module Pages
    class ListPage < ::Pages::Page
      attr_reader :project

      def initialize(project)
        @project = project
        super()
      end

      def visit!
        visit(path)
      end

      def path
        "/projects/#{project.id}/documents"
      end

      def expect_documents_listed(documents)
        expected_document_titles = documents.map(&:title)

        within "#content-wrapper" do
          expected_document_titles.each { expect(page).to have_css(".Box-row", text: it) }
        end
      end

      def expect_blank_slate_with_primary_action
        expect_blank_slate(with_primary_action: true)
      end

      def expect_blank_slate_without_primary_action
        expect_blank_slate(with_primary_action: false)
      end

      def expect_blank_slate(with_primary_action: false)
        within_test_selector("documents-list-blank-slate") do
          expect(page).to have_text("There are no documents yet")

          if with_primary_action
            expect(page).to have_text("There are no documents in this view. You can click the button below to add one.")
            expect(page).to have_link("Document")
          end
        end
      end

      def expect_submenu_opened(title)
        submenu.expect_item(title, selected: true)
      end

      def expect_submenu_filters(*titles)
        titles.each { submenu.expect_item(it) }
      end

      def expect_pagination_range(from:, to:, total:)
        pagination.expect_range(from, to, total)
      end

      def submenu
        @submenu ||= Components::Submenu.new
      end

      def pagination
        @pagination ||= Components::TablePagination.new
      end
    end
  end
end
