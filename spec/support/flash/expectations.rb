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

module Flash
  module Expectations
    def expect_flash(message: nil, exact_message: nil, type: :success, wait: 20)
      expected_css = expected_flash_css(type)
      expect(page).to have_css(expected_css, wait:, **{ text: message, exact_text: exact_message }.compact)
    end

    def find_flash_element(type:)
      expected_css = expected_flash_css(type)
      page.find(expected_css)
    end

    def expect_and_dismiss_flash(message: nil, exact_message: nil, type: :success, wait: 20)
      expect_flash(type:, message:, exact_message:, wait:)
      dismiss_flash!
      expect_no_flash(type:, message:, exact_message:, wait: 5)
    end

    def dismiss_flash!
      page.find(".Banner-close button").click # rubocop:disable Capybara/SpecificActions
    end

    def expect_no_flash(type: :success, message: nil, exact_message: nil, wait: 10)
      if type.nil?
        expect(page).to have_no_test_selector("op-primer-flash-message")
      else
        expected_css = expected_flash_css(type)
        expect(page).to have_no_css(expected_css, wait:, **{ text: message, exact_text: exact_message }.compact)
      end
    end

    def expected_flash_css(type)
      scheme = mapped_flash_type(type)

      if scheme == :default
        %{[data-test-selector="op-primer-flash-message"].Banner}
      else
        %{[data-test-selector="op-primer-flash-message"].Banner--#{scheme}}
      end
    end

    def mapped_flash_type(type)
      case type
      when :error, :warning, :success
        type
      when :notice
        :success
      else
        :default
      end
    end
  end
end

RSpec.configure do |config|
  config.include Flash::Expectations
end
