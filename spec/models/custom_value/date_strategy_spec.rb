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

RSpec.describe CustomValue::DateStrategy do
  let(:instance) { described_class.new(custom_value) }
  let(:custom_value) do
    double("CustomValue",
           value:)
  end

  describe "#typed_value" do
    subject { instance.typed_value }

    context "value is some date string" do
      let(:value) { "2015-01-03" }

      it { is_expected.to eql(Date.iso8601(value)) }
    end

    context "value is blank" do
      let(:value) { "" }

      it { is_expected.to be_nil }
    end

    context "value is nil" do
      let(:value) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe "#formatted_value" do
    subject { instance.formatted_value }

    context "value is some date string" do
      let(:value) { "2015-01-03" }

      context "date format", with_settings: { date_format: "%Y-%m-%d" } do
        it "is the date" do
          expect(subject).to eql value
        end
      end
    end

    context "value is blank" do
      let(:value) { "" }

      it "is a blank string" do
        expect(subject).to be_nil
      end
    end

    context "value is nil" do
      let(:value) { nil }

      it "is a blank string" do
        expect(subject).to eql ""
      end
    end
  end

  describe "#validate_type_of_value" do
    subject { instance.validate_type_of_value }

    context "value is valid date string" do
      let(:value) { "2015-01-03" }

      it "accepts" do
        expect(subject).to be_nil
      end
    end

    context "value is invalid date string in good format" do
      let(:value) { "2015-02-30" }

      it "rejects" do
        expect(subject).to be(:not_a_date)
      end
    end

    context "value is date string in bad format" do
      let(:value) { "03.01.2015" }

      it "rejects" do
        expect(subject).to be(:not_a_date)
      end
    end

    context "value is not a date string at all" do
      let(:value) { "chicken" }

      it "rejects" do
        expect(subject).to be(:not_a_date)
      end
    end

    context "value is valid date" do
      let(:value) { Date.iso8601("2015-01-03") }

      it "accepts" do
        expect(subject).to be_nil
      end
    end
  end
end
