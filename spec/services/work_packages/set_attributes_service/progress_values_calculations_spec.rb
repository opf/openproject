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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"
require_relative "have_correctable_progress_value_matchers"

RSpec.describe WorkPackages::SetAttributesService::ProgressValuesCalculations do
  let(:dummy_class) { Class.new { extend WorkPackages::SetAttributesService::ProgressValuesCalculations } }

  describe "#calculate_work" do
    it "returns the correct work base on remaining work and % complete" do
      expect(dummy_class.calculate_work(remaining_work: 1, percent_complete: 90)).to eq(10)
      expect(dummy_class.calculate_work(remaining_work: 5, percent_complete: 50)).to eq(10)
      expect(dummy_class.calculate_work(remaining_work: 10, percent_complete: 0)).to eq(10)
    end

    it "rounds the result to 2 decimal places" do
      # 1h remaining, 99% complete => 99.99999999999991h work => 100h
      expect(dummy_class.calculate_work(remaining_work: 1, percent_complete: 99)).to eq(100)
    end

    it "returns same value as remaining work if % complete is 0%" do
      expect(dummy_class.calculate_work(remaining_work: 42, percent_complete: 0)).to eq(42)
    end

    context "when % complete is 100% (no consistency check)" do
      it "returns Infinity if remaining work is positive" do
        expect(dummy_class.calculate_work(remaining_work: 42, percent_complete: 100)).to eq(Float::INFINITY)
      end

      it "returns NaN if remaining work is 0" do
        expect(dummy_class.calculate_work(remaining_work: 0, percent_complete: 100)).to be_nan
      end

      it "returns -Infinity if remaining work is negative" do
        expect(dummy_class.calculate_work(remaining_work: -42, percent_complete: 100)).to eq(-Float::INFINITY)
      end
    end
  end

  describe "#calculate_remaining_work" do
    it "returns the correct remaining work base on work and % complete" do
      expect(dummy_class.calculate_remaining_work(work: 10, percent_complete: 100)).to eq(0)
      expect(dummy_class.calculate_remaining_work(work: 10, percent_complete: 95)).to eq(0.5)
      expect(dummy_class.calculate_remaining_work(work: 10, percent_complete: 50)).to eq(5)
      expect(dummy_class.calculate_remaining_work(work: 10, percent_complete: 0)).to eq(10)
    end

    it "rounds the result to 2 decimal places" do
      # 1.23h, 33% => 0.8240999999999999h => 0.82h
      # it should be 0.8241h but we have floating point precision kicking in, and we have
      # to keep backward compatibility to avoid displaying false validation errors
      expect(dummy_class.calculate_remaining_work(work: 1.23, percent_complete: 33)).to eq(0.82)
      # 1.23h, 67% => 0.4059h => 0.41h
      expect(dummy_class.calculate_remaining_work(work: 1.23, percent_complete: 67)).to eq(0.41)
    end

    it "returns 0h if % complete is 100%" do
      expect(dummy_class.calculate_remaining_work(work: 10, percent_complete: 100)).to eq(0)
    end

    it "returns same value as work if % complete is 0%" do
      expect(dummy_class.calculate_remaining_work(work: 10, percent_complete: 0)).to eq(10)
    end

    it "rounds work value to 2 decimal places before computing remaining work" do
      expect(dummy_class.calculate_remaining_work(work: 0.25499, percent_complete: 75)).to eq(0.06)
      expect(dummy_class.calculate_remaining_work(work: 0.25499, percent_complete: 76)).to eq(0.06)
      expect(dummy_class.calculate_remaining_work(work: 0.25499, percent_complete: 77)).to eq(0.06)
      expect(dummy_class.calculate_remaining_work(work: 0.245, percent_complete: 75)).to eq(0.06)
      expect(dummy_class.calculate_remaining_work(work: 0.245, percent_complete: 76)).to eq(0.06)
      expect(dummy_class.calculate_remaining_work(work: 0.245, percent_complete: 77)).to eq(0.06)
    end
  end

  describe "#calculate_percent_complete" do
    it "returns the correct percent complete" do
      expect(dummy_class.calculate_percent_complete(work: 10, remaining_work: 0)).to eq(100)
      expect(dummy_class.calculate_percent_complete(work: 10, remaining_work: 0.5)).to eq(95)
      expect(dummy_class.calculate_percent_complete(work: 10, remaining_work: 5)).to eq(50)
      expect(dummy_class.calculate_percent_complete(work: 10, remaining_work: 10)).to eq(0)
    end

    it "returns 0% if the work and remaining work are the same" do
      expect(dummy_class.calculate_percent_complete(work: 1000, remaining_work: 1000)).to eq(0)
      expect(dummy_class.calculate_percent_complete(work: 1, remaining_work: 1)).to eq(0)
    end

    it "returns 1% if the calculated percent complete is above 0% and less than 1% (0.1% is not 0%)" do
      999.downto(990) do |remaining_work|
        expect(dummy_class.calculate_percent_complete(work: 1000, remaining_work:)).to eq(1)
      end
    end

    it "rounds the calculated percent complete to nearest integer (12.5 => 13%, 13.4 => 13%)" do
      # 12.4%
      expect(dummy_class.calculate_percent_complete(work: 1000, remaining_work: 876)).to eq(12)
      # 12.5% to 13.4%
      875.downto(866) do |remaining_work|
        expect(dummy_class.calculate_percent_complete(work: 1000, remaining_work:)).to eq(13)
      end
      # 13.5%
      expect(dummy_class.calculate_percent_complete(work: 1000, remaining_work: 865)).to eq(14)
    end

    it "returns 99% if the calculated percent complete is more than 99% and less than 100% (99.9% is not 100%)" do
      1.upto(10) do |remaining_work|
        expect(dummy_class.calculate_percent_complete(work: 1000, remaining_work:)).to eq(99)
      end
    end

    it "returns 100% if remaining work is 0" do
      expect(dummy_class.calculate_percent_complete(work: 1000, remaining_work: 0)).to eq(100)
      expect(dummy_class.calculate_percent_complete(work: 1, remaining_work: 0)).to eq(100)
    end

    it "rounds input values to 2 decimal places before computing percent complete" do
      expect(dummy_class.calculate_percent_complete(work: 0.25, remaining_work: 0.06)).to eq(76)

      # would be 75% if not rounded
      expect(dummy_class.calculate_percent_complete(work: 0.25, remaining_work: 0.0625)).to eq(76)
      # would be 77% if not rounded
      expect(dummy_class.calculate_percent_complete(work: 0.25, remaining_work: 0.0575)).to eq(76)
      # would be 78% if not rounded
      expect(dummy_class.calculate_percent_complete(work: 0.25, remaining_work: 0.055)).to eq(76)
    end

    context "when work is 0 (no consistency check)" do
      it "fails with FloatDomainError because of a division by zero" do
        expect { dummy_class.calculate_percent_complete(work: 0.0, remaining_work: 0.0) }.to raise_error(FloatDomainError)
      end
    end
  end

  describe "#correctable_remaining_work_value?" do
    it "returns true when work is set, remaining work is not 0h, and % complete is 100%" do
      expect(work: 10, remaining_work: 11, percent_complete: 100).to have_correctable_remaining_work_value
      expect(work: 10, remaining_work: 10, percent_complete: 100).to have_correctable_remaining_work_value
      expect(work: 10, remaining_work: 1, percent_complete: 100).to have_correctable_remaining_work_value
      expect(work: 10, remaining_work: -1, percent_complete: 100).to have_correctable_remaining_work_value
      expect(work: 10, remaining_work: nil, percent_complete: 100).to have_correctable_remaining_work_value

      # this one feels weird...
      expect(work: 0, remaining_work: 10, percent_complete: 100).to have_correctable_remaining_work_value
    end

    it "returns false when work is not set" do
      expect(work: nil, remaining_work: 10, percent_complete: 100).not_to have_correctable_remaining_work_value
    end

    it "returns false when remaining work is 0h" do
      expect(work: 10, remaining_work: 0, percent_complete: 100).not_to have_correctable_remaining_work_value
    end

    it "returns false when % complete is not 100%" do
      expect(work: 10, remaining_work: 10, percent_complete: 42).not_to have_correctable_remaining_work_value
      expect(work: 10, remaining_work: 10, percent_complete: 0).not_to have_correctable_remaining_work_value
      expect(work: 10, remaining_work: 10, percent_complete: nil).not_to have_correctable_remaining_work_value
    end
  end

  describe "#correctable_percent_complete_value?" do
    it "returns true when % complete is calculable and does not match the value derived from work and remaining work" do
      expect(work: 10, remaining_work: 10, percent_complete: 20).to have_correctable_percent_complete_value
      expect(work: 10, remaining_work: 0, percent_complete: 42).to have_correctable_percent_complete_value
    end

    it "returns false when % complete is calculable and matches the value derived from work and remaining work" do
      expect(work: 10, remaining_work: 5, percent_complete: 100).not_to have_correctable_percent_complete_value
      expect(work: 10, remaining_work: 0.5, percent_complete: 95).not_to have_correctable_percent_complete_value
      expect(work: 10, remaining_work: 5, percent_complete: 50).not_to have_correctable_percent_complete_value
      expect(work: 10, remaining_work: 10, percent_complete: 0).not_to have_correctable_percent_complete_value
    end

    it "returns false when % complete can not be calculated" do
      # any value  nil => % complete cannot be calculated
      expect(work: nil, remaining_work: 0, percent_complete: 100).not_to have_correctable_percent_complete_value
      expect(work: 10, remaining_work: nil, percent_complete: 100).not_to have_correctable_percent_complete_value
      expect(work: 10, remaining_work: 0, percent_complete: nil).not_to have_correctable_percent_complete_value

      # negative value => % complete cannot be calculated
      expect(work: -10, remaining_work: 0, percent_complete: 100).not_to have_correctable_percent_complete_value
      expect(work: 10, remaining_work: -3, percent_complete: 100).not_to have_correctable_percent_complete_value

      # work = 0h => % complete cannot be calculated (division by zero)
      expect(work: 0, remaining_work: 0, percent_complete: 100).not_to have_correctable_percent_complete_value
      expect(work: 0, remaining_work: 0, percent_complete: 0).not_to have_correctable_percent_complete_value

      # work < remaining work => % complete cannot be calculated
      expect(work: 10, remaining_work: 11, percent_complete: 100).not_to have_correctable_percent_complete_value
    end

    it "tolerates a range of % complete values when work and remaining work precision " \
       "is too small to get an accurate percent complete value" do
      # nominal case: 0.25h - 0.06h = 0.19h => 76% of 0.25h
      #
      # Remaining work is rounded to 0.06h for all values between 0.0550h and
      # 0.0649h. If user enters values from 75% to 77% while work is 0.25h, then
      # derived remaining work is always 0.06h, so all those % complete values
      # must be considered ok and are not to be corrected.
      75.upto(77) do |percent_complete|
        expect(work: 0.25, remaining_work: 0.06, percent_complete:).not_to have_correctable_percent_complete_value
      end

      # Due to floating point precision, when 78% is used, remaining work is derived to 0.54999999
      # which is rounded to 0.05h, so 78% would not be considered a consistent progress value.
      expect(work: 0.25, remaining_work: 0.06, percent_complete: 78).to have_correctable_percent_complete_value
      # but 78% is consistent with the remaining work of 0.05h
      expect(work: 0.25, remaining_work: 0.05, percent_complete: 78).not_to have_correctable_percent_complete_value
    end

    it "tolerates a range of remaining work values when work is too large and " \
       "remaining work is high which gives 1% completion" do
      # nominal case: 1000h - 990h = 10h => 1% of 1000h
      #
      # Percent complete is rounded to 1% for all values between 0.00001% and
      # 1.49999%. If user enters remaining work values from 986h and 999.99h, then
      # derived % complete will always be 1%, so all those combinations must be
      # considered consistent progress values.
      986.upto(999) do |remaining_work|
        expect(work: 1000, remaining_work:, percent_complete: 1).not_to have_correctable_percent_complete_value
      end

      # tests for remaining work = 999.99h => 1%
      expect(work: 1000, remaining_work: 999.99, percent_complete: 1).not_to have_correctable_percent_complete_value
      # tests for remaining work = 1000h => 0%
      expect(work: 1000, remaining_work: 1000.0, percent_complete: 0).not_to have_correctable_percent_complete_value
      expect(work: 1000, remaining_work: 1000.0, percent_complete: 1).to have_correctable_percent_complete_value
      # tests for remaining work = 984.99h => 2%
      expect(work: 1000, remaining_work: 984.99, percent_complete: 2).not_to have_correctable_percent_complete_value
      expect(work: 1000, remaining_work: 984.99, percent_complete: 1).to have_correctable_percent_complete_value
    end

    it "tolerates a range of remaining work values when work is too large and " \
       "remaining work is low which gives 99% completion" do
      # nominal case: 1000h - 10h = 990h => 99% of 1000h
      #
      # Percent complete is rounded to 99% for all values between 98.5% and
      # 99.99999%. If user enters remaining work values from 0.1h and 15h, then
      # derived % complete will always be 99%, so all those combinations must be
      # considered consistent progress values.
      1.upto(15) do |remaining_work|
        expect(work: 1000, remaining_work:, percent_complete: 99).not_to have_correctable_percent_complete_value
      end

      # tests for remaining work = 0.01h => 99%
      expect(work: 1000, remaining_work: 0.01, percent_complete: 99).not_to have_correctable_percent_complete_value
      # tests for remaining work = 0h => 100%
      expect(work: 1000, remaining_work: 0.0, percent_complete: 100).not_to have_correctable_percent_complete_value
      expect(work: 1000, remaining_work: 0.0, percent_complete: 99).to have_correctable_percent_complete_value
      # tests for remaining work = 16h => 98%
      expect(work: 1000, remaining_work: 16, percent_complete: 98).not_to have_correctable_percent_complete_value
      expect(work: 1000, remaining_work: 16, percent_complete: 99).to have_correctable_percent_complete_value
    end
  end
end
