#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require 'spec_helper'

describe ScheduleHelpers::ChartRepresenter do
  let(:fake_today) { Date.new(2022, 6, 16) } # Thursday 16 June 2022
  let(:monday) { Date.new(2022, 6, 20) } # Monday 20 June
  let(:tuesday) { Date.new(2022, 6, 21) }
  let(:wednesday) { Date.new(2022, 6, 22) }
  let(:thursday) { Date.new(2022, 6, 23) }
  let(:friday) { Date.new(2022, 6, 24) }
  let(:saturday) { Date.new(2022, 6, 25) }
  let(:sunday) { Date.new(2022, 6, 26) }

  describe '#normalized_to_s' do
    let!(:week_days) { create(:week_days) }

    context 'when both charts have different work packages items and/or order' do
      def to_first_columns(charts)
        charts.map { _1.split("\n").map(&:split).map(&:first).join(' ') }
      end

      it 'returns charts ascii with work packages in same order as the first given chart' do
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

      it 'pushes extra elements of the second chart at the end' do
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

        expect(expected_column).to eq('days main other')
        expect(actual_column).to eq('days main other extra')
      end

      it 'keeps extra elements of the first chart at the same place' do
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

        expect(expected_column).to eq('days main extra other')
        expect(actual_column).to eq('days main other')
      end
    end

    context 'when both charts have different first column width' do
      def to_first_cells(charts)
        charts.map { _1.split("\n").first.split(" | ").first }
      end

      it 'returns charts ascii with identical first column width' do
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

        expect(first_cell).to eq('days            ')
        expect(first_cell).to eq(second_cell)

        # tiny_chart as reference chart
        first_cell, second_cell =
          described_class
            .normalized_to_s(longer_chart, tiny_chart)
            .then(&method(:to_first_cells))

        expect(first_cell).to eq('days            ')
        expect(first_cell).to eq(second_cell)
      end
    end

    context 'when both charts cover different time periods' do
      def to_headers(charts)
        charts.map { _1.split("\n").first }
      end

      it 'returns charts ascii with identical time periods' do
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
  end
end
