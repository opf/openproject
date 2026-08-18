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

RSpec.describe CostReport do
  shared_let(:project) { create(:project) }
  let(:user) { create(:admin) }
  let(:query) { create(:cost_report_query, principal: user) }
  let(:instance) { described_class.new(name: "Costs", query:, principal: user) }

  describe "persistence" do
    it "is stored as a PersistedView" do
      instance.save!

      expect(PersistedView.find(instance.id)).to be_a(described_class)
    end

    it "categorises itself as a cost report" do
      instance.save!

      expect(instance.category).to eq("cost_report")
    end

    it "requires a query" do
      instance.query = nil

      expect(instance).not_to be_valid
      expect(instance.errors[:query]).to be_present
    end

    it "starts with empty pivot axes" do
      expect(instance.pivot_rows).to eq([])
      expect(instance.pivot_columns).to eq([])
    end
  end

  describe "#apply_pivot_configuration" do
    before do
      instance.apply_pivot_configuration(rows: [:project_id], columns: [:week])
    end

    it "stores the axes as strings" do
      expect(instance.pivot_rows).to eq(%w[project_id])
      expect(instance.pivot_columns).to eq(%w[week])
    end

    it "derives the query's group bys from the axes, columns first" do
      expect(instance.query.group_bys.map(&:name)).to eq(%i[week project_id])
    end

    it "is valid" do
      expect(instance).to be_valid
    end

    it "persists the axes and the derived group bys together" do
      instance.save!

      reloaded = described_class.find(instance.id)

      expect(reloaded.pivot_rows).to eq(%w[project_id])
      expect(reloaded.pivot_columns).to eq(%w[week])
      expect(reloaded.query.group_bys.map(&:name)).to eq(%i[week project_id])
    end

    it "keeps the nesting order within an axis" do
      instance.apply_pivot_configuration(rows: %i[project_id work_package_id], columns: [])
      instance.save!

      expect(described_class.find(instance.id).pivot_rows).to eq(%w[project_id work_package_id])
    end

    it "replaces a previous configuration" do
      instance.apply_pivot_configuration(rows: [:user_id], columns: [])

      expect(instance.pivot_rows).to eq(%w[user_id])
      expect(instance.pivot_columns).to eq([])
      expect(instance.query.group_bys.map(&:name)).to eq(%i[user_id])
    end
  end

  describe "axes and group bys agreeing" do
    it "is invalid when the query groups by something no axis mentions" do
      instance.apply_pivot_configuration(rows: [:project_id], columns: [])
      instance.query.group(:project_id, :week)

      expect(instance).not_to be_valid
      expect(instance.errors[:base]).to be_present
    end

    it "is invalid when an axis mentions something the query does not group by" do
      instance.apply_pivot_configuration(rows: [:project_id], columns: [])
      instance.query.group_bys = []

      expect(instance).not_to be_valid
    end
  end

  describe "#engine_query" do
    before do
      instance.query.where("spent_on", ">d", ["2026-01-01"])
      instance.apply_pivot_configuration(rows: %i[project_id work_package_id], columns: [:week])
    end

    it "lays the dimensions out on the axes this view holds" do
      replayed = instance.engine_query.group_bys.map { |group_by| [group_by.class.name.demodulize, group_by.type] }

      expect(replayed).to eq([["ProjectId", :row], ["WorkPackageId", :row], ["Week", :column]])
    end

    it "replays the query's filters" do
      expect(instance.engine_query.filters.map { |filter| filter.class.name.demodulize })
        .to include("SpentOn")
    end

    it "builds a chain that produces SQL" do
      expect(instance.engine_query.sql_statement.to_s).to be_present
    end

    context "when an axis is empty" do
      it "fills an empty row axis with the singleton dimension" do
        instance.apply_pivot_configuration(rows: [], columns: [:week])

        replayed = instance.engine_query.group_bys.map { |group_by| [group_by.class.name.demodulize, group_by.type] }

        expect(replayed).to eq([["SingletonValue", :row], ["Week", :column]])
      end

      it "fills an empty column axis with the singleton dimension" do
        instance.apply_pivot_configuration(rows: [:project_id], columns: [])

        replayed = instance.engine_query.group_bys.map { |group_by| [group_by.class.name.demodulize, group_by.type] }

        expect(replayed).to eq([["ProjectId", :row], ["SingletonValue", :column]])
      end

      it "does not touch the stored axes or the query's group bys" do
        instance.apply_pivot_configuration(rows: [], columns: [:week])
        instance.engine_query

        expect(instance.pivot_rows).to eq([])
        expect(instance.query.group_bys.map(&:name)).to eq([:week])
      end

      it "stays valid" do
        instance.apply_pivot_configuration(rows: [], columns: [:week])
        instance.engine_query

        expect(instance).to be_valid
      end
    end

    context "without any dimension" do
      it "adds no singleton, because there is no pivot to render" do
        instance.apply_pivot_configuration(rows: [], columns: [])

        expect(instance.engine_query.group_bys).to eq([])
        expect(instance).not_to be_pivot
      end
    end
  end

  describe "#build_default_query" do
    let(:instance) { described_class.new(name: "Costs", project:, principal: user) }

    it "builds a cost report query for the same project and principal" do
      built = instance.build_default_query

      expect(built).to be_a(CostReportQuery)
      expect(built.project).to eq(project)
      expect(built.principal).to eq(user)
    end
  end

  describe "#visible?" do
    let(:permissions) { %i[view_cost_entries] }
    let(:owner) { create(:user, member_with_permissions: { project => permissions }) }
    let(:other) { create(:user, member_with_permissions: { project => permissions }) }
    let(:without_permission) { create(:user) }

    # A global report, as created from the global cost reports page.
    let(:instance) { create(:cost_report, principal: owner, public: false) }

    it "is visible to its owner" do
      expect(instance).to be_visible(owner)
    end

    it "is not visible to somebody else while private" do
      expect(instance).not_to be_visible(other)
    end

    it "is visible to somebody else once public" do
      instance.update!(public: true)

      expect(instance).to be_visible(other)
    end

    it "is not visible without any of the reporting permissions" do
      expect(instance).not_to be_visible(without_permission)
    end

    # The controller registers its view actions for all four of these.
    described_class::VIEW_PERMISSIONS.each do |permission|
      it "is visible with only #{permission}" do
        user = create(:user, member_with_permissions: { project => [permission] })
        instance.update!(public: true)

        expect(instance).to be_visible(user)
      end
    end

    it "is not visible to an admin while it is somebody else's private report" do
      expect(instance).not_to be_visible(create(:admin))
    end

    context "when bound to a project" do
      let(:other_project) { create(:project) }
      let(:instance) { create(:cost_report, principal: owner, public: true, project:) }

      it "is visible to a user with the permission in that project" do
        expect(instance).to be_visible(other)
      end

      it "is not visible to a user who only has the permission elsewhere" do
        elsewhere = create(:user, member_with_permissions: { other_project => permissions })

        expect(instance).not_to be_visible(elsewhere)
      end
    end
  end

  describe "#unit_id" do
    it "stores the selected unit on the view" do
      instance.unit_id = 3
      instance.save!

      expect(described_class.find(instance.id).unit_id).to eq(3)
    end
  end

  describe ".for_legacy_cost_query_id" do
    it "finds the report converted from that cost query" do
      instance.legacy_cost_query_id = 42
      instance.save!

      expect(described_class.for_legacy_cost_query_id(42)).to eq(instance)
    end

    it "accepts the id as a string" do
      instance.legacy_cost_query_id = 42
      instance.save!

      expect(described_class.for_legacy_cost_query_id("42")).to eq(instance)
    end

    it "is nil for a report that was not converted" do
      instance.save!

      expect(described_class.for_legacy_cost_query_id(42)).to be_nil
    end
  end
end
