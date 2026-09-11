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
require "spreadsheet"

RSpec.describe Exports::Formatters::XLS::DateFormat do
  def stub_locale_pattern(date: nil, time: nil)
    allow(I18n).to receive(:t).and_call_original
    allow(I18n).to receive(:t).with("date.formats.default").and_return(date) if date
    allow(I18n).to receive(:t).with("time.formats.time").and_return(time) if time
  end

  describe ".date" do
    it "follows the locale when the setting is unset" do
      expect(described_class.date).to eq("MM/DD/YYYY")
    end

    it "follows the locale when the setting is unset and the locale is not english" do
      I18n.with_locale(:ru) do
        expect(described_class.date).to eq("DD.MM.YYYY")
      end
    end

    it "translates every allowed setting into an excel format", :aggregate_failures do
      formats = {
        "%Y-%m-%d" => "YYYY-MM-DD",
        "%d/%m/%Y" => "DD/MM/YYYY",
        "%d.%m.%Y" => "DD.MM.YYYY",
        "%d-%m-%Y" => "DD-MM-YYYY",
        "%m/%d/%Y" => "MM/DD/YYYY",
        "%d %b %Y" => "DD MMM YYYY",
        "%d %B %Y" => "DD MMMM YYYY",
        "%b %d, %Y" => "MMM DD, YYYY",
        "%B %d, %Y" => "MMMM DD, YYYY"
      }

      expect(formats.keys).to match_array(Settings::Definition[:date_format].allowed)

      formats.each do |pattern, format|
        with_settings(date_format: pattern)

        expect(described_class.date).to eq(format)
      end
    end

    {
      "%d. %m. %Y" => "DD. MM. YYYY",
      "%-d %B %Y" => "D MMMM YYYY",
      "%e. %Bta %Y" => 'D. MMMM"ta" YYYY',
      "%Y年%m月%d日" => 'YYYY"年"MM"月"DD"日"'
    }.each do |pattern, format|
      it "translates the #{pattern} locale pattern into #{format}" do
        stub_locale_pattern(date: pattern)

        expect(described_class.date).to eq(format)
      end
    end

    ["%Y%j", "%d %b %Y %Z", "%Y-%m-%d (week %U)"].each do |pattern|
      it "falls back to an ISO format for #{pattern}, which excel cannot express" do
        stub_locale_pattern(date: pattern)

        expect(described_class.date).to eq(described_class::DEFAULT_DATE)
      end
    end
  end

  describe ".time" do
    it "follows the locale when the setting is unset" do
      expect(described_class.time).to eq("HH:MM AM/PM")
    end

    it "translates every allowed setting into an excel format", :aggregate_failures do
      formats = { "%H:%M" => "HH:MM", "%I:%M %p" => "HH:MM AM/PM" }

      expect(formats.keys).to match_array(Settings::Definition[:time_format].allowed)

      formats.each do |pattern, format|
        with_settings(time_format: pattern)

        expect(described_class.time).to eq(format)
      end
    end

    it "keeps the seconds a locale asks for" do
      stub_locale_pattern(time: "%H:%M:%S")

      expect(described_class.time).to eq("HH:MM:SS")
    end

    ["%H:%M %Z", "%U:%M %s", "%I:% M %p"].each do |pattern|
      it "falls back to a 24 hour format for #{pattern}, which excel cannot express" do
        stub_locale_pattern(time: pattern)

        expect(described_class.time).to eq(described_class::DEFAULT_TIME)
      end
    end

    it "falls back rather than render a 12 hour clock excel would show as 24 hours" do
      stub_locale_pattern(time: "%I:%M")

      expect(described_class.time).to eq(described_class::DEFAULT_TIME)
    end
  end

  describe ".datetime" do
    it "joins the date and the time format",
       with_settings: { date_format: "%d.%m.%Y", time_format: "%H:%M" } do
      expect(described_class.datetime).to eq("DD.MM.YYYY HH:MM")
    end
  end

  describe "the formats excel is handed" do
    def expect_date_and_datetime_formats
      expect(Spreadsheet::Format.new(number_format: described_class.date)).to be_date
      expect(Spreadsheet::Format.new(number_format: described_class.datetime)).to be_datetime
    end

    it "are never read as a number for any combination of settings" do
      allowed = Settings::Definition[:date_format].allowed.product(Settings::Definition[:time_format].allowed)

      allowed.each do |date_format, time_format|
        with_settings(date_format:, time_format:)

        expect_date_and_datetime_formats
      end
    end

    it "are never read as a number for any pattern the shipped locales use" do
      dates = ["%Y-%m-%d", "%d/%m/%Y", "%d.%m.%Y", "%d-%m-%Y", "%m/%d/%Y",
               "%d. %m. %Y", "%e. %Bta %Y", "%Y / %m / %d", "%Y/%m/%d", "%Y年%m月%d日"]
      times = ["%H:%M", "%H:%M:%S", "%I:%M %p", "%U:%M %s", "%I:% M %p"]

      dates.product(times).each do |date, time|
        stub_locale_pattern(date:, time:)

        expect_date_and_datetime_formats
      end
    end
  end
end
