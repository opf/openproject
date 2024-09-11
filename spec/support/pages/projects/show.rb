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
  module Projects
    class Show < ::Pages::Page
      attr_reader :project

      # rubocop:disable Lint/MissingSuper
      def initialize(project)
        @project = project
      end
      # rubocop:enable Lint/MissingSuper

      def path
        project_path(project)
      end

      def within_sidebar(&)
        within("#menu-sidebar", &)
      end

      def toast_type
        :rails
      end

      def visit_page
        visit path
      end

      def expect_no_visible_sidebar
        expect_angular_frontend_initialized
        expect(page).to have_no_css(".op-grid-page--grid-container")
      end

      def within_async_loaded_sidebar(&)
        within "#project-custom-fields-sidebar" do
          expect(page).to have_css("[data-test-selector='project-custom-fields-sidebar-async-content']")
          yield
        end
      end

      def within_custom_field_section_container(section, &)
        within("[data-test-selector='project-custom-field-section-#{section.id}']", &)
      end

      def within_custom_field_container(custom_field, &)
        within("[data-test-selector='project-custom-field-#{custom_field.id}']", &)
      end

      def open_edit_dialog_for_section(section)
        within_async_loaded_sidebar do
          scroll_to_element(page.find("[data-test-selector='project-custom-field-section-#{section.id}']"))
          within_custom_field_section_container(section) do
            page.find("[data-test-selector='project-custom-field-section-edit-button']").click
          end
        end

        expect(page).to have_css("[data-test-selector='async-dialog-content']", wait: 5)
      end

      def expand_text(custom_field)
        within_custom_field_container(custom_field) do
          page.find('[data-test-selector="expand-button"]').click
        end
      end

      def expect_text_not_truncated(custom_field)
        within_custom_field_container(custom_field) do
          expect(page).to have_no_css('[data-test-selector="expand-button"]')
        end
      end

      def expect_text_truncated(custom_field)
        within_custom_field_container(custom_field) do
          expect(page).to have_css('[data-test-selector="expand-button"]')
        end
      end

      def expect_full_text_in_dialog(text)
        within('[data-test-selector="attribute-dialog"]') do
          expect(page)
            .to have_content(text)
        end
      end
    end
  end
end
