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

require_relative "../../spec_helper"
require_relative "../../support/custom_field_filter"

RSpec.describe CostQuery, :reporting_query_helper do
  let!(:type) { create(:type) }
  let!(:project1) { create(:project_with_types, types: [type]) }
  let!(:work_package1) { create(:work_package, project: project1, type:) }
  let!(:time_entry1) do
    create(:time_entry, entity: work_package1, project: project1, spent_on: Date.new(2012, 1, 1))
  end
  let!(:time_entry2) do
    time_entry2 = time_entry1.dup
    time_entry2.save!
    time_entry2
  end
  let!(:budget1) { create(:budget, project: project1) }
  let!(:cost_entry1) do
    create(:cost_entry, entity: work_package1, project: project1, spent_on: Date.new(2013, 2, 3))
  end
  let!(:cost_entry2) do
    cost_entry2 = cost_entry1.dup
    cost_entry2.save!
    cost_entry2
  end

  let!(:project2) { create(:project_with_types, types: [type]) }
  let!(:work_package2) { create(:work_package, project: project2, type:) }
  let!(:time_entry3) do
    create(:time_entry, entity: work_package2, project: project2, spent_on: Date.new(2013, 2, 3))
  end
  let!(:time_entry4) do
    time_entry4 = time_entry3.dup
    time_entry4.save!
    time_entry4
  end
  let!(:budget2) { create(:budget, project: project2) }
  let!(:cost_entry3) do
    create(:cost_entry, entity: work_package2, project: project2, spent_on: Date.new(2012, 1, 1))
  end
  let!(:cost_entry4) do
    cost_entry4 = cost_entry3.dup
    cost_entry4.save!
    cost_entry4
  end

  minimal_query

  describe CostQuery::GroupBy do
    it "does not fail when grouping by a non-existent column" do
      expect { query.group_by(:non_existent_column).result }.not_to raise_error
    end

    it "computes group_by on projects" do
      query.group_by :project_id
      expect(query.result.size).to eq(2)
    end

    it "keeps own and all parents' group fields in all_group_fields" do
      query.group_by :project_id
      query.group_by :work_package_id
      query.group_by :cost_type_id
      expect(query.all_group_fields).to eq(%w[entries.cost_type_id])
      expect(query.child.all_group_fields).to eq(%w[entries.cost_type_id entries.entity_gid])
      expect(query.child.child.all_group_fields).to eq(%w[entries.cost_type_id entries.entity_gid entries.project_id])
    end

    it "computes group_by WorkPackage" do
      query.group_by :work_package_id
      expect(query.result.size).to eq(2)
    end

    it "labels the group 'Version' while multiple versions is off", with_settings: { work_package_multiple_versions: false } do
      expect(CostQuery::GroupBy::VersionId.label).to eq("Version")
    end

    # While the feature is off a work package is single-version, so it is grouped
    # under its primary target version only (the lowest version id, i.e. what
    # target_versions.first returns) and the grouped total matches the ungrouped
    # entry count.
    it "computes group_by Version, listing a work package under its primary target version",
       with_settings: { work_package_multiple_versions: false } do
      version1 = create(:version, project: project1)
      version2 = create(:version, project: project1)
      work_package = create(:work_package, project: project1, type:, version: version1)
      work_package.work_package_versions.create!(version: version2, kind: "target")
      create(:time_entry, entity: work_package, project: project1, spent_on: Date.new(2012, 1, 1))

      query.group_by :version_id
      # work_package1 / work_package2 entries have no target version (one group);
      # the new work package adds a single primary-version group.
      expect(query.result.size).to eq(2)

      total_count = query.result.each_direct_result.sum(&:count)
      expect(total_count).to eq(Entry.count)
    end

    # Filter and group-by declare the same target-version join; the engine
    # collapses it only while both emit an identical join statement. If they
    # drift apart the combined query fails with a duplicate-table error.
    it "combines the version filter and group-by on a single join" do
      version = create(:version, project: project1)
      work_package = create(:work_package, project: project1, type:, version:)
      create(:time_entry, entity: work_package, project: project1, spent_on: Date.new(2012, 1, 1))

      query.filter :version_id, operator: "=", value: version.id
      query.group_by :version_id
      expect(query.result.size).to eq(1)
    end

    context "with multiple target versions enabled",
            with_settings: { work_package_multiple_versions: true } do
      it "labels the group 'Target versions'" do
        expect(CostQuery::GroupBy::VersionId.label).to eq("Target versions")
      end

      it "computes group_by Version, listing a work package under each target version" do
        version1 = create(:version, project: project1)
        version2 = create(:version, project: project1)
        work_package = create(:work_package, project: project1, type:, version: version1)
        work_package.work_package_versions.create!(version: version2, kind: "target")
        create(:time_entry, entity: work_package, project: project1, spent_on: Date.new(2012, 1, 1))

        query.group_by :version_id
        # work_package1 / work_package2 entries have no target version (one group);
        # the new work package is reported under both of its target versions.
        expect(query.result.size).to eq(3)

        # OPEN POINT FND-178: cost reports over-count totals when grouping or
        # filtering by a multi-value attribute. The single time entry is counted
        # once under each target-version group, so the grouped total exceeds the
        # ungrouped entry count. This is accepted for now (team decision); the
        # assertion pins the inflated total, not just the group count, so a later
        # "fix" can't quietly change it without revisiting FND-178.
        total_count = query.result.each_direct_result.sum(&:count)
        expect(total_count).to eq(Entry.count + 1)
      end

      # Same duplicate-join guard as the off-mode spec, on the all-versions join.
      it "combines the version filter and group-by on a single join" do
        version1 = create(:version, project: project1)
        version2 = create(:version, project: project1)
        work_package = create(:work_package, project: project1, type:, version: version1)
        work_package.work_package_versions.create!(version: version2, kind: "target")
        create(:time_entry, entity: work_package, project: project1, spent_on: Date.new(2012, 1, 1))

        query.filter :version_id, operator: "=", value: [version1.id, version2.id]
        query.group_by :version_id
        # One group per matching target version of the single work package.
        expect(query.result.size).to eq(2)
      end
    end

    it "does not group a Meeting time entry under a same-id work package's target version" do
      version = create(:version, project: project1)
      work_package = create(:work_package, project: project1, type:, version:)
      # entries.entity_id is polymorphic; simulate a meeting time entry whose id
      # collides with the versioned work package's id.
      meeting_entry = create(:time_entry, entity: work_package, project: project1, spent_on: Date.new(2012, 1, 1))
      meeting_entry.update_columns(entity_type: "Meeting")

      query.group_by :version_id
      # The meeting entry must stay in the no-version group with work_package1 /
      # work_package2 rather than inheriting the work package's target version.
      expect(query.result.size).to eq(1)
    end

    it "computes group_by CostType" do
      query.group_by :cost_type_id
      # type 'Labor' for time entries, 2 different cost types
      expect(query.result.size).to eq(3)
    end

    it "computes group_by Activity" do
      query.group_by :activity_id
      # "-1" for time entries, 2 different cost activities
      expect(query.result.size).to eq(3)
    end

    it "computes group_by Date (day)" do
      query.group_by :spent_on
      expect(query.result.size).to eq(2)
    end

    it "computes group_by Date (week)" do
      query.group_by :tweek
      expect(query.result.size).to eq(2)
    end

    it "computes group_by Date (month)" do
      query.group_by :tmonth
      expect(query.result.size).to eq(2)
    end

    it "computes group_by Date (year)" do
      query.group_by :tyear
      expect(query.result.size).to eq(2)
    end

    it "computes group_by User" do
      query.group_by :user_id
      expect(query.result.size).to eq(4)
    end

    it "computes group_by Author" do
      query.group_by :author_id
      expect(query.result.size).to eq(2)
    end

    it "computes group_by Type" do
      query.group_by :type_id
      expect(query.result.size).to eq(1)
    end

    it "computes group_by Budget" do
      query.group_by :budget_id
      expect(query.result.size).to eq(1)
    end

    it "computes multiple group_by" do
      query.group_by :project_id
      query.group_by :user_id
      sql_result = query.result

      expect(sql_result.size).to eq(4)
      # for each user the number of projects should be correct
      sql_sizes = []
      sql_result.each do |sub_result|
        # user should be the outmost group_by
        expect(sub_result.fields).to include(:user_id)
        sql_sizes.push sub_result.size
        sub_result.each { |sub_sub_result| expect(sub_sub_result.fields).to include(:project_id) }
      end
      expect(sql_sizes.sort).to eq([1, 1, 1, 1])
    end

    # TODO: ?
    it "computes multiple group_by with joins" do
      query.group_by :project_id
      query.group_by :type_id
      sql_result = query.result
      expect(sql_result.size).to eq(1)
      # for each type the number of projects should be correct
      sql_sizes = []
      sql_result.each do |sub_result|
        # type should be the outmost group_by
        expect(sub_result.fields).to include(:type_id)
        sql_sizes.push sub_result.size
        sub_result.each { |sub_sub_result| expect(sub_sub_result.fields).to include(:project_id) }
      end
      expect(sql_sizes.sort).to eq([2])
    end

    it "compute count correct with lots of group_by" do
      query.group_by :project_id
      query.group_by :work_package_id
      query.group_by :cost_type_id
      query.group_by :activity_id
      query.group_by :spent_on
      query.group_by :tweek
      query.group_by :type_id
      query.group_by :tmonth
      query.group_by :tyear

      expect(query.result.count).to eq(8)
    end

    it "accepts row as a specialised group_by" do
      query.row :project_id
      expect(query.chain.type).to eq(:row)
    end

    it "accepts column as a specialised group_by" do
      query.column :project_id
      expect(query.chain.type).to eq(:column)
    end

    it "has type :column as a default" do
      query.group_by :project_id
      expect(query.chain.type).to eq(:column)
    end

    it "aggregates a third group_by which owns at least 2 sub results" do
      query.group_by :tweek
      query.group_by :project_id
      query.group_by :user_id
      sql_result = query.result

      expect(sql_result.size).to eq(4)
      # for each user the number of projects should be correct
      sql_sizes = []
      sub_sql_sizes = []
      sql_result.each do |sub_result|
        # user should be the outmost group_by
        expect(sub_result.fields).to include(:user_id)
        sql_sizes.push sub_result.size

        sub_result.each do |sub_sub_result|
          expect(sub_sub_result.fields).to include(:project_id)
          sub_sql_sizes.push sub_sub_result.size

          sub_sub_result.each do |sub_sub_sub_result|
            expect(sub_sub_sub_result.fields).to include(:tweek)
          end
        end
      end
      expect(sql_sizes.sort).to eq([1, 1, 1, 1])
      expect(sub_sql_sizes.sort).to eq([1, 1, 1, 1])
    end

    describe CostQuery::GroupBy::CustomFieldEntries do
      let!(:project) { create(:project_with_types) }
      let!(:custom_field) do
        create(:work_package_custom_field)
      end

      let(:custom_field2) do
        build(:work_package_custom_field)
      end

      before do
        check_cache
        CostQuery::GroupBy.all.merge described_class.all
      end

      def check_cache
        CostQuery::Cache.reset!
        CostQuery::GroupBy::CustomFieldEntries.all
      end

      def delete_work_package_custom_field(custom_field)
        custom_field.destroy
        check_cache
      end

      include OpenProject::Reporting::SpecHelper::CustomFieldFilterHelper

      it "creates classes for custom fields" do
        # Would raise a name error
        expect { group_by_class_name_string(custom_field).constantize }.not_to raise_error
      end

      it "creates new classes for custom fields that get added after starting the server" do
        custom_field2.save!

        check_cache

        # Would raise a name error
        expect { group_by_class_name_string(custom_field2).constantize }.not_to raise_error

        custom_field2.destroy
      end

      it "removes the custom field classes after it is deleted" do
        custom_field2.save!

        check_cache

        custom_field2.destroy

        check_cache

        expect { group_by_class_name_string(custom_field2).constantize }.to raise_error NameError
      end

      it "includes custom fields classes in CustomFieldEntries.all" do
        expect(described_class.all)
          .to include(group_by_class_name_string(custom_field).constantize)
      end

      it "includes custom fields classes in GroupBy.all" do
        expect(CostQuery::GroupBy.all)
          .to include(group_by_class_name_string(custom_field).constantize)
      end

      it "is usable as filter" do
        custom_field2.save!

        check_cache

        query.group_by custom_field2.attribute_name
        footprint = query.result.each_direct_result.map { |c| [c.count, c.units.to_i] }.sort
        expect(footprint).to eq([[8, 8]])
      end
    end
  end
end
