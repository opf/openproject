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

Capybara.add_selector :primer_label, locator_type: [String, Symbol] do
  label "Primer Label"

  css do |*|
    ".Label"
  end

  locator_filter skip_if: nil do |node, locator, exact:, **|
    text = if node[:"aria-labelledby"]
             CapybaraAccessibleSelectors::Helpers.element_labelledby(node)
           elsif node[:"aria-label"]
             node[:"aria-label"]
           else
             node.text
           end
    text.public_send(exact ? :eql? : :include?, locator.to_s)
  end

  # Use `node_filter` instead of `expression_filter` to have a better failure
  # message when the selector fails: `expression_filter` modifies the initial
  # query and elements without the expected scheme are not returned.
  # `node_filter` applies the filter on the elements returned by the query so
  # that error message can list them if none matches.
  node_filter :scheme do |node, scheme|
    actual = node[:class].scan(/(?<=Label--)[\w-]+/)
    scheme = scheme.to_s

    actual.include?(scheme).tap do |res|
      actual_values = actual.any? ? actual.map(&:inspect).to_sentence : "not set"
      add_error("Expected scheme to be #{scheme.inspect} but was #{actual_values}") unless res
    end
  end

  describe_expression_filters do |scheme: nil, **|
    " with scheme #{scheme.inspect}" if scheme
  end

  filter_set(:capybara_accessible_selectors, %i[aria described_by])
end

Capybara.add_selector :primer_text, locator_type: [String] do
  label "Primer Text"

  xpath do |locator, **options|
    xpath = XPath.descendant(:span)
    xpath = xpath[XPath.attr(:class).contains_word(options[:class])] if options[:class]
    unless locator.nil?
      locator = locator.to_s
      xpath = xpath[XPath.string.n.is(locator)]
    end
    xpath
  end

  # Use `node_filter` instead of `expression_filter` to have a better failure
  # message when the selector fails: `expression_filter` modifies the initial
  # query and elements without the expected color are not returned.
  # `node_filter` applies the filter on the elements returned by the query so
  # that error message can list them if none matches.
  node_filter :color do |node, color|
    class_attr = node[:class]
    next false unless class_attr

    actual = class_attr.scan(/(?<=color-fg-)[\w-]+/)
    color = color.to_s

    actual.include?(color).tap do |res|
      actual_values = actual.any? ? actual.map(&:inspect).to_sentence : "not set"
      add_error("Expected color to be #{color.inspect} but was #{actual_values}") unless res
    end
  end

  describe_expression_filters do |color: nil, **|
    " with color #{color.inspect}" if color
  end

  filter_set(:capybara_accessible_selectors, %i[aria described_by])
end

Capybara.add_selector :octicon, locator_type: [String, Symbol] do
  label "Octicon"

  css do |locator|
    css_selector = "svg.octicon"
    css_selector += ".octicon-#{locator.to_s.downcase}" if locator
    css_selector
  end

  expression_filter(:size, valid_values: [Numeric, *Primer::Beta::Octicon::SIZE_OPTIONS]) do |expr, size|
    px_size = size.is_a?(Numeric) ? size : Primer::Beta::Octicon::SIZE_MAPPINGS.fetch(size)
    builder(expr).add_attribute_conditions(width: px_size, height: px_size)
  end

  describe_expression_filters do |size: nil, **|
    desc = +""
    desc << (size.is_a?(Numeric) ? " with size #{size}px" : " with #{size.inspect} size") if size.present?
    desc
  end

  filter_set(:capybara_accessible_selectors, %i[aria described_by])
end

module Capybara
  module RSpecMatchers
    def have_primer_label(locator = nil, **, &)
      Matchers::HaveSelector.new(:primer_label, locator, **, &)
    end

    def have_no_primer_label(...)
      Matchers::NegatedMatcher.new(have_primer_label(...))
    end

    def have_primer_text(locator = nil, **, &)
      Matchers::HaveSelector.new(:primer_text, locator, **, &)
    end

    def have_no_primer_text(...)
      Matchers::NegatedMatcher.new(have_primer_text(...))
    end

    def have_octicon(locator = nil, **, &)
      Matchers::HaveSelector.new(:octicon, locator, **, &)
    end

    def have_no_octicon(...)
      Matchers::NegatedMatcher.new(have_octicon(...))
    end
  end
end
