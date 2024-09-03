# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe PercentageConverter do
  describe ".parse" do
    it "returns nil when given blank strings or nil" do
      expect(described_class.parse("")).to be_nil
      expect(described_class.parse("  ")).to be_nil
      expect(described_class.parse(" \t ")).to be_nil
      expect(described_class.parse(nil)).to be_nil
    end

    it "returns 0.0 when given '0%'" do
      expect(described_class.parse("0%")).to be(0.0)
      expect(described_class.parse("0 %")).to be(0.0)
      expect(described_class.parse(" 0 % ")).to be(0.0)
    end

    it "returns a float when given a string repsenting an integer" do
      expect(described_class.parse("50")).to be(50.0)
      expect(described_class.parse(" 50 ")).to be(50.0)
      expect(described_class.parse(" -23 ")).to be(-23.0)
      expect(described_class.parse(" +1278 ")).to be(1278.0)
      expect(described_class.parse(" -0 ")).to eq(0.0)
      expect(described_class.parse(" +0% ")).to be(0.0)
    end

    it "returns a float when given a string representing a float" do
      expect(described_class.parse("5.")).to be(5.0)
      expect(described_class.parse("5.%")).to be(5.0)
      expect(described_class.parse("5.7%")).to be(5.7)
      expect(described_class.parse("5.75")).to be(5.75)
      expect(described_class.parse("5.75%")).to be(5.75)
      expect(described_class.parse("5.75 %")).to be(5.75)
      expect(described_class.parse("  -5.75  %  ")).to be(-5.75)
      expect(described_class.parse("+5.75 %")).to be(5.75)
      expect(described_class.parse("  123.321 %  ")).to be(123.321)
      expect(described_class.parse("-456.654 %")).to be(-456.654)
    end

    it "does not get tricked with octals representation" do
      expect(described_class.parse("09")).to be(9.0)
      expect(described_class.parse("010")).to be(10.0)
    end

    it "raises a `ParseError` if it's not a valid percentage" do
      expect { described_class.parse("invalid percentage") }.to raise_error(PercentageConverter::ParseError)
    end
  end

  describe ".valid?" do
    it "returns true for integers" do
      expect(described_class.valid?(0)).to be(true)
      expect(described_class.valid?(100)).to be(true)
      expect(described_class.valid?(789)).to be(true)
      expect(described_class.valid?(-456)).to be(true)
    end

    it "returns true for floats" do
      expect(described_class.valid?(0.0)).to be(true)
      expect(described_class.valid?(-0.0)).to be(true)
      expect(described_class.valid?(23.1)).to be(true)
      expect(described_class.valid?(100.2)).to be(true)
      expect(described_class.valid?(789.3)).to be(true)
      expect(described_class.valid?(-456.4)).to be(true)
    end

    it "returns true for blank values" do
      expect(described_class.valid?(nil)).to be(true)
      expect(described_class.valid?("")).to be(true)
      expect(described_class.valid?("  ")).to be(true)
      expect(described_class.valid?(" \t ")).to be(true)
    end

    it "returns true for strings representing a number or a valid percentage" do
      expect(described_class.valid?("50")).to be(true)
      expect(described_class.valid?(" 50 ")).to be(true)
      expect(described_class.valid?(" -23 ")).to be(true)
      expect(described_class.valid?(" +1278 ")).to be(true)
      expect(described_class.valid?(" -0 ")).to be(true)
      expect(described_class.valid?(" +0% ")).to be(true)
      expect(described_class.valid?("5.")).to be(true)
      expect(described_class.valid?("5.%")).to be(true)
      expect(described_class.valid?("  -5.75   %  ")).to be(true)
      expect(described_class.valid?("  1234.0 %  ")).to be(true)
    end

    it "rreturns false for strings not representing a number" do
      expect(described_class.valid?("invalid")).to be(false)
      expect(described_class.valid?("-")).to be(false)
      expect(described_class.valid?("+")).to be(false)
      expect(described_class.valid?("日")).to be(false)
      expect(described_class.valid?("invalid 123")).to be(false)
      expect(described_class.valid?("123 invalid")).to be(false)
      expect(described_class.valid?("-  23")).to be(false)
      expect(described_class.valid?("123.4.5")).to be(false)
      expect(described_class.valid?("1'234.5")).to be(false)
      expect(described_class.valid?("1,234.5")).to be(false)
      expect(described_class.valid?("12%%")).to be(false)
      expect(described_class.valid?("12%.4")).to be(false)
    end
  end
end
