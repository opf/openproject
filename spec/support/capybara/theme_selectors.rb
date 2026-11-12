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

Capybara.add_selector :theme do
  label "Theme"

  xpath do |locator|
    xpath = XPath.descendant(:body)
    xpath = builder(xpath).add_attribute_conditions("data-color-mode": locator) if locator
    xpath
  end

  expression_filter(:contrast) do |expr, contrast|
    if contrast
      # Extract the theme from the existing expression
      theme_match = expr.to_s.match(/data-color-mode='([^']+)'/)
      if theme_match
        theme = theme_match[1]
        contrast_suffix = "_high_contrast"
        builder(expr).add_attribute_conditions("data-#{theme}-theme": "#{theme}#{contrast_suffix}")
      else
        expr
      end
    else
      expr
    end
  end

  describe_expression_filters do |contrast: nil, **|
    contrast ? " with high contrast" : ""
  end
end

Capybara.add_selector :auto_theme_config do
  label "Auto Theme Config"

  xpath do |_locator|
    xpath = XPath.descendant(:body)
    xpath = builder(xpath).add_attribute_conditions("data-auto-theme-switcher-theme-value": "sync_with_os")
    xpath
  end

  expression_filter(:force_light_contrast) do |expr, enabled|
    if enabled
      builder(expr).add_attribute_conditions("data-auto-theme-switcher-force-light-contrast-value": "true")
    else
      expr
    end
  end

  expression_filter(:force_dark_contrast) do |expr, enabled|
    if enabled
      builder(expr).add_attribute_conditions("data-auto-theme-switcher-force-dark-contrast-value": "true")
    else
      expr
    end
  end

  describe_expression_filters do |force_light_contrast: nil, force_dark_contrast: nil, **|
    desc = +""
    desc << " with forced light contrast" if force_light_contrast
    desc << " with forced dark contrast" if force_dark_contrast
    desc
  end
end

module Capybara
  module RSpecMatchers
    def have_theme(locator = nil, contrast: false, **, &)
      Matchers::HaveSelector.new(:theme, locator, contrast:, **, &)
    end

    def have_no_theme(locator = nil, **, &)
      Matchers::NegatedMatcher.new(have_theme(locator, **, &))
    end

    def have_auto_theme_config(force_light_contrast: false, force_dark_contrast: false, **, &)
      Matchers::HaveSelector.new(:auto_theme_config, nil,
                                 force_light_contrast:,
                                 force_dark_contrast:,
                                 **, &)
    end
  end
end
