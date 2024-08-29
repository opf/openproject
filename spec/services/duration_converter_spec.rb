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

RSpec.describe DurationConverter do
  describe ".parse" do
    it "returns nil when given blank strings or nil" do
      expect(described_class.parse("")).to be_nil
      expect(described_class.parse("  ")).to be_nil
      expect(described_class.parse(" \t ")).to be_nil
      expect(described_class.parse(nil)).to be_nil
    end

    it "returns 0 when given 0 duration" do
      expect(described_class.parse("0 hrs")).to eq(0)
    end

    it "works with ChronicDuration defaults otherwise" do
      expect(described_class.parse("5 hrs 30 mins")).to eq(5.5)
    end

    it "assumes hours as the default unit for input if no other units given" do
      expect(described_class.parse("5.75")).to eq(5.75)
    end

    it "assumes the next logical unit if at least one unit is given" do
      expect(described_class.parse("2h 15")).to eq(2.25)
      expect(described_class.parse("1d 24")).to eq(32)
      expect(described_class.parse("1w 1")).to eq(48)
      expect(described_class.parse("1mo 1")).to eq(200)
      expect(described_class.parse("1mo 1w 1d 1h 30")).to eq(209.5)
    end
  end

  describe ".valid?", :aggregate_failures do
    it "returns true for positive numbers" do
      expect(described_class.valid?(0)).to be(true)
      expect(described_class.valid?(0.0)).to be(true)
      expect(described_class.valid?(100)).to be(true)
      expect(described_class.valid?(100.0)).to be(true)
      expect(described_class.valid?(789)).to be(true)
      expect(described_class.valid?(789.123)).to be(true)
    end

    it "returns false for negative numbers" do
      expect(described_class.valid?(-0.01)).to be(false)
      expect(described_class.valid?(-1)).to be(false)
      expect(described_class.valid?(-1.5)).to be(false)
      expect(described_class.valid?(-456)).to be(false)
      expect(described_class.valid?(-456.789)).to be(false)
    end

    it "returns true for blank values" do
      expect(described_class.valid?(nil)).to be(true)
      expect(described_class.valid?("")).to be(true)
      expect(described_class.valid?("  ")).to be(true)
      expect(described_class.valid?(" \t ")).to be(true)
    end

    it "returns true for strings representing a positive number or a valid duration" do
      expect(described_class.valid?("50")).to be(true)
      expect(described_class.valid?(" 50 ")).to be(true)
      expect(described_class.valid?(" +1278 ")).to be(true)
      expect(described_class.valid?(" -0 ")).to be(true)
      expect(described_class.valid?("  1234.0 h  ")).to be(true)
      expect(described_class.valid?("12h.4")).to be(true) # 12h 0.4m
      expect(described_class.valid?("1 week 2 days 3 hours 5 minutes")).to be(true)
    end

    it "returns false for strings not representing a positive number nor a valid duration" do
      expect(described_class.valid?("invalid")).to be(false)
      expect(described_class.valid?("dsg")).to be(false)
      expect(described_class.valid?(" +0h ")).to be(false)
      expect(described_class.valid?("-5")).to be(false)
      expect(described_class.valid?("-5.6")).to be(false)
      expect(described_class.valid?("5.")).to be(false)
      expect(described_class.valid?("5.h")).to be(false)
      expect(described_class.valid?("-5.75h")).to be(false)
      expect(described_class.valid?("invalid")).to be(false)
      expect(described_class.valid?("-")).to be(false)
      expect(described_class.valid?("+")).to be(false)
      expect(described_class.valid?("日")).to be(false)
      expect(described_class.valid?("invalid 123")).to be(false)
      expect(described_class.valid?("123 invalid")).to be(false)
      expect(described_class.valid?("-  23")).to be(false)
      expect(described_class.valid?("123..5")).to be(false)
      expect(described_class.valid?("1'234.5")).to be(false)
      expect(described_class.valid?("1,234.5")).to be(false)
      expect(described_class.valid?("12mm")).to be(false)
    end
  end

  describe ".output" do
    it "returns nil when given nil" do
      expect(described_class.output(nil)).to be_nil
    end

    it "returns 0h when given 0" do
      expect(described_class.output(0)).to eq("0h")
    end

    context "when duration format is set to days_and_hours",
            with_settings: { duration_format: "days_and_hours" } do
      it "displays the duration in days and hours" do
        expect(described_class.output(5.75))
            .to eq("5.75h")
        expect(described_class.output(5.754321))
          .to eq("5.75h")
        expect(described_class.output(804))
          .to eq("100d 4h")
      end

      it "does not display days if it would be 0 days (like '3h')" do
        expect(described_class.output(3))
          .to eq("3h")
        expect(described_class.output(7))
          .to eq("7h")
        expect(described_class.output(7.99))
          .to eq("7.99h")
      end

      it "displays hours even when it's zero (like '2d 0h')" do
        expect(described_class.output(8))
          .to eq("1d 0h")
        expect(described_class.output(2 * 8))
          .to eq("2d 0h")
      end

      it "ignores seconds and keep the nearest minute, displayed as hours" do
        expect(described_class.output(0.28))
          .to eq("0.28h")
        expect(described_class.output(2.23))
          .to eq("2.23h")
      end

      it "deals well with floating point maths" do
        expect(described_class.output(1.89))
          .to eq("1.89h")
      end
    end

    context "when duration format is set to hours_only",
            with_settings: { duration_format: "hours_only" } do
      it "displays the duration in hours only" do
        expect(described_class.output(0))
            .to eq("0h")
        expect(described_class.output(5.75))
            .to eq("5.75h")
        expect(described_class.output(5.754321))
          .to eq("5.75h")
        expect(described_class.output(8))
          .to eq("8h")
        expect(described_class.output(804.32))
          .to eq("804.32h")
      end

      it "ignores seconds and keep the nearest minute, displayed as hours" do
        expect(described_class.output(0.28))
          .to eq("0.28h")
        expect(described_class.output(2.23))
          .to eq("2.23h")
      end

      it "deals well with floating point maths" do
        expect(described_class.output(1.89))
          .to eq("1.89h")
        expect(described_class.output(1.9997222222)) # 1h59m59s
          .to eq("2h")
        expect(described_class.output(1.9916666667)) # 1h59m30s
          .to eq("1.99h")
      end
    end
  end
end
