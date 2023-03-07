#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

describe Timestamp do
  describe ".new" do
    describe "when calling without argument" do
      subject { described_class.new }

      it "returns Timestamp.now" do
        expect(subject.to_s).to eq described_class.now.to_s
      end
    end

    describe "when providing an ISO8601 String" do
      subject { described_class.new("PT10S") }

      it "returns a described_class" do
        expect(subject).to be_a described_class
      end

      specify "the argument is retrievable via to_s" do
        expect(subject.to_s).to eq "PT10S"
      end
    end

    describe "when providing a Time" do
      let(:time) { Time.zone.now }

      subject { described_class.new(time) }

      it "returns an absolute described_class representing that time (up to full seconds)" do
        expect(subject).to be_a described_class
        expect(subject.relative?).to be false
        expect(subject.to_time).to eq Time.zone.at(time.to_i)
      end
    end

    describe "when providing a non-supported object" do
      subject { described_class.new(:foo) }

      it "raises an error" do
        expect { subject }.to raise_error described_class::Exception
      end
    end
  end

  describe ".now" do
    subject { described_class.now }

    it "returns a described_class" do
      expect(subject).to be_a described_class
    end

    it "returns a relative timestamp" do
      expect(subject.relative?).to be true
    end

    it "corresponds to a duration of 0 seconds (ago)" do
      expect(subject.to_duration).to eq ActiveSupport::Duration.build(0)
    end
  end

  describe ".parse" do
    describe "when providing a valid ISO8601 duration" do
      subject { described_class.parse("PT10S") }

      it "returns a described_class representing a time ago that duration" do
        expect(subject).to be_a described_class
        expect(subject.to_s).to eq "PT10S"
        expect(subject.to_duration).to eq ActiveSupport::Duration.build(10)
        expect(subject.relative?).to be true
      end
    end

    describe "when providing a valid ISO8601 time" do
      subject { described_class.parse("2022-10-29T21:55:58Z") }

      it "returns a described_class representing that absolute time" do
        expect(subject).to be_a described_class
        expect(subject.to_s).to eq "2022-10-29T21:55:58Z"
        expect(subject.to_time).to eq Time.zone.parse("2022-10-29T21:55:58Z")
        expect(subject.relative?).to be false
      end
    end

    describe "when providing a special shortcut value" do
      describe "now" do
        subject { described_class.parse("now") }

        it "returns a Timestamp representing the current time" do
          expect(subject).to be_a described_class
          expect(subject.to_iso8601).to eq "PT0S"
          expect(subject.relative?).to be true
        end
      end

      describe "-1y" do
        subject { described_class.parse("-1y") }

        it "returns a Timestamp representing a time ago that duration" do
          expect(subject).to be_a described_class
          expect(subject.to_iso8601).to eq "P-1Y"
          expect(subject.to_duration).to eq ActiveSupport::Duration.build(-1.year)
          expect(subject.relative?).to be true
        end
      end

      describe "-1y2m" do
        subject { described_class.parse("-1y2m") }

        it "returns a Timestamp representing a time ago that duration" do
          expect(subject).to be_a described_class
          expect(subject.to_iso8601).to eq "P-1Y-2M"
          expect(subject.to_duration).to eq ActiveSupport::Duration.build(-1.year - 2.months)
          expect(subject.relative?).to be true
        end
      end

      describe "2022-01-01" do
        subject { described_class.parse("2022-01-01") }

        it "returns a Timestamp representing that absolute time" do
          expect(subject).to be_a described_class
          expect(subject.to_iso8601).to eq "2022-01-01T00:00:00Z"
          expect(subject.to_time).to eq Time.zone.parse("2022-01-01T00:00:00Z")
          expect(subject.relative?).to be false
        end
      end
    end

    describe "when providing something invalid" do
      subject { described_class.parse("foo") }

      it "raises an error" do
        expect { subject }.to raise_error ArgumentError
      end

      describe "when providing something invalid starting with P (for duration)" do
        subject { described_class.parse("Pfoo") }

        it "raises an error" do
          expect { subject }.to raise_error ArgumentError
          expect { subject }.to raise_error ActiveSupport::Duration::ISO8601Parser::ParsingError
        end
      end
    end

    describe 'when providing a Timestamp' do
      subject { described_class.parse(provided) }

      let(:provided) { described_class.new }

      it "returns the provided timestamp" do
        expect(subject).to eql provided
      end
    end
  end

  describe ".parse_multiple" do
    describe "when providing an empty string" do
      subject { described_class.parse_multiple("") }

      it "returns an empty array" do
        expect(subject).to eq []
      end
    end

    describe "when providing a single timestamp" do
      subject { described_class.parse_multiple("PT10S") }

      it "returns an array containing that timestamp" do
        expect(subject).to eq [described_class.new("PT10S")]
      end
    end

    describe "when providing multiple comma-separated timestamps" do
      subject { described_class.parse_multiple("PT10S,PT20S") }

      it "returns an array containing those timestamps" do
        expect(subject).to eq [described_class.new("PT10S"), described_class.new("PT20S")]
      end
    end

    describe "when providing multiple comma-separated timestamps with whitespace" do
      subject { described_class.parse_multiple("PT10S, PT20S") }

      it "returns an array containing those timestamps" do
        expect(subject).to eq [described_class.new("PT10S"), described_class.new("PT20S")]
      end
    end

    describe "when providing multiple comma-separated timestamps with whitespace and empty strings" do
      subject { described_class.parse_multiple("PT10S, , PT20S") }

      it "returns an array containing those timestamps" do
        expect(subject).to eq [described_class.new("PT10S"), described_class.new("PT20S")]
      end
    end

    describe "when providing something invalid" do
      subject { described_class.parse_multiple("foo") }

      it "raises an error" do
        expect { subject }.to raise_error ArgumentError
      end
    end
  end

  describe "#relative?" do
    subject { timestamp.relative? }

    describe "for a timestamp representing an absolute time" do
      let(:timestamp) { described_class.new(1.year.ago) }

      it "returns false" do
        expect(subject).to be false
      end
    end

    describe "for a timestamp representing a point in time relative to now" do
      let(:timestamp) { described_class.new("PT10S") }

      it "returns true" do
        expect(subject).to be true
      end
    end
  end

  describe "#iso8601" do
    subject { timestamp.iso8601 }

    describe "for a timestamp representing an absolute time" do
      let(:timestamp) { described_class.new(1.year.ago) }

      it "returns an ISO8601 String representing that time" do
        expect(subject).to eq timestamp.to_time.iso8601
      end
    end

    describe "for a timestamp representing a point in time relative to now" do
      let(:timestamp) { described_class.new("PT10S") }

      it "returns an ISO8601 String representing the duration between that time and now" do
        expect(subject).to eq "PT10S"
        expect(subject).to eq ActiveSupport::Duration.build(10).iso8601
      end
    end
  end

  describe "#to_s" do
    subject { timestamp.to_s }

    describe "for a timestamp representing an absolute time" do
      let(:timestamp) { described_class.new(1.year.ago) }

      it "returns an ISO8601 String representing that time" do
        expect(subject).to eq timestamp.to_time.iso8601
      end
    end

    describe "for a timestamp representing a point in time relative to now" do
      let(:timestamp) { described_class.new("PT10S") }

      it "returns an ISO8601 String representing the duration between that time and now" do
        expect(subject).to eq "PT10S"
        expect(subject).to eq ActiveSupport::Duration.build(10).iso8601
      end
    end
  end

  describe "#to_json" do
    subject { timestamp.to_json }

    describe "for a timestamp representing an absolute time" do
      let(:timestamp) { described_class.new(1.year.ago) }

      it "returns an ISO8601 String representing that time" do
        expect(subject).to eq timestamp.to_time.iso8601
      end
    end

    describe "for a timestamp representing a point in time relative to now" do
      let(:timestamp) { described_class.new("PT10S") }

      it "returns an ISO8601 String representing the duration between that time and now" do
        expect(subject).to eq "PT10S"
        expect(subject).to eq ActiveSupport::Duration.build(10).iso8601
      end
    end
  end

  describe "#to_time" do
    subject { timestamp.to_time }

    describe "for a timestamp representing an absolute time" do
      let(:time) { 1.year.ago }
      let(:timestamp) { described_class.new(time) }

      it "returns a Time representing that time (up to full seconds)" do
        expect(subject).to be_a Time
        expect(subject).to eq Time.zone.at(time.to_i)
      end
    end

    describe "for a timestamp representing a point in time relative to now" do
      Timecop.freeze do
        let(:timestamp) { described_class.new("PT10S") }
        it "returns a Time converting the relative time to an absolute time (relative to now at evaluation time)" do
          expect(subject).to be_a Time
          expect(Time.zone.at(subject.to_i)).to eq Time.zone.at(10.seconds.ago.to_i)
        end
      end
    end

    describe "for a timestamp representing a point in time relative to now with negative duration" do
      Timecop.freeze do
        let(:timestamp) { described_class.new("PT-10S") }
        it "returns a Time converting the relative time to an absolute time (relative to now at evaluation time)" do
          expect(subject).to be_a Time
          expect(Time.zone.at(subject.to_i)).to eq Time.zone.at(10.seconds.ago.to_i)
        end
      end
    end
  end

  describe "#to_duration" do
    subject { timestamp.to_duration }

    describe "for a timestamp representing an absolute time" do
      let(:time) { 1.year.ago }
      let(:timestamp) { described_class.new(time) }

      it "raises an error because the absolute time does not change when the current time progresses " \
         "and therefore cannot be represented as constant duration" do
        expect { subject }.to raise_error described_class::Exception
      end
    end

    describe "for a timestamp representing a point in time relative to now" do
      Timecop.freeze do
        let(:timestamp) { described_class.new("PT10S") }
        it "returns an ActiveSupport::Duration corresponding to the duration between the timestamp and now" do
          expect(subject).to be_a ActiveSupport::Duration
          expect(subject).to eq ActiveSupport::Duration.build(10)
        end
      end
    end
  end

  describe "#hash" do
    # rubocop:disable RSpec/IdenticalEqualityAssertion
    context 'for two instances of relative time representing the same point in time' do
      it 'is eql' do
        expect(described_class.new("PT0S").hash)
          .to eql described_class.new("PT0S").hash
      end
    end

    context 'for two instances of relative time representing different points in time' do
      it 'is different' do
        expect(described_class.new("PT0S").hash)
          .not_to eql described_class.new("PT10S").hash
      end
    end

    context 'for two instances of absolute time representing the same point in time' do
      let(:time) { Time.zone.now }

      it 'is equal' do
        expect(described_class.new(time).hash)
          .to eql described_class.new(time).hash
      end
    end

    context 'for two instances of absolute time representing different points in time' do
      it 'is different' do
        expect(described_class.new(10.seconds.ago).hash)
          .not_to eql described_class.new(5.seconds.ago).hash
      end
    end
    # rubocop:enable RSpec/IdenticalEqualityAssertion
  end

  describe "passing a described_class to a where clause" do
    subject { Query.where("updated_at < ?", timestamp) }

    let(:timestamp) { described_class.new("PT10S") }

    it "raises an error because the query interface requires a Time type" do
      expect { subject }.to raise_error TypeError
    end

    describe "when converting the timestamp to_time" do
      subject { Query.where("updated_at < ?", timestamp.to_time) }

      it "raises no error" do
        expect { subject }.not_to raise_error
      end
    end
  end
end
