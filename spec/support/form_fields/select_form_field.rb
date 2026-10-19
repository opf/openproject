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

require_relative "form_field"

module FormFields
  class SelectFormField < FormField
    def expect_selected(*values)
      values.each do |val|
        expect(field_container).to have_css(".ng-value", text: val)
      end
    end

    def expect_no_option(option)
      field_container.find(".ng-select-container").click

      expect(page)
        .to have_no_css(".ng-option", text: option, visible: :all)
    end

    def expect_option(option, grouping: nil)
      field_container.find(".ng-select-container").click
      if grouping
        # Make sure the option is displayed under correct grouping title.
        option_group = find(".ng-optgroup", text: grouping)
        option = find(".ng-option.ng-option-child", text: option, visible: :visible)

        expected_group = begin
          option.find(:xpath,
                      "preceding-sibling::*[contains(@class, 'ng-optgroup')][1]",
                      wait: false)
        rescue Capybara::ElementNotFound
          raise "Unable to find the '.ng-optgroup' grouping for option '#{option.text}'"
        end

        expect(option_group).to eq(expected_group), <<~MSG
          Expected the option '#{option.text}' to be under the group '#{option_group.text}',
          but it was under '#{expected_group.text}' instead.
        MSG
      else
        expect(page)
          .to have_css(".ng-option", text: option, visible: :visible)
      end
    end

    def expect_visible
      expect(field_container).to have_css("ng-select")
    end

    def select_option(*values)
      values.each do |val|
        field_container.find(".ng-select-container").click
        page.find(".ng-option", text: val, visible: :all).click
        sleep 1
      end
    end

    def search(text)
      field_container.find(".ng-select-container input").set text
    end
  end
end
