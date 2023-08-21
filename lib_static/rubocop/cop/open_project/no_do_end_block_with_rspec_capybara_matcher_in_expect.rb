#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module RuboCop::Cop::OpenProject
  # As +do .. end+ block has less precedence than method call, a +do .. end+
  # block at the end of a rspec matcher will be an argument to the +to+ method,
  # which is not handled by Capybara matchers (teamcapybara/capybara/#2616).
  #
  # # bad
  # expect(page).to have_selector("input") do |input|
  #   input.value == "hello world"
  # end
  #
  # # good
  # expect(page).to have_selector("input") { |input| input.value == "hello world" }
  #
  # # good
  # expect(page).to have_selector("input", value: "hello world")
  #
  # # good
  # match_input_with_hello_world = have_selector("input") do |input|
  #   input.value == "hello world"
  # end
  # expect(page).to match_input_with_hello_world
  #
  # # good
  # expect(foo).to have_received(:bar) do |arg|
  #   arg == :baz
  # end
  #
  class NoDoEndBlockWithRSpecCapybaraMatcherInExpect < RuboCop::Cop::Base
    extend RuboCop::Cop::AutoCorrector

    CAPYBARA_MATCHER_METHODS = %w[selector css xpath text title current_path link button
                                  field checked_field unchecked_field select table
                                  sibling ancestor].flat_map do |matcher_type|
                                    ["have_#{matcher_type}", "have_no_#{matcher_type}"]
                                  end

    MSG = 'The `do .. end` block is associated with `to` and not with Capybara matcher `%<matcher_method>s`.'.freeze

    def_node_matcher :expect_to_with_block?, <<~PATTERN
      # ruby-parse output
      (block
        (send
          (send nil? :expect ...)
          :to
          ...
        )
        ...
      )
    PATTERN

    def_node_matcher :rspec_matcher, <<~PATTERN
      (send
        (send nil? :expect...)
        :to
        (:send nil? $_matcher_method ...)
      )
    PATTERN

    def on_block(node)
      return unless expect_to_with_block?(node)
      return unless capybara_matcher?(node)

      add_offense(offense_range(node), message: offense_message(node))
    end

    private

    def capybara_matcher?(node)
      matcher_name = node.send_node.arguments.first.method_name.to_s
      CAPYBARA_MATCHER_METHODS.include?(matcher_name)
    end

    def offense_range(node)
      node.send_node.loc.selector.join(node.loc.end)
    end

    def offense_message(node)
      rspec_matcher(node.send_node) do |matcher_method|
        format(MSG, matcher_method:)
      end
    end
  end
end
