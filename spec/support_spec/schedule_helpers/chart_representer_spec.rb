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

RSpec.describe ScheduleHelpers::ChartRepresenter do
  describe "#normalized_to_s" do
    shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

    context "when both charts have different work packages items and/or order" do
      def to_first_columns(charts)
        charts.map { _1.split("\n").map(&:split).map(&:first).join(" ") }
      end

      it "returns charts ascii with work packages in same order as the first given chart" do
        initial_expected_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days       |    MTWTFSS  |
            main       | X..X        |
            other      |      XXX..X |
          CHART
        initial_actual_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days       |    MTWTFSS  |
            other      |      XXX..X |
            main       | X..X        |
          CHART

        expected_column, actual_column =
          described_class
            .normalized_to_s(initial_expected_chart, initial_actual_chart)
            .then(&method(:to_first_columns))

        expect(actual_column).to eq(expected_column)
      end

      it "pushes extra elements of the second chart at the end" do
        initial_expected_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days       |    MTWTFSS  |
            main       | X..X        |
            other      |      XXX..X |
          CHART
        initial_actual_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days       |    MTWTFSS  |
            extra      |             |
            main       | X..X        |
            other      |      XXX..X |
          CHART

        expected_column, actual_column =
          described_class
            .normalized_to_s(initial_expected_chart, initial_actual_chart)
            .then(&method(:to_first_columns))

        expect(expected_column).to eq("days main other")
        expect(actual_column).to eq("days main other extra")
      end

      it "keeps extra elements of the first chart at the same place" do
        initial_expected_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days       |    MTWTFSS  |
            main       | X..X        |
            extra      |             |
            other      |      XXX..X |
          CHART
        initial_actual_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days       |    MTWTFSS  |
            main       | X..X        |
            other      |      XXX..X |
          CHART

        expected_column, actual_column =
          described_class
            .normalized_to_s(initial_expected_chart, initial_actual_chart)
            .then(&method(:to_first_columns))

        expect(expected_column).to eq("days main extra other")
        expect(actual_column).to eq("days main other")
      end
    end

    context "when both charts have different first column width" do
      def to_first_cells(charts)
        charts.map { _1.split("\n").first.split(" | ").first }
      end

      it "returns charts ascii with identical first column width" do
        tiny_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days      | MTWTFSS |
            tiny name |   XX    |
          CHART
        longer_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days             | MTWTFSS |
            much longer name |   XX    |
          CHART

        # tiny_chart as reference chart
        first_cell, second_cell =
          described_class
            .normalized_to_s(tiny_chart, longer_chart)
            .then(&method(:to_first_cells))

        expect(first_cell).to eq("days            ")
        expect(first_cell).to eq(second_cell)

        # tiny_chart as reference chart
        first_cell, second_cell =
          described_class
            .normalized_to_s(longer_chart, tiny_chart)
            .then(&method(:to_first_cells))

        expect(first_cell).to eq("days            ")
        expect(first_cell).to eq(second_cell)
      end
    end

    context "when both charts cover different time periods" do
      def to_headers(charts)
        charts.map { _1.split("\n").first }
      end

      it "returns charts ascii with identical time periods" do
        larger_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days       |   MTWTFSS   |
            main       | XXXXXXXXXXX |
          CHART
        shorter_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days       | MTWTFSS |
            main       |   XXX   |
          CHART

        # larger_chart as reference
        first_header, second_header =
          described_class
            .normalized_to_s(larger_chart, shorter_chart)
            .then(&method(:to_headers))

        expect(first_header).to eq(second_header)

        # shorter_chart as reference
        first_header, second_header =
          described_class
            .normalized_to_s(shorter_chart, larger_chart)
            .then(&method(:to_headers))

        expect(first_header).to eq(second_header)
      end
    end

    context "when expected chart does not have working days information" do
      def to_headers(charts)
        charts.map { _1.split("\n").first }
      end

      it "gets it from actual chart information" do
        # in real tests, actual will probably be created from WorkPackage instances
        actual_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days  | MTWTFSS  |
            main  |   XXXXX  | working days include weekends
            other |     X..X | working days work week
          CHART
        expected_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days  | MTWTFSS  |
            main  |   XXXXX  |
            other |     X..X |
          CHART

        normalized_expected, normalized_actual =
          described_class
            .normalized_to_s(expected_chart, actual_chart)

        expect(normalized_actual).to eq(normalized_expected)
      end

      it "ignores working days information for extra work packages not defined in actual" do
        initial_actual_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days       |    MTWTFSS  |
            main       | X..X        |
          CHART
        initial_expected_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days       |    MTWTFSS  |
            main       | X..X        |
            extra      |             |
          CHART

        expect { described_class.normalized_to_s(initial_expected_chart, initial_actual_chart) }
          .not_to raise_error
      end
    end

    context "when expected chart has different working days information from actual" do
      def to_headers(charts)
        charts.map { _1.split("\n").first }
      end

      it "use each information from each side" do
        # in real tests, actual will probably be created from WorkPackage instances
        actual_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days  | MTWTFSS  |
            main  | XXXXXXXX | working days include weekends
            other |     X..X | working days work week
            foo   |     X..X |
          CHART
        expected_chart =
          ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
            days  | MTWTFSS  |
            main  | XXXXX..X | working days work week
            other |     XXXX | working days include weekends
            foo   |     X..X |
          CHART

        normalized_expected, normalized_actual =
          described_class
            .normalized_to_s(expected_chart, actual_chart)

        expect(normalized_actual).to eq(<<~CHART.strip)
          days  | MTWTFSS  |
          main  | XXXXXXXX |
          other |     X..X |
          foo   |     X..X |
        CHART
        expect(normalized_expected).to eq(<<~CHART.strip)
          days  | MTWTFSS  |
          main  | XXXXX..X |
          other |     XXXX |
          foo   |     X..X |
        CHART
      end
    end
  end
end
