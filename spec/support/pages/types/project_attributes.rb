# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "support/pages/page"

module Pages
  module Types
    class ProjectAttributes < ::Pages::Page
      def initialize(type)
        super()

        @type = type
      end

      def path
        edit_type_project_attributes_path(@type)
      end

      def toggle(project_custom_field)
        page
          .find("[data-test-selector='toggle-type-project-attribute-#{project_custom_field.id}'] > button")
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
