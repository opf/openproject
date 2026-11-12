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

RSpec.describe Project::Phases::Scopes::CoveringDatesOrDaysOfWeek do
  # Constructs the keyword arguments for the `#covering_dates_or_days_of_week` method.
  # It's a `{ days_of_week:, dates: }` hash for given days of week built differently
  # depending on the `days_args_strategy` value.
  #
  # `days_args_strategy` can take the following values:
  # - `:days_of_week_only`: returns `{ days_of_week: ..., dates: [] }` so it
  #   only contains days of week
  # - `:dates_only`: returns `{ days_of_week: [], dates: ... }` so it only
  #   contains specific dates for the specified days of weeks over the next 2
  #   weeks
  # - `:mixed`: returns `{ days_of_week: ..., dates: ... }` so it contains a mix of days
  #   of week and specific dates: Monday, Wednesday, Friday and Sunday are days of week, and
  #   Tuesday, Thursday and Saturday are dates
  def day_args(*days_of_week_as_symbols)
    next_monday = Date.current.next_occurring(:monday)
    values = days_of_week_as_symbols.map { |dow| next_monday.next_occurring(dow.to_sym) }
                         .flat_map { |day| [day, day + 7.days] }

    case days_args_strategy
    when :days_of_week_only
      days_of_week = values.map(&:cwday).uniq
      dates = []
    when :dates_only
      days_of_week = []
      dates = values
    when :mixed
      # Monday, Wednesday, Friday and Sunday as days of week
      # Tuesday, Thursday and Saturday as dates
      days_of_week = values.map(&:cwday).uniq.filter(&:odd?)
      dates = values.filter { |day| day.cwday.even? }
    end
    { days_of_week:, dates: }
  end

  def create_phases_from_table(representation)
    # TODO: less hacky way to adapt tables for work packages to create phases
    TableHelpers::TableParser.new.parse(representation).to_h do |entry|
      entry => { attributes: { subject:, start_date:, due_date: } }
      [
        subject,
        create(:project_phase, start_date:, finish_date: due_date)
      ]
    end
  end

  shared_context "with the days of week" do
    let(:days_args_strategy) { :days_of_week_only }
  end

  shared_context "with specific dates" do
    let(:days_args_strategy) { :dates_only }
  end

  shared_context "with days of week and specific dates mixed" do
    let(:days_args_strategy) { :mixed }
  end

  for_each_context "with the days of week",
                   "with specific dates",
                   "with days of week and specific dates mixed" do
    describe "#covering_dates_or_days_of_week" do
      it "returns phases having start date or due date being in the given days of week" do
        table =
          create_phases_from_table(<<~TABLE)
            subject      | MTWTFSS |
            covered1     | XX      |
            covered2     |  XX     |
            covered3     |  X      |
            covered4     |  [      |
            covered5     |  ]      |
            not_covered1 | X       |
            not_covered2 |   X     |
            not_covered3 |    XX   |
            not_covered4 |         |
          TABLE

        expect(Project::Phase.covering_dates_or_days_of_week(**day_args(:tuesday)))
          .to contain_exactly(
            table["covered1"],
            table["covered2"],
            table["covered3"],
            table["covered4"],
            table["covered5"]
          )
      end

      it "returns phases having days between start date and due date being in the given days of week" do
        table =
          create_phases_from_table(<<~TABLE)
            subject      | MTWTFSS |
            covered1     | XXXX    |
            covered2     |  XXX    |
            not_covered1 |    XX   |
            not_covered2 | X       |
          TABLE

        expect(Project::Phase.covering_dates_or_days_of_week(**day_args(:tuesday, :wednesday)))
          .to contain_exactly(
            table["covered1"],
            table["covered2"]
          )
      end

      it "accepts a single day of week or an array of days" do
        table =
          create_phases_from_table(<<~TABLE)
            subject       | MTWTFSS |
            covered       |  X      |
            not_covered   | X       |
          TABLE

        single_value = day_args(:tuesday).transform_values { |v| Array(v).first }

        expect(Project::Phase.covering_dates_or_days_of_week(**single_value))
          .to eq([table["covered"]])
        expect(Project::Phase.covering_dates_or_days_of_week(**day_args(:tuesday)))
          .to eq([table["covered"]])
        expect(Project::Phase.covering_dates_or_days_of_week(**day_args(:tuesday, :wednesday)))
          .to eq([table["covered"]])
      end
    end
  end
end
