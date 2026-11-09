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

module FormFields
  class FormField
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers

    attr_reader :property, :selector

    def initialize(property, selector: nil)
      @property = property
      @selector = selector || "[data-test-selector='#{property_name}']"
    end

    def expect_visible
      raise NotImplementedError
    end

    def expect_not_visible
      expect(page).to have_no_selector(selector)
    end

    def expect_required
      expect(field_container)
        .to have_css ".spot-form-field--label-indicator", text: "*"
    end

    def field_container
      page.find(selector)
    end

    def property_name
      if property.is_a? CustomField
        property.attribute_name(:camel_case)
      else
        property.to_s
      end
    end
  end
end
