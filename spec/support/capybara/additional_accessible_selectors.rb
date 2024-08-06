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

Capybara.add_selector(:list) do
  xpath { ".//ul | .//ol" }
end

Capybara.add_selector(:list_item) do
  label "list item"

  xpath { ".//li" }

  expression_filter(:position) do |xpath, position|
    position ? "#{xpath}[#{position}]" : xpath
  end

  describe_expression_filters do |position: nil, **|
    position ? " at position #{position}" : ""
  end
end

module Capybara
  module RSpecMatchers
    %i[list list_item].each do |selector|
      define_method :"have_#{selector}" do |locator = nil, **options, &optional_filter_block|
        Matchers::HaveSelector.new(selector, locator, **options, &optional_filter_block)
      end

      define_method :"have_no_#{selector}" do |*args, **options, &optional_filter_block|
        Matchers::NegatedMatcher.new(send(:"have_#{selector}", *args, **options, &optional_filter_block))
      end
    end
  end
end
