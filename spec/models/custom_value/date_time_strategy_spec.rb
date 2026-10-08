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
  let(:value) { nil }

  current_user { build_stubbed(:user, preferences: { time_zone: "Europe/Berlin" }) }

  describe "#parse_value" do
    subject { instance.parse_value(input) }

    context "with a UTC datetime" do
      let(:input) { "2026-10-01T12:30:00Z" }

      it { is_expected.to eq("2026-10-01T12:30:00Z") }
    end

    context "with an offset" do
      let(:input) { "2026-10-01T14:30:00+02:00" }

      it { is_expected.to eq("2026-10-01T12:30:00Z") }
    end

    context "without an offset" do
      let(:input) { "2026-10-01T14:30" }

      it "reads it as UTC regardless of the user's time zone" do
        expect(subject).to eq("2026-10-01T14:30:00Z")
      end
    end

    context "with fractional seconds" do
      let(:input) { "2026-10-01T12:30:15.987Z" }

      it "drops them to keep the stored layout fixed-width" do
        expect(subject).to eq("2026-10-01T12:30:15Z")
      end
    end

    context "with a date only" do
      let(:input) { "2026-10-01" }

      it "is midnight UTC" do
        expect(subject).to eq("2026-10-01T00:00:00Z")
      end
    end

    context "with a non ISO 8601 format" do
      let(:input) { "01.10.2026 12:30" }

      it { is_expected.to eq(input) }
    end

    context "with nil" do
      let(:input) { nil }

      it { is_expected.to be_nil }
    end

    context "with an empty string" do
      let(:input) { "" }

      it { is_expected.to eq("") }
    end
  end

  describe "#typed_value" do
    subject { instance.typed_value }

    context "with a stored value" do
      let(:value) { "2026-10-01T12:30:00Z" }

      it { is_expected.to eq(Time.utc(2026, 10, 1, 12, 30)) }
    end

    context "with an invalid value" do
      let(:value) { "chicken" }

      it { is_expected.to be_nil }
    end

    context "with an empty string" do
      let(:value) { "" }

      it { is_expected.to be_nil }
    end

    context "with nil" do
      it { is_expected.to be_nil }
    end
  end

  describe "#formatted_value" do
    subject { instance.formatted_value }

    context "with a stored value", with_settings: { date_format: "%Y-%m-%d", time_format: "%H:%M" } do
      let(:value) { "2026-10-01T12:30:00Z" }

      it "is the date and time in the user's time zone" do
        expect(subject).to eq("2026-10-01 14:30")
      end
    end

    context "with nil" do
      it { is_expected.to eq("") }
    end
  end

  describe "#validate_type_of_value" do
    subject { instance.validate_type_of_value }

    context "with a stored value" do
      let(:value) { "2026-10-01T12:30:00Z" }

      it { is_expected.to be_nil }
    end

    context "with a date only" do
      let(:value) { "2026-10-01" }

      it { is_expected.to be_nil }
    end

    context "with an out of range time" do
      let(:value) { "2026-10-01T25:00:00Z" }

      it { is_expected.to be(:not_a_datetime) }
    end

    context "with a non ISO 8601 format" do
      let(:value) { "01.10.2026 12:30" }

      it { is_expected.to be(:not_a_datetime) }
    end
  end
end
