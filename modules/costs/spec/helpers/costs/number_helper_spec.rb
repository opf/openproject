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

require_relative "../../spec_helper"

RSpec.describe Costs::NumberHelper do
  describe "#parse_number_string" do
    context "with a german local" do
      it "parses a string with delimiter and separator correctly" do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("123.456,78"))
            .to eql "123456.78"
        end
      end

      it "parses a string with space delimiter and separator correctly" do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("123 456,78"))
            .to eql "123456.78"
        end
      end

      it "parses a string without delimiter and separator correctly" do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("12345678"))
            .to eql "12345678"
        end
      end

      it "parses a string without delimiter and with separator correctly" do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("123456,78"))
            .to eql "123456.78"
        end
      end

      it "parses a string with delimiter and without separator correctly" do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("12.345.678"))
            .to eql "12345678"
        end
      end

      it "parses a string with space delimiter and without separator correctly" do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("12 345 678"))
            .to eql "12345678"
        end
      end

      it "returns alphabetical values instead of a delimiter unchanged" do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("123456a78"))
            .to eql "123456a78"
        end
      end
    end

    context "with an english local" do
      it "parses a string with delimiter and separator correctly" do
        I18n.with_locale(:en) do
          expect(helper.parse_number_string("123,456.78"))
            .to eql "123456.78"
        end
      end

      it "parses a string with space delimiter and separator correctly" do
        I18n.with_locale(:en) do
          expect(helper.parse_number_string("123 456.78"))
            .to eql "123456.78"
        end
      end

      it "parses a string without delimiter and separator correctly" do
        I18n.with_locale(:en) do
          expect(helper.parse_number_string("12345678"))
            .to eql "12345678"
        end
      end

      it "parses a string without delimiter and with separator correctly" do
        I18n.with_locale(:en) do
          expect(helper.parse_number_string("123456.78"))
            .to eql "123456.78"
        end
      end

      it "parses a string with delimiter and without separator correctly" do
        I18n.with_locale(:en) do
          expect(helper.parse_number_string("12,345,678"))
            .to eql "12345678"
        end
      end

      it "parses a string with space delimiter and without separator correctly" do
        I18n.with_locale(:en) do
          expect(helper.parse_number_string("12 345 678"))
            .to eql "12345678"
        end
      end

      it "returns alphabetical values instead of a delimiter unchanged" do
        I18n.with_locale(:en) do
          expect(helper.parse_number_string("123456a78"))
            .to eql "123456a78"
        end
      end

      it "parses a string with only commas as separators when no dot is present" do
        I18n.with_locale(:en) do
          expect(helper.parse_number_string("123,456"))
            .to eql "123.456"
        end
      end
    end

    context "for nil" do
      it "is nil" do
        expect(helper.parse_number_string(nil))
          .to be_nil
      end
    end

    context "with a russian locale (Regression #37859)" do
      it "parses a string with delimiter and separator correctly" do
        I18n.with_locale(:ru) do
          expect(helper.parse_number_string("123.456,78"))
            .to eql "123456.78"
        end
      end

      it "parses a string with space delimiter and separator correctly" do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("123 456,78"))
            .to eql "123456.78"
        end
      end

      it "parses a string without delimiter and separator correctly" do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("12345678"))
            .to eql "12345678"
        end
      end

      it "parses a string without delimiter and with separator correctly" do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("123456,78"))
            .to eql "123456.78"
        end
      end

      it "parses a string with delimiter and without separator correctly" do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("12.345.678"))
            .to eql "12345678"
        end
      end

      it "parses a string with space delimiter and without separator correctly" do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("12 345 678"))
            .to eql "12345678"
        end
      end

      it "returns alphabetical values instead of a delimiter unchanged" do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("123456a78"))
            .to eql "123456a78"
        end
      end
    end
  end

  describe "#parse_hours_string_to_number", with_settings: { hours_per_day: 8, days_per_month: 20 } do
    it "parses plain decimal numbers" do
      expect(helper.parse_hours_string_to_number("10")).to eq(10)
      expect(helper.parse_hours_string_to_number("2.5")).to eq(2.5)
    end

    it "parses durations expressed in hours" do
      expect(helper.parse_hours_string_to_number("8h")).to eq(8)
      expect(helper.parse_hours_string_to_number("5 hrs 30 mins")).to eq(5.5)
    end

    it "resolves days through the hours per day setting" do
      expect(helper.parse_hours_string_to_number("1d")).to eq(8)
      expect(helper.parse_hours_string_to_number("2d 10h")).to eq(26)
    end

    it "resolves weeks and months through the duration settings" do
      expect(helper.parse_hours_string_to_number("1w")).to eq(40)
      expect(helper.parse_hours_string_to_number("1mo")).to eq(160)
    end

    context "with a german locale" do
      it "parses the locale delimiter and separator" do
        I18n.with_locale(:de) do
          expect(helper.parse_hours_string_to_number("1.234,5")).to eq(1234.5)
        end
      end

      it "still parses durations" do
        I18n.with_locale(:de) do
          expect(helper.parse_hours_string_to_number("2d 10h")).to eq(26)
        end
      end
    end

    context "with a different hours per day setting", with_settings: { hours_per_day: 6 } do
      it "resolves days accordingly" do
        expect(helper.parse_hours_string_to_number("1d")).to eq(6)
      end
    end

    it "returns 0.0 for unparseable values" do
      expect(helper.parse_hours_string_to_number("garbage")).to eq(0.0)
      expect(helper.parse_hours_string_to_number("12mm")).to eq(0.0)
      expect(helper.parse_hours_string_to_number(nil)).to eq(0.0)
      expect(helper.parse_hours_string_to_number("")).to eq(0.0)
    end
  end
end
