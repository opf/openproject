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

Capybara.add_selector(:pattern_input, locator_type: [String, Symbol]) do
  label "pattern input field"

  # Find a div with contenteditable attribute, which has parent with
  # data-controller attribute pattern-input, and that has a preceding sibling
  # hidden input with label matched by locator
  xpath do |locator, **_options|
    input_predicate = XPath.attr(:type) == "hidden"

    if locator
      locator = locator.to_s

      input_predicate &= XPath.attr(:id) == XPath.anywhere(:label)[XPath.string.n.is(locator)].attr(:for)
    end

    XPath.descendant(:div)[
      [
        XPath.attr(:contenteditable),
        XPath.ancestor.attr(:"data-controller") == "pattern-input",
        XPath.preceding_sibling(:input)[input_predicate]
      ].inject(:&)
    ]
  end
end

module Capybara
  module RSpecMatchers
    def have_pattern_input(locator = nil, **, &)
      Matchers::HaveSelector.new(:pattern_input, locator, **, &)
    end

    def have_no_pattern_input(locator = nil, **, &)
      Matchers::NegatedMatcher.new(have_pattern_input(locator, **, &))
    end
  end
end
