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
  module Projects
    class Show < ::Pages::Page
      attr_reader :project

      def initialize(project)
        @project = project
      end

      def path
        project_path(project)
      end

      def within_sidebar(&)
        within("#menu-sidebar", &)
      end

      def visit_page
        visit path
      end

      def expect_no_visible_sidebar
        expect_angular_frontend_initialized
        expect(page).to have_no_css(".Layout-sidebar")
      end

      def expect_visible_sidebar
        expect_angular_frontend_initialized
        expect(page).to have_css(".Layout-sidebar")
      end

      def within_project_attributes_sidebar(&)
        within_test_selector("project-custom-fields-sidebar", &)
      end

      def within_main_area(&)
        within_test_selector("grids-project-attribute-widgets", &)
      end

      def within_custom_field_section_container(section, &)
        within_test_selector("project-custom-field-section-#{section.id}", &)
      end

      def within_custom_field_section_widget(section, &)
        within_test_selector("project-custom-field-section-widget-#{section.id}", &)
      end

      def within_custom_field_container(custom_field, &)
        within_test_selector("project-custom-field-#{custom_field.id}", &)
      end

      def expect_no_custom_field(custom_field)
        expect(page).to have_no_css("[data-test-selector='project-custom-field-#{custom_field.id}']")
      end

      def expect_custom_field_without_modal_button(custom_field)
        within_custom_field_container(custom_field) do
          expect(page).to have_no_test_selector("[data-test-selector*='inplace-edit-dialog-button-']")
        end
      end

      def open_modal_for_custom_field(custom_field)
        scroll_to_element(page.find("[data-test-selector='project-custom-field-#{custom_field.id}']"))
        field = Components::Common::InplaceEditField.new(project, custom_field.attribute_name.to_sym, show_in_dialog: true)
        field.open_field

        wait_for_size_animation_completion(field.dialog.dialog_css_selector)

        field
      end

      def open_inplace_edit_field_for_custom_field(custom_field)
        scroll_to_element(page.find("[data-test-selector='project-custom-field-#{custom_field.id}']"))
        field = Components::Common::InplaceEditField.new(project, custom_field.attribute_name.to_sym)

        wait_for_turbo_stream { field.open_field }

        field
      end

      def open_edit_dialog_for_life_cycle(life_cycle, wait_angular: false)
        within_life_cycle_sidebar do
          page.find("[data-test-selector='project-life-cycle-edit-button-#{life_cycle.id}']").click
        end

        Components::Projects::ProjectLifeCycle::EditDialog.new.tap do |dialog|
          dialog.expect_open

          expect_angular_frontend_initialized if wait_angular
        end
      end

      def within_life_cycle_sidebar(&)
        within_test_selector("project-life-cycle-sidebar-async-content", &)
      end

      def within_life_cycle_container(life_cycle, &)
        within("[data-test-selector='project-life-cycle-#{life_cycle.id}']", &)
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
