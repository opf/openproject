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
require Rails.root.join(
  "modules/reporting/db/migrate/20260814153519_migrate_cost_queries_to_cost_reports.rb"
)

RSpec.describe MigrateCostQueriesToCostReports, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  shared_let(:user) { create(:user) }
  shared_let(:project) { create(:project) }

  # A filter carrying the "me" value only validates for a logged in user, which
  # is always the case when a report is actually run.
  current_user { create(:admin) }

  # Builds a cost query through the engine, so the stored YAML is exactly what
  # the old implementation produces rather than a hand written approximation.
  def create_cost_query(name:, is_public: false, in_project: nil, &)
    query = CostQuery.new(project: in_project)
    yield(query) if block_given?

    query.name = name
    query.user_id = user.id
    query.project_id = in_project&.id
    query.is_public = is_public
    query.save!
    query
  end

  describe "a report with filters and both axes" do
    let!(:cost_query) do
      create_cost_query(name: "Spent per week", is_public: true, in_project: project) do |query|
        query.filter(:spent_on, operator: ">d", values: ["2026-01-01"])
        query.filter(:user_id, operator: "=", values: ["me"])
        query.column(:week)
        query.row(:project_id)
      end
    end

    before { migrate }

    it "creates one query and one view" do
      expect(CostReportQuery.count).to eq(1)
      expect(CostReport.count).to eq(1)
    end

    it "moves the name, ownership and publicity onto the view" do
      report = CostReport.last

      expect(report.name).to eq("Spent per week")
      expect(report.principal).to eq(user)
      expect(report.project).to eq(project)
      expect(report).to be_public
      expect(report.category).to eq("cost_report")
    end

    it "keeps the original id so old report links still resolve" do
      expect(CostReport.last.legacy_cost_query_id).to eq(cost_query.id)
      expect(CostReport.for_legacy_cost_query_id(cost_query.id)).to eq(CostReport.last)
    end

    it "links the view to its query" do
      expect(CostReport.last.query).to eq(CostReportQuery.last)
    end

    it "converts the filters, keeping operators and values" do
      filters = CostReportQuery.last.filters.map { |f| [f.name, f.operator, f.values] }

      expect(filters).to contain_exactly([:spent_on, ">d", ["2026-01-01"]],
                                         [:user_id, "=", ["me"]])
    end

    it "splits the group bys onto the view's axes" do
      report = CostReport.last

      expect(report.pivot_columns).to eq(%w[week])
      expect(report.pivot_rows).to eq(%w[project_id])
    end

    it "derives the query's group bys from the axes, columns first" do
      expect(CostReportQuery.last.group_bys.map(&:name)).to eq(%i[week project_id])
    end

    it "produces a valid query and view" do
      expect(CostReportQuery.last).to be_valid
      expect(CostReport.last).to be_valid
    end

    it "keeps the timestamps of the original report" do
      expect(CostReport.last.created_at).to be_within(1.second).of(cost_query.created_at)
    end

    it "leaves the original row in place" do
      expect(CostQuery.count).to eq(1)
    end
  end

  describe "the system filter the engine injects" do
    let!(:cost_query) do
      create_cost_query(name: "With permissions") do |query|
        query.filter(:spent_on, operator: ">d", values: ["2026-01-01"])
      end
    end

    it "serializes a permission filter in the original" do
      expect(cost_query.serialized[:filters].map(&:first)).to include("PermissionFilter")
    end

    it "is not carried over" do
      migrate

      expect(CostReportQuery.last.filters.map(&:name)).to eq([:spent_on])
    end
  end

  describe "nesting order within an axis" do
    let!(:cost_query) do
      create_cost_query(name: "Nested") do |query|
        # The engine prepends, so the arguments are given in reverse of the
        # order the user sees, exactly as CostReportsController#build_query does.
        query.row(:work_package_id)
        query.row(:project_id)
        query.column(:tmonth)
        query.column(:tyear)
      end
    end

    it "keeps the order the user arranged the rows in" do
      migrate

      expect(CostReport.last.pivot_rows).to eq(%w[project_id work_package_id])
    end

    it "keeps the order the user arranged the columns in" do
      migrate

      expect(CostReport.last.pivot_columns).to eq(%w[tyear tmonth])
    end

    it "round trips through the engine unchanged, axes included" do
      migrate

      replayed = CostReport.last.group_bys
                           .map { |group_by| [group_by.class.name.demodulize, group_by.type] }
      original = cost_query.group_bys
                           .map { |group_by| [group_by.class.name.demodulize, group_by.type] }

      expect(replayed).to eq(original)
    end
  end

  describe "a report without any group by" do
    let!(:cost_query) do
      create_cost_query(name: "Flat list") do |query|
        query.filter(:spent_on, operator: ">d", values: ["2026-01-01"])
      end
    end

    it "leaves both axes empty" do
      migrate

      report = CostReport.last

      expect(report.pivot_rows).to eq([])
      expect(report.pivot_columns).to eq([])
      expect(report.query.group_bys).to eq([])
    end

    it "produces a valid report" do
      migrate

      expect(CostReport.last).to be_valid
    end
  end

  describe "a custom field filter and group by" do
    shared_let(:custom_field) { create(:list_wp_custom_field, is_filter: true, is_for_all: true) }

    let!(:cost_query) do
      custom_field
      CostQuery::Cache.reset!

      # The engine generates a class per custom field, and add_chain looks the
      # class up before the chain gets a chance to generate it - swallowing the
      # NameError and dropping the group by. This is what the controller's
      # load_all before_action exists for.
      CostQuery::GroupBy.all
      CostQuery::Filter.all

      create_cost_query(name: "By custom field") do |query|
        query.row(:"custom_field_#{custom_field.id}")
      end
    end

    it "translates the engine's class name into the cf_<id> attribute" do
      migrate

      expect(CostReport.last.pivot_rows).to eq(["cf_#{custom_field.id}"])
      expect(CostReportQuery.last.group_bys.map(&:name)).to eq([:"cf_#{custom_field.id}"])
    end
  end

  describe "a global report" do
    let!(:cost_query) { create_cost_query(name: "Everything", is_public: true) }

    it "stays without a project" do
      migrate

      expect(CostReport.last.project).to be_nil
      expect(CostReportQuery.last.project).to be_nil
    end
  end

  describe "an unreadable definition" do
    let!(:cost_query) { create_cost_query(name: "Broken") }

    # Written through the migration's own model, which does not serialize the
    # column, to get invalid YAML into the database at all.
    before do
      described_class::CostQuery.find(cost_query.id).update_column(:serialized, "{ not: valid: yaml")
    end

    it "does not raise" do
      expect { migrate }.not_to raise_error
    end

    it "skips the report" do
      migrate

      expect(CostReport.count).to eq(0)
    end
  end

  describe "reverting" do
    let!(:cost_query) do
      create_cost_query(name: "Spent per week") do |query|
        query.column(:week)
      end
    end

    it "removes what it created" do
      migrate

      expect { ActiveRecord::Migration.suppress_messages { described_class.new.down } }
        .to change(CostReport, :count).from(1).to(0)
        .and change(CostReportQuery, :count).from(1).to(0)
    end
  end
end
