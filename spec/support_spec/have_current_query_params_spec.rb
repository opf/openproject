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

require "spec_helper"

RSpec.describe "have_current_query_params matcher" do # rubocop:disable RSpec/DescribeClass
  let(:session) { Capybara::Session.new(:rack_test, ->(_env) { [200, {}, [""]] }) }

  before { session.visit("/foo?a=1&b[]=2&b[]=3") }

  it "matches exact params" do
    expect(session).to have_current_query_params("a" => "1", "b" => %w[2 3])
  end

  it "matches with composable matchers" do
    expect(session).to have_current_query_params(a_hash_including("a" => "1"))
  end

  it "matches with composable matchers as values" do
    expect(session).to have_current_query_params("a" => anything, "b" => include("3"))
  end

  it "fails on extra params" do
    expect { expect(session).to have_current_query_params("a" => "1") }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end

  it "fails with diff on mismatch" do
    expect { expect(session).to have_current_query_params("a" => "2") }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError, /-"a" => "2".*\+"a" => "1"/m)
  end

  it "matches when negated" do
    expect(session).not_to have_current_query_params(a_hash_including("a" => "2"))
  end

  it "fails when negated on match" do
    expect { expect(session).not_to have_current_query_params(a_hash_including("a" => "1")) }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end

  it "matches with negated alias" do
    expect(session).to have_no_current_query_params(a_hash_including("a" => "2"))
  end

  it "fails with negated alias on match" do
    expect { expect(session).to have_no_current_query_params(a_hash_including("a" => "1")) }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end
end
