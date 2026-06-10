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

require "spec_helper"

RSpec.describe OpPrimer::AttributesHelper do
  subject(:helper) { Class.new { include OpPrimer::AttributesHelper }.new }

  describe "#merge_data" do
    it "concatenates the controller key across hashes" do
      merged = helper.merge_data(
        { data: { controller: "a" } },
        { data: { controller: "b" } }
      )

      expect(merged).to eq(controller: "a b")
    end

    it "still concatenates the upstream plural keys" do
      merged = helper.merge_data(
        { data: { target: "foo" } },
        { "data-target": "bar" }
      )

      expect(merged).to eq(target: "foo bar")
    end

    it "keeps non-plural keys last-wins (parity with Primer)" do
      merged = helper.merge_data(
        { data: { foo: "first" } },
        { data: { foo: "second" } }
      )

      expect(merged).to eq(foo: "second")
    end

    it "removes the merged data keys from the source hashes" do
      hash1 = { data: { controller: "a" }, keep: "x" }
      hash2 = { "data-controller": "b", keep: "y" }

      helper.merge_data(hash1, hash2)

      expect(hash1).to eq(keep: "x")
      expect(hash2).to eq(keep: "y")
    end
  end
end
