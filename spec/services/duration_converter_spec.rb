# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2024 the OpenProject GmbH
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

  describe ".output" do
    it "returns nil when given nil" do
      expect(described_class.output(nil)).to be_nil
    end

    it "returns 0 h when given 0" do
      expect(described_class.output(0)).to eq("0h")
    end

    it "works with ChronicDuration defaults otherwise in :short format" do
      expect(described_class.output(5.75))
        .to eq("5h 45m")
    end

    it "handles floating point numbers gracefully" do
      expect(described_class.output(0.28))
        .to eq("16m 48s")
    end
  end
end
