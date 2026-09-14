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

RSpec.describe CustomValue::CalculatedValueStrategy do
  let(:instance) { described_class.new(custom_value) }
  let(:custom_value) { instance_double(CustomValue, value:) }

  describe "#typed_value" do
    subject { instance.typed_value }

    context "when value is a float string" do
      let(:value) { "3.14" }

      it { is_expected.to be(3.14) }
    end

    context "when value is an int string" do
      let(:value) { "42" }

      it { is_expected.to be(42) }
    end

    context "when value is the DB true value" do
      let(:value) { OpenProject::Database::DB_VALUE_TRUE }

      it { is_expected.to be(true) }
    end

    context "when value is the DB false value" do
      let(:value) { OpenProject::Database::DB_VALUE_FALSE }

      it { is_expected.to be(false) }
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

    context "when value is a float string" do
      let(:value) { "32400.14" }

      it "is the float string with delimiters" do
        expect(subject).to eql "32,400.14"
      end

      it "is localized with delimiters" do
        I18n.with_locale(:de) do
          expect(subject).to eql "32.400,14"
        end
      end
    end

    context "when value is a float string with many zeroed decimals" do
      let(:value) { "3.0000000000000000000000000000009" }

      it "is formatted as a float with a minimum precision" do
        expect(subject).to eql "3.0"
      end
    end

    context "when value is a float string with some zeroed decimals" do
      let(:value) { "3.000" }

      it "is formatted as a float with a minimum precision" do
        expect(subject).to eql "3.0"
      end
    end

    context "when value is a float string with digits after the decimal point" do
      let(:value) { "42.87391" }

      it "is formatted as a float with a precision of 3 while rounding decimal places" do
        expect(subject).to eql "42.874"
      end
    end

    context "when value is an int string" do
      let(:value) { "42312" }

      it "is the int string with delimiters" do
        expect(subject).to eql "42,312"
      end

      it "is localized with delimiters" do
        I18n.with_locale(:de) do
          expect(subject).to eql "42.312"
        end
      end
    end

    context "when value is the DB true value" do
      let(:value) { OpenProject::Database::DB_VALUE_TRUE }

      it "is the localized Yes label" do
        expect(subject).to eql I18n.t(:general_text_Yes)
      end
    end

    context "when value is the DB false value" do
      let(:value) { OpenProject::Database::DB_VALUE_FALSE }

      it "is the localized No label" do
        expect(subject).to eql I18n.t(:general_text_No)
      end
    end

    context "when value is blank" do
      let(:value) { "" }

      it "is a blank string" do
        expect(subject).to eql value
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

    [true, "true", OpenProject::Database::DB_VALUE_TRUE].each do |value|
      context "with #{value.inspect}" do
        let(:value) { value }

        it "normalises to the DB true value" do
          expect(subject).to eql OpenProject::Database::DB_VALUE_TRUE
        end
      end
    end

    [false, "false", OpenProject::Database::DB_VALUE_FALSE].each do |value|
      context "with #{value.inspect}" do
        let(:value) { value }

        it "normalises to the DB false value" do
          expect(subject).to eql OpenProject::Database::DB_VALUE_FALSE
        end
      end
    end

    context "when input is a numeric string" do
      let(:value) { "42" }

      it "is passed through unchanged" do
        expect(subject).to eql "42"
      end
    end
  end

  describe "#validate_type_of_value" do
    subject { instance.validate_type_of_value }

    context "when value is a float string in decimal notation" do
      let(:value) { "3.14" }

      it "accepts" do
        expect(subject).to be_nil
      end
    end

    context "when value is a float string in exp. notation" do
      let(:value) { "5.0e-14" }

      it "accepts" do
        expect(subject).to be_nil
      end
    end

    context "when value is a positive int string" do
      let(:value) { "10" }

      it "accepts" do
        expect(subject).to be_nil
      end
    end

    context "when value is a negative int string" do
      let(:value) { "-10" }

      it "accepts" do
        expect(subject).to be_nil
      end
    end

    context "when value is not a float string" do
      let(:value) { "banana" }

      it "rejects" do
        expect(subject).to be(:not_a_number)
      end
    end

    context "when value is a float" do
      let(:value) { 3.14 }

      it "accepts" do
        expect(subject).to be_nil
      end
    end

    context "when value is an int" do
      let(:value) { 3 }

      it "accepts" do
        expect(subject).to be_nil
      end
    end

    context "when value is the boolean true" do
      let(:value) { true }

      it "accepts" do
        expect(subject).to be_nil
      end
    end

    context "when value is the boolean false" do
      let(:value) { false }

      it "accepts" do
        expect(subject).to be_nil
      end
    end

    context "when value is the DB true value" do
      let(:value) { OpenProject::Database::DB_VALUE_TRUE }

      it "accepts" do
        expect(subject).to be_nil
      end
    end

    context "when value is the DB false value" do
      let(:value) { OpenProject::Database::DB_VALUE_FALSE }

      it "accepts" do
        expect(subject).to be_nil
      end
    end
  end
end
