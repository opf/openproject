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

RSpec.describe OpenProject::MultiKeyHash do
  describe ".expand" do
    it "expands a single key" do
      expect(described_class.expand(foo: 1)).to eq({ foo: 1 })
    end

    it "expands an array key into multiple keys" do
      expect(described_class.expand(%i[a b] => 3, c: 4)).to eq({ a: 3, b: 3, c: 4 })
    end

    it "returns empty hash for empty input" do
      expect(described_class.expand).to eq({})
    end

    it "handles string keys" do
      expect(described_class.expand(%w[foo bar] => 7)).to eq({ "foo" => 7, "bar" => 7 })
    end

    it "handles integer keys" do
      expect(described_class.expand([1, 2] => 8)).to eq({ 1 => 8, 2 => 8 })
    end

    it "handles nil as a key" do
      expect(described_class.expand([nil, :foo] => 10)).to eq({ nil => 10, foo: 10 })
    end

    it "handles nested arrays as keys" do
      expect(described_class.expand([%i[a b], :c] => 9)).to eq({ %i[a b] => 9, c: 9 })
    end

    it "overwrites duplicate keys with last value" do
      expect(described_class.expand(%i[foo bar] => 1, %i[foo baz] => 2)).to eq({ foo: 2, bar: 1, baz: 2 })
    end
  end
end
