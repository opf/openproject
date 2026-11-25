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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackages::Import::CSV::DateParser do
  describe ".date" do
    subject(:date) { described_class.date(raw) }

    context "with a date on its own" do
      let(:raw) { "2026-09-26" }

      it { is_expected.to eq(Date.new(2026, 9, 26)) }
    end

    context "with a month and a day written without a leading zero" do
      let(:raw) { "2026-9-6" }

      it { is_expected.to eq(Date.new(2026, 9, 6)) }
    end

    context "with surrounding whitespace" do
      let(:raw) { "  2026-09-26  " }

      it { is_expected.to eq(Date.new(2026, 9, 26)) }
    end

    context "with a time beside the date, the way a spreadsheet writes a date column" do
      let(:raw) { "2026-09-26 00:00:00" }

      it { is_expected.to eq(Date.new(2026, 9, 26)) }
    end

    # The cell names a date, so the date it names is the date it gets, rather than the one the
    # offset would move it to.
    context "with a zone that would carry the moment into the next day" do
      let(:raw) { "2026-09-26T23:30:00-05:00" }

      it { is_expected.to eq(Date.new(2026, 9, 26)) }
    end

    context "with a day the month does not have" do
      let(:raw) { "2026-02-30" }

      it { is_expected.to be_nil }
    end

    context "with slashes in place of the dashes" do
      let(:raw) { "2026/09/26" }

      it { is_expected.to eq(Date.new(2026, 9, 26)) }
    end

    context "with a date written in any other order" do
      it "reads none of it, rather than guessing at which half is the month" do
        expect(described_class.date("09/29/2026")).to be_nil
        expect(described_class.date("29/09/2026")).to be_nil
        expect(described_class.date("09-29-2026")).to be_nil
        expect(described_class.date("29.09.2026")).to be_nil
      end
    end

    context "with the two separators mixed" do
      let(:raw) { "2026-09/26" }

      it { is_expected.to be_nil }
    end

    context "with numbers that are no date at all" do
      let(:raw) { "2026-09-31" }

      it { is_expected.to be_nil }
    end

    context "with something that is not a date at all" do
      it "reads none of it" do
        expect(described_class.date("yesterday")).to be_nil
        expect(described_class.date("08:09")).to be_nil
        expect(described_class.date("2026")).to be_nil
        expect(described_class.date("")).to be_nil
        expect(described_class.date(nil)).to be_nil
      end
    end
  end

  describe ".timestamp" do
    subject(:timestamp) { described_class.timestamp(raw) }

    context "with the shape the template writes" do
      let(:raw) { "2026-09-26T08:09:52Z" }

      it { is_expected.to eq(Time.utc(2026, 9, 26, 8, 9, 52)) }
    end

    context "with a space in place of the T" do
      let(:raw) { "2026-09-26 08:09:52" }

      it { is_expected.to eq(Time.utc(2026, 9, 26, 8, 9, 52)) }
    end

    context "without the seconds" do
      let(:raw) { "2026-09-26 08:09" }

      it { is_expected.to eq(Time.utc(2026, 9, 26, 8, 9)) }
    end

    context "without a zone" do
      let(:raw) { "2026-09-26T08:09:52" }

      it { is_expected.to eq(Time.utc(2026, 9, 26, 8, 9, 52)) }

      it "reads the cell in the time zone of the user running the import" do
        Time.use_zone("Europe/Berlin") do
          expect(described_class.timestamp(raw)).to eq(Time.utc(2026, 9, 26, 6, 9, 52))
        end
      end
    end

    context "with an offset" do
      it "reads the moment the offset names" do
        expect(described_class.timestamp("2026-09-26T08:09:52+02:00")).to eq(Time.utc(2026, 9, 26, 6, 9, 52))
        expect(described_class.timestamp("2026-09-26T08:09:52+0200")).to eq(Time.utc(2026, 9, 26, 6, 9, 52))
      end
    end

    context "with a fraction of a second" do
      let(:raw) { "2026-09-26T08:09:52.123Z" }

      it { is_expected.to eq(Time.utc(2026, 9, 26, 8, 9, 52, 123_000)) }
    end

    context "with a date on its own" do
      let(:raw) { "2026-09-26" }

      it { is_expected.to eq(Time.utc(2026, 9, 26)) }
    end

    context "with a meridian" do
      it "reads the clock the cell shows" do
        expect(described_class.timestamp("2026-09-29 10:40 AM")).to eq(Time.utc(2026, 9, 29, 10, 40))
        expect(described_class.timestamp("2026/09/29 10:40 pm")).to eq(Time.utc(2026, 9, 29, 22, 40))
        expect(described_class.timestamp("2026-09-26 12:00 AM")).to eq(Time.utc(2026, 9, 26))
      end
    end

    context "with a zone named rather than written as an offset" do
      it "reads the zone where Ruby can place it" do
        expect(described_class.timestamp("2026-09-29 10:40 UTC")).to eq(Time.utc(2026, 9, 29, 10, 40))
        expect(described_class.timestamp("2026-09-26 10:40 CET")).to eq(Time.utc(2026, 9, 26, 9, 40))
      end

      # Reading it in the importing user's zone instead would be a silent hour or two out.
      it "reads none of it where Ruby cannot" do
        expect(described_class.timestamp("2026-09-26 10:40 FOO")).to be_nil
      end
    end

    context "with a time that no clock shows" do
      it "reads none of it" do
        expect(described_class.timestamp("2026-09-26 24:00")).to be_nil
        expect(described_class.timestamp("2026-09-26 08:60")).to be_nil
        expect(described_class.timestamp("2026-09-26 23:00 PM")).to be_nil
      end
    end

    context "with something that is not a moment at all" do
      it "reads none of it" do
        expect(described_class.timestamp("last Tuesday")).to be_nil
        expect(described_class.timestamp("2026-09-26 and a bit")).to be_nil
        expect(described_class.timestamp(nil)).to be_nil
      end
    end
  end
end
