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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "support/pages/page"

module Pages
  module Types
    class ProjectAttributes < ::Pages::Page
      def initialize(type, variant: nil)
        super()

        @type = type
        @variant = variant
      end

      def path
        return edit_type_variant_project_attributes_path(type_id: @type.id, variant_id: @variant.id) if @variant

        edit_type_project_attributes_path(@type)
      end

      def toggle(project_custom_field)
        page
          .find("[data-test-selector='toggle-variant-project-attribute-#{project_custom_field.id}'] > button")
          .click
      end

      def expect_type(type)
        within "[data-test-selector='custom-field-type']" do
          expect(page).to have_text(type)
        end
      end

      def expect_checked_state
        expect(page).to have_css(".ToggleSwitch-statusOn")
      end

      def expect_unchecked_state
        expect(page).to have_css(".ToggleSwitch-statusOff")
      end

      def within_section(section, &)
        within("[data-test-selector='type-project-attribute-section-#{section.id}']", &)
      end

      def within_attribute(project_custom_field, &)
        within("[data-test-selector='type-project-attribute-#{project_custom_field.id}']", &)
      end
    end
  end
end
