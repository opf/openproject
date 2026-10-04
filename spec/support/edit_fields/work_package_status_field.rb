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

require_relative "edit_field"

class WorkPackageStatusField < EditField
  def initialize(context)
    @context = context
    @selector = "[data-test-selector='op-wp-status-button']"
  end

  def input_selector
    "#wp-status-context-menu"
  end

  def input_element
    page.find input_selector.to_s
  end

  def display_element
    @context.find "#{@selector} .button"
  end

  def activate!
    retry_block do
      unless active?
        scroll_to_and_click(display_element)
      end
    end
  end
  alias :activate_edition :activate!

  def update(value, save: true, expect_failure: false)
    retry_block do
      activate_edition
      set_value value

      expect_state! open: expect_failure
    end
  end

  def set_value(content)
    input_element.find("button", text: content).click
  end

  def active?
    page.has_selector? input_selector, wait: 1
  end
  alias :editing? :active?

  def expect_active!
    expect(page).to have_selector(input_selector, wait: 10),
                    "Expected context menu for status."
  end

  def expect_inactive!
    expect(page).to have_no_selector(input_selector)
  end
end
