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

RSpec.describe WorkPackages::Scopes::CoveringDatesOrDaysOfWeek do
  create_shared_association_defaults_for_work_package_factory

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
      it "returns work packages having start date or due date being in the given days of week" do
        table =
          create_table(<<~TABLE)
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

        expect(WorkPackage.covering_dates_or_days_of_week(**day_args(:tuesday)))
          .to contain_exactly(
            table.work_package("covered1"),
            table.work_package("covered2"),
            table.work_package("covered3"),
            table.work_package("covered4"),
            table.work_package("covered5")
          )
      end

      it "returns work packages having days between start date and due date being in the given days of week" do
        table =
          create_table(<<~TABLE)
            subject      | MTWTFSS |
            covered1     | XXXX    |
            covered2     |  XXX    |
            not_covered1 |    XX   |
            not_covered2 | X       |
          TABLE

        expect(WorkPackage.covering_dates_or_days_of_week(**day_args(:tuesday, :wednesday)))
          .to contain_exactly(
            table.work_package("covered1"),
            table.work_package("covered2")
          )
      end

      context "if work package ignores non working days" do
        it "does not returns it" do
          create_table(<<~TABLE)
            subject      | MTWTFSS | days counting
            not_covered  | XXXXXXX | all days
          TABLE

          expect(WorkPackage.covering_dates_or_days_of_week(**day_args(:wednesday)))
            .to eq([])
        end
      end

      it "does not return work packages having follows relation covering the given days of week" do
        create_table(<<~TABLE)
          subject      | MTWTFSS | predecessors
          not_covered1 | X       |
          follower1    |     X   | not_covered1
          not_covered2 | X       |
          follower2    |   X     | not_covered2
        TABLE

        expect(WorkPackage.covering_dates_or_days_of_week(**day_args(:tuesday, :thursday)))
          .to eq([])
      end

      it "does not return work packages having follows relation with lag covering the given days of week" do
        create_table(<<~TABLE)
          subject      | MTWTFSS | predecessors
          not_covered1 | X       |
          follower1    |     X   | not_covered1 with lag 3
          not_covered2 | X       |
          follower2    |   X     | not_covered2 with lag 1
        TABLE

        expect(WorkPackage.covering_dates_or_days_of_week(**day_args(:tuesday, :thursday)))
          .to eq([])
      end

      it "accepts a single day of week or an array of days" do
        table =
          create_table(<<~TABLE)
            subject       | MTWTFSS |
            covered       |  X      |
            not_covered   | X       |
          TABLE

        single_value = day_args(:tuesday).transform_values { |v| Array(v).first }

        expect(WorkPackage.covering_dates_or_days_of_week(**single_value))
          .to eq([table.work_package("covered")])
        expect(WorkPackage.covering_dates_or_days_of_week(**day_args(:tuesday)))
          .to eq([table.work_package("covered")])
        expect(WorkPackage.covering_dates_or_days_of_week(**day_args(:tuesday, :wednesday)))
          .to eq([table.work_package("covered")])
      end
    end

    describe "#predecessors_needing_relations_rescheduling" do
      it "returns nothing if no days of week or dates are provided" do
        create_table(<<~TABLE)
          subject      |  MTWTFSS | scheduling mode | predecessors
          covered1     | XX       | manual          |
          succ1        |      XX  | automatic       | covered1
        TABLE

        expect(WorkPackage.predecessors_needing_relations_rescheduling(**day_args).pluck(:subject))
          .to eq([])
      end

      it "returns work packages being predecessors in a relation covering the given days" do
        create_table(<<~TABLE)
          subject      |  MTWTFSS | scheduling mode | predecessors
          covered1     | XX ░     | manual          |
          succ1        |    ░ XX  | automatic       | covered1

          covered2     |  XX░     | manual          |
          succ2        |    ░XX   | automatic       | covered2

          not_covered3 |  XX░     | manual          |
          succ3        |    XX    | automatic       | not_covered3

          not_covered4 |   XX     | manual          |
          succ4        |    ░XX   | automatic       | not_covered4

          not_covered5 |   XX     | manual          |
          succ5        |    ░ XX  | automatic       | not_covered5

          not_covered6 | XX ░     | manual          |
          succ6        |    XX    | automatic       | not_covered6
        TABLE

        expect(WorkPackage.predecessors_needing_relations_rescheduling(**day_args(:wednesday)).pluck(:subject))
          .to contain_exactly(
            "covered1",
            "covered2"
          )
      end

      it "does not return non-impacting predecessors from a chain of successors" do
        create_table(<<~TABLE)
          subject      |  MTWTFSS | scheduling mode | predecessors
          pred         |  X  ░    | manual          |
          succ1        |   X ░    | automatic       | pred
          succ2        |    X░    | automatic       | succ1
          succ3        |     ░X   | automatic       | succ2
          succ4        |     ░ XX | automatic       | succ3
        TABLE

        expect(WorkPackage.predecessors_needing_relations_rescheduling(**day_args(:thursday)).pluck(:subject))
          .to contain_exactly(
            "succ2"
          )
      end

      it "returns each impacting predecessor in a chain of successors" do
        create_table(<<~TABLE)
          subject      | MTWTFSSmtwtfss | scheduling mode | predecessors
          pred         | X   ░      ░   | manual          |
          succ1        |   X ░      ░   | automatic       | pred
          succ2        |     ░ X    ░   | automatic       | succ1
          succ3        |     ░   X  ░   | automatic       | succ2
          succ4        |     ░      ░ X | automatic       | succ3
        TABLE

        expect(WorkPackage.predecessors_needing_relations_rescheduling(**day_args(:friday)).pluck(:subject))
          .to contain_exactly(
            "succ1",
            "succ3"
          )
      end

      it "when there are multiple follows relations to the same successor, " \
         "it returns only the farthest predecessor for each successor" do
        create_table(<<~TABLE)
          subject      | MTWTFSSmtwtfss | scheduling mode | predecessors
          pred1        |   X ░      ░   | manual          |
          pred2        | X   ░      ░   | manual          |
          pred3        |     ░ X    ░   | manual          |
          succ         |     ░   X  ░   | automatic       | pred1, pred2, pred3
        TABLE

        expect(WorkPackage.predecessors_needing_relations_rescheduling(**day_args(:friday)).pluck(:subject))
          .to contain_exactly("pred2")
      end
    end
  end
end
