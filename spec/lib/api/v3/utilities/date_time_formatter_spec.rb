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

RSpec.describe API::V3::Utilities::DateTimeFormatter do
  subject { described_class }

  let(:date) { Time.zone.today }
  let(:datetime) { DateTime.now }

  shared_examples_for "can format nil" do
    it "accepts nil if asked to" do
      expect(subject.send(method, nil, allow_nil: true)).to be_nil
    end

    it "returns usual result for non-nils" do
      expected = subject.send(method, input)
      expect(subject.send(method, input, allow_nil: true)).to eq(expected)
    end
  end

  shared_examples_for "can parse nil" do
    it "accepts nil if asked to" do
      expect(subject.send(method, nil, "prop", allow_nil: true)).to be_nil
    end

    it "returns usual result for non-nils" do
      expected = subject.send(method, input, "prop")
      expect(subject.send(method, input, "prop", allow_nil: true)).to eq(expected)
    end
  end

  shared_examples_for "rejects durations with parsing errors" do
    it "rejects parsing non sense" do
      expect do
        subject.send(method, "foo", "prop")
      end.to raise_error(API::Errors::PropertyFormatError)
    end

    it "rejects parsing pure number strings" do
      expect do
        subject.send(method, "5", "prop")
      end.to raise_error(API::Errors::PropertyFormatError)
    end

    it "rejects parsing pure numbers" do
      expect do
        subject.send(method, 5, "prop")
      end.to raise_error(API::Errors::PropertyFormatError)
    end
  end

  describe "format_date" do
    it "formats dates" do
      expect(subject.format_date(date)).to eq(date.iso8601)
    end

    it "formats datetimes" do
      expect(subject.format_date(datetime)).to eq(datetime.to_date.iso8601)
    end

    it_behaves_like "can format nil" do
      let(:method) { :format_date }
      let(:input) { date }
    end
  end

  describe "parse_date" do
    it "parses ISO 8601 dates" do
      expect(subject.parse_date(date.iso8601, "prop")).to eq(date)
    end

    it "rejects parsing non ISO date formats" do
      bad_format = date.strftime("%d.%m.%Y")
      expect do
        subject.parse_date(bad_format, "prop")
      end.to raise_error(API::Errors::PropertyFormatError) do |error| # rubocop:disable Style/MultilineBlockChain
        expect(error.message).to include("Invalid format for property 'prop'")
        expect(error.message).to include("Expected format like 'YYYY-MM-DD (ISO 8601 date only)'")
      end
    end

    it "rejects parsing ISO 8601 date + time formats" do
      bad_format = datetime.iso8601
      expect do
        subject.parse_date(bad_format, "prop")
      end.to raise_error(API::Errors::PropertyFormatError) do |error| # rubocop:disable Style/MultilineBlockChain
        expect(error.message).to include("Invalid format for property 'prop'")
        expect(error.message).to include("Expected format like 'YYYY-MM-DD (ISO 8601 date only)'")
      end
    end

    it_behaves_like "can parse nil" do
      let(:method) { :parse_date }
      let(:input) { date.iso8601 }
    end
  end

  describe "format_datetime" do
    it "formats dates" do
      expect(subject.format_datetime(date)).to eq(date.to_datetime.utc.iso8601(3))
    end

    it "formats datetimes" do
      expect(subject.format_datetime(datetime)).to eq(datetime.utc.iso8601(3))
    end

    it_behaves_like "can format nil" do
      let(:method) { :format_datetime }
      let(:input) { datetime }
    end
  end

  describe "parse_datetime" do
    it "parses ISO 8601 datetimes" do
      expect(subject.parse_datetime(datetime.utc.iso8601(9), "prop")).to eq(datetime)
      expect(subject.parse_datetime("1999-12-31T14:15:16", "prop"))
                .to eq(DateTime.new(1999, 12, 31, 14, 15, 16))
      expect(subject.parse_datetime("1999-12-31", "prop"))
                .to eq(DateTime.new(1999, 12, 31, 0, 0, 0))
      expect(subject.parse_datetime("1999-12-31T14:15:16Z", "prop"))
                .to eq(DateTime.new(1999, 12, 31, 14, 15, 16, "+00:00"))
      expect(subject.parse_datetime("1999-12-31T14:15:16+02:30", "prop"))
                .to eq(DateTime.new(1999, 12, 31, 11, 45, 16, "+00:00"))
      expect(subject.parse_datetime("1999-12-31T14:15:16.4242", "prop"))
                .to eq(DateTime.new(1999, 12, 31, 14, 15, 16.4242))
    end

    it "rejects parsing non ISO date formats" do
      bad_format = datetime.strftime("%d.%m.%Y")
      expect do
        subject.parse_datetime(bad_format, "prop")
      end.to raise_error(API::Errors::PropertyFormatError) do |error| # rubocop:disable Style/MultilineBlockChain
        expect(error.message).to include("Invalid format for property 'prop'")
        expect(error.message).to include("Expected format like 'YYYY-MM-DDThh:mm:ss[.lll][+hh:mm] " +
          "(any compatible ISO 8601 datetime)'")
      end
    end

    it_behaves_like "can parse nil" do
      let(:method) { :parse_datetime }
      let(:input) { datetime.iso8601(9) }
    end
  end

  describe "format_duration_from_hours" do
    it "formats floats" do
      expect(subject.format_duration_from_hours(5.0)).to eq("PT5H")
    end

    it "formats fractional floats" do
      expect(subject.format_duration_from_hours(5.5)).to eq("PT5H30M")
    end

    it "includes seconds" do
      expect(subject.format_duration_from_hours(5.501)).to eq("PT5H30M3S")
    end

    it "formats ints" do
      expect(subject.format_duration_from_hours(5)).to eq("PT5H")
    end

    it_behaves_like "can format nil" do
      let(:method) { :format_duration_from_hours }
      let(:input) { 5 }
    end
  end

  describe "parse_duration_to_hours" do
    it "parses ISO 8601 durations of full hours" do
      expect(subject.parse_duration_to_hours("PT5H", "prop")).to eq(5.0)
    end

    it "parses ISO 8601 durations of fractional hours" do
      expect(subject.parse_duration_to_hours("PT5H30M", "prop")).to eq(5.5)
    end

    it "parses ISO 8601 durations of days" do
      expect(subject.parse_duration_to_hours("P1D", "prop")).to eq(24.0)
    end

    it_behaves_like "rejects durations with parsing errors" do
      let(:method) { :parse_duration_to_hours }
    end

    it_behaves_like "can parse nil" do
      let(:method) { :parse_duration_to_hours }
      let(:input) { "PT5H" }
    end
  end

  describe "format_duration_from_days" do
    it "formats floats" do
      expect(subject.format_duration_from_days(5.0)).to eq("P5D")
    end

    it "formats fractional floats" do
      expect(subject.format_duration_from_days(5.5)).to eq("P5DT12H")
    end

    it "includes minutes and seconds" do
      expect(subject.format_duration_from_days(5.501)).to eq("P5DT12H1M26S")
    end

    it "formats ints" do
      expect(subject.format_duration_from_days(5)).to eq("P5D")
    end

    it_behaves_like "can format nil" do
      let(:method) { :format_duration_from_days }
      let(:input) { 5 }
    end
  end

  describe "parse_duration_to_days" do
    it "parses ISO 8601 durations of full days" do
      expect(subject.parse_duration_to_days("P5D", "prop")).to eq(5)
    end

    it "parses ISO 8601 durations of fractional days as whole" do
      expect(subject.parse_duration_to_days("P5DT18H30M", "prop")).to eq(5)
    end

    it "parses ISO 8601 durations of hours as 0 days" do
      expect(subject.parse_duration_to_days("PT1H30M", "prop")).to eq(0)
    end

    it_behaves_like "rejects durations with parsing errors" do
      let(:method) { :parse_duration_to_days }
    end

    it_behaves_like "can parse nil" do
      let(:method) { :parse_duration_to_days }
      let(:input) { "PT5H" }
    end
  end
end
