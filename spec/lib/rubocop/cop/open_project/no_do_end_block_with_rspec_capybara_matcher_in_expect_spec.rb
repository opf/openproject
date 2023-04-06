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

require 'spec_helper'
require 'rubocop/cop/open_project/no_do_end_block_with_rspec_capybara_matcher_in_expect'

RSpec.describe RuboCop::Cop::OpenProject::NoDoEndBlockWithRSpecCapybaraMatcherInExpect do
  include RuboCop::RSpec::ExpectOffense
  include_context 'config'

  context 'when using `do .. end` syntax with rspec matcher' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        expect(page).to have_selector("input") do |input|
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ The `do .. end` block is associated with `to` and not with Capybara matcher `have_selector`.
        end
      RUBY
    end

    it 'matches only Capybara matchers' do
      expect_no_offenses(<<~RUBY)
        expect(foo).to have_received(:bar) do |value|
          value == 'hello world'
        end
      RUBY
    end
  end

  context 'when using `{ .. }` syntax with rspec matcher' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        expect(page).to have_selector("input") { |input| }
      RUBY
    end
  end
end
