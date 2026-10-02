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

RSpec.describe CustomValue::DateTimeStrategy do
  let(:instance) { described_class.new(custom_value) }
  let(:custom_value) { instance_double(CustomValue, value:) }
  let(:user) { build_stubbed(:user, preferences: { time_zone: "Europe/Berlin" }) }

  current_user { user }

  describe "#typed_value" do
    subject { instance.typed_value }

    context "when value is in the storage format" do
      let(:value) { "2026-10-01 12:30:00" }

      it "is read as UTC" do
        expect(subject).to eq(Time.utc(2026, 10, 1, 12, 30, 0))
      end
    end

    context "when value is not a datetime" do
      let(:value) { "hello, world!" }

      it { is_expected.to be_nil }
    end

    context "when value is blank" do
      let(:value) { "" }

      it { is_expected.to be_nil }
    end

    context "when value is nil" do
      let(:value) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe "#parse_value" do
    let(:value) { nil }

    it "normalizes an ISO 8601 string with offset to UTC" do
      expect(instance.parse_value("2026-10-01T14:30:00+02:00")).to eq("2026-10-01 12:30:00")
    end

    it "normalizes an ISO 8601 string in UTC" do
      expect(instance.parse_value("2026-10-01T12:30:00.000Z")).to eq("2026-10-01 12:30:00")
    end

    it "interprets a string without offset in the user's time zone" do
      expect(instance.parse_value("2026-10-01T14:30")).to eq("2026-10-01 12:30:00")
    end

    it "keeps a value already in the storage format as UTC" do
      expect(instance.parse_value("2026-10-01 12:30:00")).to eq("2026-10-01 12:30:00")
    end

    it "normalizes time objects to UTC and drops sub-second precision" do
      time = Time.new(2026, 10, 1, 14, 30, 15.5, "+02:00")

      expect(instance.parse_value(time)).to eq("2026-10-01 12:30:15")
    end

    it "normalizes DateTime objects to UTC" do
      expect(instance.parse_value(DateTime.iso8601("2026-10-01T14:30:00+02:00"))).to eq("2026-10-01 12:30:00")
    end

    it "keeps a date without a time of day so that validation can reject it" do
      expect(instance.parse_value("2026-10-01")).to eq("2026-10-01")
    end

    it "reads the string form of a UTC Time (as assigned through the customizable setter)" do
      expect(instance.parse_value(Time.utc(2026, 10, 1, 12, 30).to_s)).to eq("2026-10-01 12:30:00")
    end

    it "reads the string form of a TimeWithZone" do
      time = Time.utc(2026, 10, 1, 12, 30).in_time_zone("Asia/Tokyo")

      expect(instance.parse_value(time.to_s)).to eq("2026-10-01 12:30:00")
    end

    it "honours an offset without a colon (as sent by Jira)" do
      expect(instance.parse_value("2026-10-01T14:30:00.000+0200")).to eq("2026-10-01 12:30:00")
    end

    it "keeps unparsable input so that validation can reject it" do
      expect(instance.parse_value("chicken")).to eq("chicken")
    end

    it "keeps blank input" do
      expect(instance.parse_value("")).to eq("")
    end
  end

  describe "#formatted_value", with_settings: { date_format: "%Y-%m-%d", time_format: "%H:%M" } do
    subject { instance.formatted_value }

    context "when value is set" do
      let(:value) { "2026-10-01 12:30:00" }

      it "is the time in the user's time zone" do
        expect(subject).to eq("2026-10-01 14:30")
      end
    end

    context "when value is blank" do
      let(:value) { "" }

      it { is_expected.to eq("") }
    end

    context "when value is nil" do
      let(:value) { nil }

      it { is_expected.to eq("") }
    end
  end

  describe "#validate_type_of_value" do
    subject { instance.validate_type_of_value }

    context "when value is in the storage format" do
      let(:value) { "2026-10-01 12:30:00" }

      it { is_expected.to be_nil }
    end

    context "when value is an ISO 8601 string" do
      let(:value) { "2026-10-01T12:30:00Z" }

      it { is_expected.to be_nil }
    end

    context "when value is a date without a time of day" do
      let(:value) { "2026-10-01" }

      it { is_expected.to be(:not_a_datetime) }
    end

    context "when value is an impossible datetime" do
      let(:value) { "2026-02-30 12:30:00" }

      it { is_expected.to be(:not_a_datetime) }
    end

    context "when value is not a datetime at all" do
      let(:value) { "chicken" }

      it { is_expected.to be(:not_a_datetime) }
    end
  end
end
