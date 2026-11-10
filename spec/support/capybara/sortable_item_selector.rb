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

# Finds elements wired as `sortable-lists--item`, located by the record they
# move, and filtered by the type and label they announce.
#
# @example Assert a record is a sortable item of its list's type
#   expect(page).to have_selector(:sortable_item, group, type: "group", label: "Details", count: 1)
#
# @example Shorthand matcher
#   expect(page).to have_sortable_item(type, type: "type", label: type.name)
#
# @example Scope an expectation to one item
#   within(:sortable_item, form_attribute) { expect(page).to have_button("Drag to reorder") }
#
# Filters: `type:` and `label:`, matching the item's type and label values.

Capybara.add_selector(:sortable_item, locator_type: [ActiveRecord::Base, String, Integer]) do
  label "sortable-lists item"

  css do |locator|
    css = "[data-controller~='sortable-lists--item']"
    css += "[data-sortable-lists--item-id-value='#{locator.try(:id) || locator}']" unless locator.nil?
    css
  end

  node_filter(:type) do |node, type|
    actual = node[:"data-sortable-lists--item-type-value"]

    (actual == type.to_s).tap do |res|
      add_error("Expected type to be #{type.to_s.inspect} but it was #{actual.inspect}") unless res
    end
  end

  node_filter(:label) do |node, label|
    actual = node[:"data-sortable-lists--item-label-value"]

    (actual == label).tap do |res|
      add_error("Expected label to be #{label.inspect} but it was #{actual.inspect}") unless res
    end
  end

  describe_node_filters do |type: nil, label: nil, **|
    desc = +""
    desc << " of type #{type.to_s.inspect}" if type
    desc << " with label #{label.inspect}" if label
    desc
  end
end

module Capybara
  module RSpecMatchers
    # Shorthand for `have_selector(:sortable_item, ...)`; see the examples above.
    def have_sortable_item(locator = nil, **, &)
      Matchers::HaveSelector.new(:sortable_item, locator, **, &)
    end

    # Shorthand for `have_no_selector(:sortable_item, ...)`.
    def have_no_sortable_item(...)
      Matchers::NegatedMatcher.new(have_sortable_item(...))
    end
  end
end
