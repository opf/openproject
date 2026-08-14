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

RSpec.describe Queries::CostReports::Filters::CostReportFilter do
  current_user { create(:admin) }

  let(:registered) { Queries::Register.filters[CostReportQuery] }

  def filter_for(attribute, operator, values)
    CostReportQuery.new(name: "probe").tap do |query|
      query.where(attribute, operator, values)
    end
  end

  describe "every registered filter" do
    it "takes its label from the engine filter" do
      static = registered - [Queries::CostReports::Filters::CustomFieldFilter]

      static.each do |filter_class|
        filter = filter_class.create!
        expect(filter.human_name).to be_present, "#{filter_class} has no label"
      end
    end

    it "declares a type" do
      static = registered - [Queries::CostReports::Filters::CustomFieldFilter]

      static.each do |filter_class|
        expect(filter_class.create!.type).to be_a(Symbol), "#{filter_class} has no type"
      end
    end

    it "resolves every operator it offers" do
      static = registered - [Queries::CostReports::Filters::CustomFieldFilter]

      static.each do |filter_class|
        filter = filter_class.create!

        filter.available_operators.each do |operator|
          expect(operator.symbol).to be_present, "#{filter_class} offers an unresolvable operator"
        end
      end
    end

    it "does not build SQL itself, leaving that to the engine" do
      expect { filter_for("spent_on", ">d", ["2026-01-01"]).filters.first.where }
        .to raise_error(NotImplementedError)
    end
  end

  describe "date filters" do
    %w[spent_on start_date due_date created_on updated_on].each do |attribute|
      it "#{attribute} accepts the engine's date operators" do
        expect(filter_for(attribute, ">d", ["2026-01-01"])).to be_valid
        expect(filter_for(attribute, "<d", ["2026-01-01"])).to be_valid
        expect(filter_for(attribute, "<>d", ["2026-01-01", "2026-02-01"])).to be_valid
        expect(filter_for(attribute, "t", [])).to be_valid
      end
    end

    it "resolves >d to the matching operator" do
      filter = filter_for("spent_on", ">d", ["2026-01-01"]).filters.first

      expect(filter.send(:operator_strategy)).to eq(Queries::Operators::GreaterOrEqualDate)
    end

    it "accepts a number of days for >=d" do
      expect(filter_for("spent_on", ">=d", ["7"])).to be_valid
    end

    it "rejects an operator the engine does not offer for dates" do
      expect(filter_for("spent_on", "~", ["nope"])).not_to be_valid
    end

    it "rejects a value that is not a date" do
      expect(filter_for("spent_on", ">d", ["not a date"])).not_to be_valid
    end
  end

  describe "integer filters" do
    %w[tyear tmonth tweek].each do |attribute|
      it "#{attribute} accepts the engine's comparison operators" do
        expect(filter_for(attribute, ">", ["3"])).to be_valid
        expect(filter_for(attribute, "<", ["3"])).to be_valid
        expect(filter_for(attribute, "=", ["3"])).to be_valid
      end
    end

    it "rejects a value that is not a number" do
      expect(filter_for("tyear", ">", ["nope"])).not_to be_valid
    end
  end

  describe "the subject filter" do
    it "accepts the engine's string operators" do
      expect(filter_for("subject", "~", ["foo"])).to be_valid
      expect(filter_for("subject", "!~", ["foo"])).to be_valid
    end
  end

  describe "the project filter" do
    shared_let(:project) { create(:project) }

    it "accepts ids" do
      expect(filter_for("project_id", "=", [project.id.to_s])).to be_valid
    end

    it "accepts the operators that include subprojects" do
      expect(filter_for("project_id", "=_child_projects", [project.id.to_s])).to be_valid
      expect(filter_for("project_id", "!_child_projects", [project.id.to_s])).to be_valid
    end

    it "resolves them to the matching operators" do
      filter = filter_for("project_id", "=_child_projects", [project.id.to_s]).filters.first

      expect(filter.send(:operator_strategy)).to eq(Queries::Operators::ProjectWithSubprojects)
    end
  end

  describe "the work package filter" do
    shared_let(:work_package) { create(:work_package) }

    it "accepts the operators that include descendants" do
      expect(filter_for("work_package_id", "=_child_work_packages", [work_package.id.to_s])).to be_valid
      expect(filter_for("work_package_id", "!_child_work_packages", [work_package.id.to_s])).to be_valid
    end
  end

  describe "the overridden costs filter" do
    it "accepts the engine's yes / no operators" do
      expect(filter_for("overridden_costs", "y", [])).to be_valid
      expect(filter_for("overridden_costs", "n", [])).to be_valid
    end

    it "needs no values" do
      expect(filter_for("overridden_costs", "y", []).filters.first.send(:operator_strategy))
        .not_to be_requires_value
    end
  end

  describe "the status filter" do
    shared_let(:status) { create(:status) }

    it "accepts status ids" do
      expect(filter_for("status_id", "=", [status.id.to_s])).to be_valid
    end

    it "accepts the open and closed operators" do
      expect(filter_for("status_id", "o", [])).to be_valid
      expect(filter_for("status_id", "c", [])).to be_valid
    end

    it "rejects an unknown status id" do
      expect(filter_for("status_id", "=", ["0"])).not_to be_valid
    end
  end

  describe "principal filters" do
    %w[user_id author_id assigned_to_id responsible_id logged_by_id].each do |attribute|
      it "#{attribute} accepts the me value" do
        expect(filter_for(attribute, "=", ["me"])).to be_valid
      end

      it "#{attribute} accepts a principal id" do
        expect(filter_for(attribute, "=", [User.current.id.to_s])).to be_valid
      end

      it "#{attribute} accepts the none and all operators" do
        expect(filter_for(attribute, "!*", [])).to be_valid
        expect(filter_for(attribute, "*", [])).to be_valid
      end
    end

    it "keeps the me value verbatim so it resolves per user" do
      query = filter_for("user_id", "=", ["me"])
      query.save!

      expect(CostReportQuery.find(query.id).filters.first.values).to eq(["me"])
    end
  end

  describe "value list filters" do
    it "takes the allowed values from the engine filter" do
      activity = create(:time_entry_activity)

      expect(filter_for("activity_id", "=", [activity.id.to_s])).to be_valid
    end

    it "rejects values that are not in the list" do
      expect(filter_for("activity_id", "=", ["0"])).not_to be_valid
    end
  end

  describe Queries::CostReports::Filters::CustomFieldFilter do
    shared_let(:custom_field) { create(:list_wp_custom_field, is_filter: true) }

    it "is keyed by custom field id" do
      expect(described_class.key).to match("cf_#{custom_field.id}")
    end

    it "names itself after the custom field" do
      filter = described_class.create!(name: :"cf_#{custom_field.id}")

      expect(filter.human_name).to eq(custom_field.name)
    end

    it "is unavailable for a custom field that no longer exists" do
      removed_id = 0

      expect(described_class.create!(name: :"cf_#{removed_id}")).not_to be_available
    end

    it "derives its type from the custom field format" do
      filter = described_class.create!(name: :"cf_#{custom_field.id}")

      expect(filter.type).to eq(:list_optional)
    end
  end
end
