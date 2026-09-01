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

  describe "#typed_value" do
    subject { instance.typed_value }

    context "when value is a canonical datetime string" do
      let(:value) { "2015-01-03 14:30:00" }

      it { is_expected.to eql(DateTime.new(2015, 1, 3, 14, 30, 0)) }
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

  describe "#formatted_value" do
    subject { instance.formatted_value }

    context "when value is a datetime string",
            with_settings: { date_format: "%Y-%m-%d", time_format: "%H:%M" } do
      let(:value) { "2015-01-03 14:30:00" }

      it "is the datetime in the user's time zone" do
        expect(subject).to eql "2015-01-03 14:30"
      end
    end

    context "when value is nil" do
      let(:value) { nil }

      it "is a blank string" do
        expect(subject).to eql ""
      end
    end
  end

  describe "#parse_value" do
    subject { instance.parse_value(value) }

    context "when value is an ISO 8601 UTC string" do
      let(:value) { "2015-01-03T14:30:00Z" }

      it "is normalized to the canonical format" do
        expect(subject).to eql "2015-01-03 14:30:00"
      end
    end

    context "when value is an ISO 8601 string with an offset" do
      let(:value) { "2015-01-03T14:30:00+03:00" }

      it "is converted to UTC" do
        expect(subject).to eql "2015-01-03 11:30:00"
      end
    end

    context "when value has no offset" do
      let(:value) { "2015-01-03T14:30" }
      let(:user) { build_stubbed(:user) }

      before do
        user.pref.time_zone = "Europe/Berlin"
        allow(User).to receive(:current).and_return(user)
      end

      it "is interpreted in the current user's time zone" do
        expect(subject).to eql "2015-01-03 13:30:00"
      end
    end

    context "when value is already canonical" do
      let(:value) { "2015-01-03 14:30:00" }

      it "is kept as is (treated as UTC)" do
        expect(subject).to eql value
      end
    end

    context "when value is a Time" do
      let(:value) { Time.zone.parse("2015-01-03 14:30:00 +0100") }

      it "is converted to UTC in the canonical format" do
        expect(subject).to eql "2015-01-03 13:30:00"
      end
    end

    context "when value is invalid" do
      let(:value) { "chicken" }

      it "is kept as is" do
        expect(subject).to eql value
      end
    end

    context "when value is nil" do
      let(:value) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe "#validate_type_of_value" do
    subject { instance.validate_type_of_value }

    context "when value is a canonical datetime string" do
      let(:value) { "2015-01-03 14:30:00" }

      it "accepts" do
        expect(subject).to be_nil
      end
    end

    context "when value is an invalid datetime in good format" do
      let(:value) { "2015-02-30 14:30:00" }

      it "rejects" do
        expect(subject).to be(:not_a_datetime)
      end
    end

    context "when value is a datetime string in bad format" do
      let(:value) { "03.01.2015 14:30" }

      it "rejects" do
        expect(subject).to be(:not_a_datetime)
      end
    end

    context "when value is not a datetime string at all" do
      let(:value) { "chicken" }

      it "rejects" do
        expect(subject).to be(:not_a_datetime)
      end
    end

    context "when value is a Time" do
      let(:value) { Time.zone.now }

      it "accepts" do
        expect(subject).to be_nil
      end
    end
  end
end
