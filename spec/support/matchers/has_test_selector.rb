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
RSpec::Matchers.define :have_test_selector do |expected, **args|
  include TestSelectorFinders

  match do |page|
    @actual_args = args.dup
    @selector_name = test_selector(expected)
    page.has_selector?(@selector_name, **args)
  end

  match_when_negated do |page|
    @actual_args = args.dup
    @selector_name = test_selector(expected)
    page.has_no_selector?(@selector_name, **args)
  end

  failure_message do |page|
    message = "expected page to have test selector #{expected}"

    if @actual_args.key?(:text)
      message << " with text #{@actual_args[:text].to_s.inspect}"
    end

    # Try to find the actual element without text filter to provide more context
    found_elements = []
    begin
      args_without_text = @actual_args.dup
      args_without_text.delete(:text)

      # Only search for visible elements with a short timeout
      search_args = args_without_text.merge(visible: true, wait: 0)
      page.all(@selector_name, **search_args).each do |element| # rubocop:disable Rails/FindEach
        found_elements << element.text.to_s.strip
      end

      if found_elements.any?
        message << ". Also found: #{found_elements.map(&:inspect).join(', ')}, which matched the selector but not all filters."
      end
    rescue StandardError
      # Ignore errors during the additional context gathering
    end

    message
  end

  failure_message_when_negated do
    "expected page not to have test selector #{expected}"
  end
end
