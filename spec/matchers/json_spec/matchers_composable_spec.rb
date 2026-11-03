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

require "rails_helper"

RSpec.describe JsonSpec::Matchers, "made composable" do
  let(:json) { '{"foo":1,"bar":[2,3]}' }

  describe "be_json_eql" do
    let(:matches) { be_json_eql({ bar: [2, 3], foo: 1 }.to_json) }
    let(:doesnt) { be_json_eql({ foo: 1, bar: [2, 4] }.to_json) }

    it "using include" do
      expect([json]).to include(matches)
      expect([json]).not_to include(doesnt)
    end

    it "using match" do
      expect([json]).to match([matches])
      expect([json]).not_to match([doesnt])
    end
  end

  describe "include_json" do
    let(:matches) { include_json([2, 3].to_json) }
    let(:doesnt) { include_json([2, 4].to_json) }

    it "using include" do
      expect([json]).to include(matches)
      expect([json]).not_to include(doesnt)
    end

    it "using match" do
      expect([json]).to match([matches])
      expect([json]).not_to match([doesnt])
    end
  end

  describe "have_json_path" do
    let(:matches) { have_json_path("bar") }
    let(:doesnt) { have_json_path("baz") }

    it "using include" do
      expect([json]).to include(matches)
      expect([json]).not_to include(doesnt)
    end

    it "using match" do
      expect([json]).to match([matches])
      expect([json]).not_to match([doesnt])
    end
  end

  describe "have_json_type" do
    let(:matches) { have_json_type(Integer).at_path("foo") }
    let(:doesnt) { have_json_type(Integer).at_path("bar") }

    it "using include" do
      expect([json]).to include(matches)
      expect([json]).not_to include(doesnt)
    end

    it "using match" do
      expect([json]).to match([matches])
      expect([json]).not_to match([doesnt])
    end
  end

  describe "have_json_size" do
    let(:matches) { have_json_size(2).at_path("bar") }
    let(:doesnt) { have_json_size(3).at_path("bar") }

    it "using include" do
      expect([json]).to include(matches)
      expect([json]).not_to include(doesnt)
    end

    it "using match" do
      expect([json]).to match([matches])
      expect([json]).not_to match([doesnt])
    end
  end
end
