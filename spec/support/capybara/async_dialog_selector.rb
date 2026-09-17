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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

Capybara.add_selector(:async_dialog_trigger, locator_type: [String, Symbol]) do
  label "async dialog trigger"

  xpath do |locator, **|
    xpath = XPath.descendant(:a, :button)[XPath.attr(:"data-controller").contains_word("async-dialog")]

    unless locator.nil?
      locator = locator.to_s
      matchers = [
        XPath.string.n.is(locator),
        XPath.attr(:"aria-label").is(locator)
      ]
      xpath = xpath[matchers.reduce(:|)]
    end

    xpath
  end

  node_filter(:href) do |node, href|
    (node[:href] == href).tap do |res|
      add_error("Expected href to be #{href.inspect} but it was #{node[:href].inspect}") unless res
    end
  end

  describe_expression_filters do |href: nil, **|
    " with href #{href.inspect}" if href
  end

  filter_set(:capybara_accessible_selectors, %i[aria described_by])
end

module Capybara
  module RSpecMatchers
    def have_async_dialog_trigger(locator = nil, **, &)
      Matchers::HaveSelector.new(:async_dialog_trigger, locator, **, &)
    end

    def have_no_async_dialog_trigger(...)
      Matchers::NegatedMatcher.new(have_async_dialog_trigger(...))
    end
  end
end
