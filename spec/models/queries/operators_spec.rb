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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Queries::Operators do
  describe "OPERATORS" do
    it "is keyed by symbol" do
      expect(described_class::OPERATORS["="]).to eq(described_class::Equals)
    end

    it "has no two entries claiming the same symbol" do
      symbols = described_class::OPERATORS.values.map { |operator| operator.symbol.to_s }

      expect(symbols).to eq(symbols.uniq)
    end

    it "registers every entry under its own symbol" do
      mismatched = described_class::OPERATORS.reject { |symbol, operator| operator.symbol.to_s == symbol }

      expect(mismatched).to be_empty
    end

    # Guards the alphabetical ordering of the list against careless additions.
    # Compared case insensitively, so that e.g. Includes sorts after In rather
    # than after InMoreThan as a byte wise sort would have it.
    it "is sorted alphabetically by class name" do
      names = described_class::OPERATORS.values.map(&:name)

      expect(names).to eq(names.sort_by(&:downcase))
    end
  end

  describe "the operators the reporting engine relies on" do
    it "registers all of them" do
      symbols = [">d", "<d", ">=d", "<", ">", "y", "n",
                 "=_child_projects", "!_child_projects",
                 "=_child_work_packages", "!_child_work_packages",
                 "o", "c"]

      expect(symbols.reject { |symbol| described_class::OPERATORS.key?(symbol) }).to be_empty
    end
  end

  describe "date operators" do
    before do
      allow(Time).to receive(:zone).and_return(instance_double(ActiveSupport::TimeZone,
                                                               today: Date.new(2026, 3, 10)))
    end

    describe described_class::GreaterOrEqualDate do
      it "constrains to on or after the given date" do
        sql = described_class.sql_for_field(["2026-01-05"], "entries", "spent_on")

        expect(sql).to eq("entries.spent_on > '2026-01-04 23:59:59.999999'")
      end

      it "does not constrain when no date is given" do
        expect(described_class.sql_for_field([""], "entries", "spent_on")).to eq("1 = 1")
      end
    end

    describe described_class::LessOrEqualDate do
      it "constrains to on or before the given date" do
        sql = described_class.sql_for_field(["2026-01-05"], "entries", "spent_on")

        expect(sql).to eq("entries.spent_on <= '2026-01-05 23:59:59.999999'")
      end

      it "does not constrain when no date is given" do
        expect(described_class.sql_for_field([nil], "entries", "spent_on")).to eq("1 = 1")
      end
    end

    describe described_class::DaysAgo do
      it "constrains to the given number of days back until today" do
        sql = described_class.sql_for_field(["4"], "entries", "spent_on")

        expect(sql).to eq("entries.spent_on > '2026-03-05 23:59:59.999999' " \
                          "AND entries.spent_on <= '2026-03-10 23:59:59.999999'")
      end
    end
  end

  describe "numeric operators" do
    describe described_class::GreaterThan do
      it "compares greater than" do
        expect(described_class.sql_for_field(["7"], "entries", "units")).to eq("entries.units > 7.0")
      end
    end

    describe described_class::LessThan do
      it "compares less than" do
        expect(described_class.sql_for_field(["7"], "entries", "units")).to eq("entries.units < 7.0")
      end
    end
  end

  describe "presence operators" do
    describe described_class::Set do
      it "matches rows that have a value" do
        expect(described_class.sql_for_field([], "entries", "overridden_costs"))
          .to eq("entries.overridden_costs IS NOT NULL")
      end

      it "requires no value" do
        expect(described_class).not_to be_requires_value
      end
    end

    describe described_class::Unset do
      it "matches rows that have no value" do
        expect(described_class.sql_for_field([], "entries", "overridden_costs"))
          .to eq("entries.overridden_costs IS NULL")
      end

      it "requires no value" do
        expect(described_class).not_to be_requires_value
      end
    end
  end

  describe "hierarchy operators" do
    shared_let(:parent_project) { create(:project) }
    shared_let(:child_project) { create(:project, parent: parent_project) }
    shared_let(:other_project) { create(:project) }

    shared_let(:parent_work_package) { create(:work_package, project: parent_project) }
    shared_let(:child_work_package) { create(:work_package, project: parent_project, parent: parent_work_package) }

    current_user { create(:admin) }

    describe described_class::ProjectWithSubprojects do
      it "includes the project and its descendants" do
        sql = described_class.sql_for_field([parent_project.id.to_s], "entries", "project_id")

        expect(sql).to include(parent_project.id.to_s, child_project.id.to_s)
        expect(sql).not_to include(other_project.id.to_s)
      end

      it "accepts a comma separated list" do
        sql = described_class.sql_for_field(["#{parent_project.id},#{other_project.id}"], "entries", "project_id")

        expect(sql).to include(parent_project.id.to_s, child_project.id.to_s, other_project.id.to_s)
      end

      it "ignores ids that cannot be found" do
        sql = described_class.sql_for_field(["0"], "entries", "project_id")

        expect(sql).to eq("0=1")
      end
    end

    describe described_class::NotProjectWithSubprojects do
      it "excludes the project and its descendants" do
        sql = described_class.sql_for_field([parent_project.id.to_s], "entries", "project_id")

        expect(sql).to include("NOT IN", parent_project.id.to_s, child_project.id.to_s)
      end
    end

    describe described_class::WorkPackageWithDescendants do
      it "includes the work package and its descendants" do
        sql = described_class.sql_for_field([parent_work_package.id.to_s], "entries", "entity_id")

        expect(sql).to include(parent_work_package.id.to_s, child_work_package.id.to_s)
      end
    end

    describe described_class::NotWorkPackageWithDescendants do
      it "excludes the work package and its descendants" do
        sql = described_class.sql_for_field([parent_work_package.id.to_s], "entries", "entity_id")

        expect(sql).to include("NOT IN", parent_work_package.id.to_s, child_work_package.id.to_s)
      end
    end

    describe "visibility" do
      current_user { create(:user) }

      it "drops projects the user cannot see" do
        sql = described_class::ProjectWithSubprojects.sql_for_field([parent_project.id.to_s],
                                                                    "entries",
                                                                    "project_id")

        expect(sql).to eq("0=1")
      end
    end
  end
end
