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
require "capybara/rspec"

module TestSelectorFinders
  def test_selector(value)
    "[data-test-selector=\"#{value}\"]"
  end

  def find_test_selector(value, **)
    find(:test_id, value, **)
  end

  def within_test_selector(value, **, &)
    within(:test_id, value, **, &)
  end

  # expect(page).to have_test_selector('foo')
  def have_test_selector(value, **)
    have_selector(test_selector(value), **)
  end
end

RSpec.configure do |config|
  Capybara.test_id = "data-test-selector"
  Capybara.add_selector(:test_id) do
    xpath do |locator|
      XPath.descendant[XPath.attr(Capybara.test_id) == locator]
    end
  end

  Capybara::Session.include(TestSelectorFinders)
  Capybara::DSL.extend(TestSelectorFinders)
  config.include TestSelectorFinders, type: :feature
end
