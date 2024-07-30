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

require "support/components/common/modal"
require "support/components/autocompleter/ng_select_autocomplete_helpers"

module Components
  module Projects
    module ProjectCustomFields
      class EditDialog < Components::Common::Modal
        include Components::Autocompleter::NgSelectAutocompleteHelpers

        attr_reader :project, :project_custom_field_section, :title

        def initialize(project, project_custom_field_section)
          super()

          @project = project
          @project_custom_field_section = project_custom_field_section
          @title = @project_custom_field_section.name
        end

        def dialog_css_selector
          "dialog#edit-project-custom-fields-dialog-#{@project_custom_field_section.id}"
        end

        def async_content_container_css_selector
          "#{dialog_css_selector} [data-test-selector='async-dialog-content']"
        end

        def within_dialog(&)
          within(dialog_css_selector, &)
        end

        def within_async_content(close_after_yield: false, &)
          within(async_content_container_css_selector, &)
          close if close_after_yield
        end

        def close
          within_dialog do
            page.find(".close-button").click
          end
        end
        alias_method :close_via_icon, :close

        def close_via_button
          within(dialog_css_selector) do
            click_link_or_button "Cancel"
          end
        end

        def submit
          within(dialog_css_selector) do
            page.find("[data-test-selector='save-project-attributes-button']").click
          end
        end

        def expect_open
          expect(page).to have_css(dialog_css_selector)
        end

        def expect_closed
          expect(page).to have_no_css(dialog_css_selector)
        end

        def expect_async_content_loaded
          expect(page).to have_css(async_content_container_css_selector)
        end

        ###

        def input_containers
          within "#project-section-edit-form > .FormControl-spacingWrapper" do
            page.all(".FormControl-spacingWrapper")
          end
        end

        def within_custom_field_input_container(custom_field, &)
          # wrapping in `within_async_content` to make sure the container is properly loaded
          within_async_content do
            within("[data-test-selector='project-custom-field-input-container-#{custom_field.id}']", &)
          end
        end
      end
    end
  end
end
