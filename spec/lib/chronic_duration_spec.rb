# Copied from https://gitlab.com/gitlab-org/ruby/gems/gitlab-chronic-duration
# version 0.12.0
#
# Copyright (c) Henry Poydar
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# NOTE:
# Changes to this file should be kept in sync with
# frontend/src/app/shared/helpers/chronic_duration.js.

require "rspec_helper"
require "chronic_duration"

INACCURATE_FORMATS = %i[days_and_hours hours_only].freeze

RSpec.describe ChronicDuration do
  describe ".parse" do
    exemplars = {
      "1:20" => 60 + 20,
      "1:20.51" => 60 + 20.51,
      "4:01:01" => (4 * 3600) + 60 + 1,
      "3 mins 4 sec" => (3 * 60) + 4,
      "3 Mins 4 Sec" => (3 * 60) + 4,
      "2 hrs 20 min" => (2 * 3600) + (20 * 60),
      "2h20min" => (2 * 3600) + (20 * 60),
      "6 mos 1 day" => (6 * 30 * 24 * 3600) + (24 * 3600),
      "1 year 6 mos 1 day" => (1 * 31557600) + (6 * 30 * 24 * 3600) + (24 * 3600),
      "2.5 hrs" => 2.5 * 3600,
      "47 yrs 6 mos and 4.5d" => (47 * 31557600) + (6 * 30 * 24 * 3600) + (4.5 * 24 * 3600),
      "3 weeks and, 2 days" => (3600 * 24 * 7 * 3) + (3600 * 24 * 2),
      "3 weeks, plus 2 days" => (3600 * 24 * 7 * 3) + (3600 * 24 * 2),
      "3 weeks with 2 days" => (3600 * 24 * 7 * 3) + (3600 * 24 * 2),
      "1 month" => 3600 * 24 * 30,
      "2 months" => 3600 * 24 * 30 * 2,
      "18 months" => 3600 * 24 * 30 * 18,
      "1 year 6 months" => (3600 * 24 * (365.25 + (6 * 30))).to_i,
      "day" => 3600 * 24,
      "minute 30s" => 90
    }

    context "when string can't be parsed" do
      let(:raise_exception) { false }

      before do
        allow(described_class).to receive(:raise_exceptions).and_return(raise_exception)
      end

      it "returns nil" do
        expect(described_class.parse("gobblygoo")).to be_nil
      end

      it "cannot parse zero" do
        expect(described_class.parse("0")).to be_nil
      end

      context "when @@raise_exceptions set to true" do
        let(:raise_exception) { true }

        it "raises with ChronicDuration::DurationParseError" do
          expect { described_class.parse("23 gobblygoos") }.to raise_error(ChronicDuration::DurationParseError)
        end

        context "when passing `raise_exceptions: false` as an option" do
          it "overrides @@raise_exception and returns nil" do
            expect(described_class.parse("gobblygoos", raise_exceptions: false)).to be_nil
          end
        end
      end

      context "when passing `raise_exceptions: true` as an option" do
        it "overrides @@raise_exception and raises with ChronicDuration::DurationParseError" do
          expect { described_class.parse("23 gobblygoos", raise_exceptions: true) }
            .to raise_error(ChronicDuration::DurationParseError)
        end
      end
    end

    it "returns zero if the string parses as zero and the keep_zero option is true" do
      expect(described_class.parse("0", keep_zero: true)).to eq(0)
    end

    it "returns a float if seconds are in decimals" do
      expect(described_class.parse("12 mins 3.141 seconds")).to be_a(Float)
    end

    it "returns an integer unless the seconds are in decimals" do
      expect(described_class.parse("12 mins 3 seconds")).to be_a(Integer)
    end

    it "is able to parse minutes by default" do
      expect(described_class.parse("5", default_unit: "minutes")).to eq(300)
    end

    exemplars.each do |k, v|
      it "parses a duration like #{k}" do
        expect(described_class.parse(k)).to eq(v)
      end
    end

    context "with :hours_per_day and :days_per_month params" do
      it "uses provided :hours_per_day" do
        expect(described_class.parse("1d", hours_per_day: 24)).to eq(24 * 60 * 60)
        expect(described_class.parse("1d", hours_per_day: 8)).to eq(8 * 60 * 60)
      end

      it "uses provided :days_per_month" do
        expect(described_class.parse("1mo", days_per_month: 30)).to eq(30 * 24 * 60 * 60)
        expect(described_class.parse("1mo", days_per_month: 20)).to eq(20 * 24 * 60 * 60)

        expect(described_class.parse("1w", days_per_month: 30)).to eq(7 * 24 * 60 * 60)
        expect(described_class.parse("1w", days_per_month: 20)).to eq(5 * 24 * 60 * 60)
      end

      it "uses provided both :hours_per_day and :days_per_month" do
        expect(described_class.parse("1mo", days_per_month: 30, hours_per_day: 24)).to eq(30 * 24 * 60 * 60)
        expect(described_class.parse("1mo", days_per_month: 20, hours_per_day: 8)).to eq(20 * 8 * 60 * 60)

        expect(described_class.parse("1w", days_per_month: 30, hours_per_day: 24)).to eq(7 * 24 * 60 * 60)
        expect(described_class.parse("1w", days_per_month: 20, hours_per_day: 8)).to eq(5 * 8 * 60 * 60)
      end
    end
  end

  describe ".output" do
    exemplars = {
      (60 + 20) =>
        {
          micro: "1m20s",
          short: "1m 20s",
          default: "1 min 20 secs",
          long: "1 minute 20 seconds",
          days_and_hours: "0.02h",
          hours_only: "0.02h",
          chrono: "1:20"
        },
      (60 + 20.51) =>
        {
          micro: "1m20.51s",
          short: "1m 20.51s",
          default: "1 min 20.51 secs",
          long: "1 minute 20.51 seconds",
          days_and_hours: "0.02h",
          hours_only: "0.02h",
          chrono: "1:20.51"
        },
      (60 + 20.51928) =>
        {
          micro: "1m20.51928s",
          short: "1m 20.51928s",
          default: "1 min 20.51928 secs",
          long: "1 minute 20.51928 seconds",
          days_and_hours: "0.02h",
          hours_only: "0.02h",
          chrono: "1:20.51928"
        },
      ((4 * 3600) + 60 + 1) =>
        {
          micro: "4h1m1s",
          short: "4h 1m 1s",
          default: "4 hrs 1 min 1 sec",
          long: "4 hours 1 minute 1 second",
          days_and_hours: "4.02h",
          hours_only: "4.02h",
          chrono: "4:01:01"
        },
      ((2 * 3600) + (20 * 60)) =>
        {
          micro: "2h20m",
          short: "2h 20m",
          default: "2 hrs 20 mins",
          long: "2 hours 20 minutes",
          days_and_hours: "2.33h",
          hours_only: "2.33h",
          chrono: "2:20:00"
        },
      ((8 * 24 * 3600) + (3 * 3600) + (30 * 60)) =>
        {
          micro: "8d3h30m",
          short: "8d 3h 30m",
          default: "8 days 3 hrs 30 mins",
          long: "8 days 3 hours 30 minutes",
          days_and_hours: "8d 3.5h",
          hours_only: "195.5h",
          chrono: "8:03:30:00"
        },
      ((6 * 30 * 24 * 3600) + (24 * 3600)) =>
        {
          micro: "6mo1d",
          short: "6mo 1d",
          default: "6 mos 1 day",
          long: "6 months 1 day",
          days_and_hours: "181d 0h",
          hours_only: "4344h",
          chrono: "6:01:00:00:00" # Yuck. FIXME
        },
      ((365.25 * 24 * 3600) + (24 * 3600)).to_i =>
        {
          micro: "1y1d",
          short: "1y 1d",
          default: "1 yr 1 day",
          long: "1 year 1 day",
          days_and_hours: "366d 0h",
          hours_only: "8790h",
          chrono: "1:00:01:00:00:00"
        },
      ((3 * 365.25 * 24 * 3600) + (24 * 3600)).to_i =>
        {
          micro: "3y1d",
          short: "3y 1d",
          default: "3 yrs 1 day",
          long: "3 years 1 day",
          days_and_hours: "1096d 0h",
          hours_only: "26322h",
          chrono: "3:00:01:00:00:00"
        },
      ((6 * 365.25 * 24 * 3600) + (3 * 3600)).to_i =>
        {
          micro: "6y3h",
          short: "6y 3h",
          default: "6 yrs 3 hrs",
          long: "6 years 3 hours",
          days_and_hours: "2191d 3h",
          hours_only: "52599h",
          chrono: "6:00:00:03:00:00"
        },
      (3600 * 24 * 30 * 18) =>
        {
          micro: "18mo",
          short: "18mo",
          default: "18 mos",
          long: "18 months",
          days_and_hours: "540d 0h",
          hours_only: "12960h",
          chrono: "18:00:00:00:00"
        }
    }

    exemplars.each do |k, v|
      v.each do |key, val|
        it "properly outputs a duration of #{k} seconds as #{val} using the #{key} format option" do
          expect(described_class.output(k, format: key)).to eq(val)
        end
      end
    end

    keep_zero_exemplars = {
      true =>
      {
        micro: "0s",
        short: "0s",
        default: "0 secs",
        long: "0 seconds",
        days_and_hours: "0h",
        chrono: "0"
      },
      false =>
      {
        micro: nil,
        short: nil,
        default: nil,
        long: nil,
        days_and_hours: "0h",
        chrono: "0"
      }
    }

    keep_zero_exemplars.each do |k, v|
      v.each do |key, val|
        it "outputs properly a duration of 0 seconds as #{val.nil? ? 'nil' : val} using the #{key} format option, " \
           "if the keep_zero option is #{k}" do
          expect(described_class.output(0, format: key, keep_zero: k)).to eq(val)
        end
      end
    end

    it "returns weeks when needed" do
      expect(described_class.output(45 * 24 * 60 * 60, weeks: true)).to match(/.*wk.*/)
    end

    it "returns hours and minutes only when :hours_only option specified" do
      expect(described_class.output((395 * 24 * 60 * 60) + (15 * 60), limit_to_hours: true)).to eq("9480 hrs 15 mins")
    end

    context "with :hours_per_day and :days_per_month params" do
      it "uses provided :hours_per_day" do
        expect(described_class.output(24 * 60 * 60, hours_per_day: 24)).to eq("1 day")
        expect(described_class.output(24 * 60 * 60, hours_per_day: 8)).to eq("3 days")
      end

      it "uses provided :days_per_month" do
        expect(described_class.output(7 * 24 * 60 * 60, weeks: true, days_per_month: 30)).to eq("1 wk")
        expect(described_class.output(7 * 24 * 60 * 60, weeks: true, days_per_month: 20)).to eq("1 wk 2 days")
      end

      it "uses provided both :hours_per_day and :days_per_month" do
        expect(described_class.output(7 * 24 * 60 * 60, weeks: true, days_per_month: 30, hours_per_day: 24)).to eq("1 wk")
        expect(described_class.output(5 * 8 * 60 * 60, weeks: true, days_per_month: 20, hours_per_day: 8)).to eq("1 wk")
      end

      it "uses provided params alongside with :weeks when converting to months" do
        expect(described_class.output(30 * 24 * 60 * 60, days_per_month: 30, hours_per_day: 24)).to eq("1 mo")
        expect(described_class.output(30 * 24 * 60 * 60, days_per_month: 30, hours_per_day: 24, weeks: true)).to eq("1 mo 2 days")

        expect(described_class.output(20 * 8 * 60 * 60, days_per_month: 20, hours_per_day: 8)).to eq("1 mo")
        expect(described_class.output(20 * 8 * 60 * 60, days_per_month: 20, hours_per_day: 8, weeks: true)).to eq("1 mo")
      end
    end

    it "returns the specified number of units if provided" do
      expect(described_class.output((4 * 3600) + 60 + 1, units: 2)).to eq("4 hrs 1 min")
      expect(described_class.output((6 * 30 * 24 * 3600) + (24 * 3600) + 3600 + 60 + 1,
                                    units: 3,
                                    format: :long)).to eq("6 months 1 day 1 hour")
    end

    context "when the format is not specified" do
      it "uses the default format" do
        expect(described_class.output((2 * 3600) + (20 * 60))).to eq("2 hrs 20 mins")
      end
    end

    exemplars.each do |seconds, format_spec|
      format_spec.each_key do |format|
        next if INACCURATE_FORMATS.include?(format)

        it "outputs a duration for #{seconds} that parses back to the same thing when using the #{format} format" do
          expect(described_class.parse(
                   described_class.output(seconds, format:, use_complete_matcher: true)
                 )).to eq(seconds)
        end
      end
    end

    it "uses user-specified joiner if provided" do
      expect(described_class.output((2 * 3600) + (20 * 60), joiner: ", ")).to eq("2 hrs, 20 mins")
    end
  end

  describe ".filter_by_type" do
    it "receives a chrono-formatted time like 3:14 and return a human time like 3 minutes 14 seconds" do
      expect(described_class.instance_eval("filter_by_type('3:14')", __FILE__, __LINE__)).to eq("3 minutes 14 seconds")
    end

    it "receives chrono-formatted time like 12:10:14 and return a human time like 12 hours 10 minutes 14 seconds" do
      expect(described_class.instance_eval("filter_by_type('12:10:14')", __FILE__,
                                           __LINE__ - 1)).to eq("12 hours 10 minutes 14 seconds")
    end

    it "returns the input if it's not a chrono-formatted time" do
      expect(described_class.instance_eval("filter_by_type('4 hours')", __FILE__, __LINE__)).to eq("4 hours")
    end
  end

  describe ".cleanup" do
    it "cleans up extraneous words" do
      expect(described_class.instance_eval("cleanup('4 days and 11 hours')", __FILE__, __LINE__)).to eq("4 days 11 hours")
    end

    it "cleans up extraneous spaces" do
      expect(described_class.instance_eval("cleanup('  4 days and 11     hours')", __FILE__, __LINE__)).to eq("4 days 11 hours")
    end

    it "inserts spaces where there aren't any" do
      expect(described_class.instance_eval("cleanup('4m11.5s')", __FILE__, __LINE__)).to eq("4 minutes 11.5 seconds")
    end
  end

  describe "work week" do
    before do
      allow(described_class).to receive_messages(
        hours_per_day: 8,
        days_per_month: 20
      )
    end

    it "parses knowing the work week" do
      week = described_class.parse("5d")
      expect(described_class.parse("40h")).to eq(week)
      expect(described_class.parse("1w")).to eq(week)
    end
  end
end
