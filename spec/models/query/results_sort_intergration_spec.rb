# --copyright
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
# ++

require "spec_helper"

RSpec.describe Query::Results, "sorting and grouping" do
  create_shared_association_defaults_for_work_package_factory

  let(:query) do
    build_stubbed(:query,
                  show_hierarchies: false,
                  group_by:,
                  sort_criteria: sort_by,
                  project: project1,
                  column_names: columns)
  end

  let(:query_results) do
    described_class.new query
  end
  let(:project1) { create(:project) }
  let(:user1) do
    create(:user,
           firstname: "user",
           lastname: "1",
           member_with_permissions: { project1 => [:view_work_packages] })
  end
  let(:user_a) { create(:user, firstname: "AAA", lastname: "AAA") }
  let(:user_m) { create(:user, firstname: "mmm", lastname: "mmm") }
  let(:user_z) { create(:user, firstname: "ZZZ", lastname: "ZZZ") }

  let(:work_package1) { create(:work_package, project: project1, id: 1) }
  let(:work_package2) { create(:work_package, project: project1, id: 2) }
  let(:work_package3) { create(:work_package, project: project1, id: 3) }
  let(:sort_by) { [%w[id asc]] }
  let(:columns) { %i(id subject) }
  let(:group_by) { "" }

  current_user { user1 }

  context "when grouping by assigned_to, having the author column selected" do
    let(:group_by) { "assigned_to" }
    let(:columns) { %i(id subject author) }

    before do
      work_package1.assigned_to = user_m
      work_package1.author = user_m

      work_package1.save(validate: false)

      work_package2.assigned_to = user_z
      work_package2.author = user_a

      work_package2.save(validate: false)

      work_package3.assigned_to = user_m
      work_package3.author = user_a

      work_package3.save(validate: false)
    end

    it "sorts case insensitive first by assigned_to (group by), then by sort criteria" do
      # Would look like this in the table
      #
      # user_m
      #   work_package 1
      #   work_package 3
      # user_z
      #   work_package 2
      expect(query_results.work_packages)
        .to match [work_package1, work_package3, work_package2]
    end
  end

  context "when sorting by author, grouping by assigned_to" do
    let(:group_by) { "assigned_to" }
    let(:sort_by) { [["author", "asc"]] }

    before do
      work_package1.assigned_to = user_m
      work_package1.author = user_m

      work_package1.save(validate: false)

      work_package2.assigned_to = user_z
      work_package2.author = user_a

      work_package2.save(validate: false)

      work_package3.assigned_to = user_m
      work_package3.author = user_a

      work_package3.save(validate: false)
    end

    it "sorts case insensitive first by group by, then by assigned_to" do
      # Would look like this in the table
      #
      # user_m
      #   work_package 3
      #   work_package 1
      # user_z
      #   work_package 2
      expect(query_results.work_packages)
        .to match [work_package3, work_package1, work_package2]

      query.sort_criteria = [["author", "desc"]]

      # Would look like this in the table
      #
      # user_m
      #   work_package 1
      #   work_package 3
      # user_z
      #   work_package 2
      expect(query_results.work_packages)
        .to match [work_package1, work_package3, work_package2]
    end
  end

  context "when sorting and grouping by priority" do
    let(:prio_low) { create(:issue_priority, position: 1) }
    let(:prio_high) { create(:issue_priority, position: 0) }
    let(:group_by) { "priority" }

    before do
      work_package1.priority = prio_low
      work_package2.priority = prio_high

      work_package1.save(validate: false)
      work_package2.save(validate: false)
    end

    it "respects the sorting (Regression #29689)" do
      query.sort_criteria = [["priority", "asc"]]

      expect(query_results.work_packages)
        .to match [work_package1, work_package2]

      query.sort_criteria = [["priority", "desc"]]

      expect(query_results.work_packages)
        .to match [work_package2, work_package1]
    end
  end

  context "when sorting by priority, grouping by project" do
    let(:prio_low) { create(:issue_priority, position: 1) }
    let(:prio_high) { create(:issue_priority, position: 0) }
    let(:group_by) { "project" }

    before do
      work_package1.priority = prio_low
      work_package2.priority = prio_high

      work_package1.save(validate: false)
      work_package2.save(validate: false)
    end

    it "properly selects project_id (Regression #31667)" do
      query.sort_criteria = [["priority", "asc"]]

      expect(query_results.work_packages)
        .to match [work_package1, work_package2]

      query.sort_criteria = [["priority", "desc"]]

      expect(query_results.work_packages)
        .to match [work_package2, work_package1]

      group_count = query_results.work_package_count_by_group

      expect(group_count).to eq({ project1 => 2 })
    end
  end

  context "when sorting by author and responsible, grouping by assigned_to" do
    let(:group_by) { "assigned_to" }
    let(:sort_by) { [["author", "asc"], ["responsible", "desc"]] }

    before do
      work_package1.assigned_to = user_m
      work_package1.author = user_m
      work_package1.responsible = user_a

      work_package1.save(validate: false)

      work_package2.assigned_to = user_z
      work_package2.author = user_m
      work_package3.responsible = user_m

      work_package2.save(validate: false)

      work_package3.assigned_to = user_m
      work_package3.author = user_m
      work_package3.responsible = user_z

      work_package3.save(validate: false)
    end

    it "sorts case insensitive first by group by, then by assigned_to (neutral as equal), then by responsible" do
      # Would look like this in the table
      #
      # user_m
      #   work_package 3
      #   work_package 1
      # user_z
      #   work_package 2
      expect(query_results.work_packages)
        .to match [work_package3, work_package1, work_package2]

      query.sort_criteria = [%w[author desc], %w[responsible asc]]

      # Would look like this in the table
      #
      # user_m
      #   work_package 1
      #   work_package 3
      # user_z
      #   work_package 2
      expect(query_results.work_packages)
        .to match [work_package1, work_package3, work_package2]
    end
  end

  context "when sorting by project" do
    let(:user1) { create(:admin) }
    let(:query) do
      build_stubbed(:query,
                    show_hierarchies: false,
                    project: nil,
                    sort_criteria: sort_by)
    end

    let(:project1) { create(:project, name: "Project A") }
    let(:project2) { create(:project, name: "Project b")  }
    let(:project3) { create(:project, name: "Project C")  }
    let(:work_package1) { create(:work_package, project: project1) }
    let(:work_package2) { create(:work_package, project: project2) }
    let(:work_package3) { create(:work_package, project: project3) }

    before { [work_package1, work_package2, work_package3] }

    context "when ascending" do
      let(:sort_by) { [%w[project asc]] }

      it "sorts case insensitive" do
        expect(query_results.work_packages)
          .to match [work_package1, work_package2, work_package3]
      end
    end

    context "when descending" do
      let(:sort_by) { [%w[project desc]] }

      it "sorts case insensitive" do
        expect(query_results.work_packages)
          .to match [work_package3, work_package2, work_package1]
      end
    end
  end

  context "when sorting by category" do
    let(:query) do
      build_stubbed(:query,
                    show_hierarchies: false,
                    project: nil,
                    sort_criteria: sort_by)
    end
    let(:category1) { create(:category, project: project1, name: "Category A") }
    let(:category2) { create(:category, project: project1, name: "Category b") }
    let(:category3) { create(:category, project: project1, name: "Category C") }
    let(:work_package1) { create(:work_package, project: project1, category: category1) }
    let(:work_package2) { create(:work_package, project: project1, category: category2) }
    let(:work_package3) { create(:work_package, project: project1, category: category3) }

    before { [work_package1, work_package2, work_package3] }

    context "when ascending" do
      let(:sort_by) { [%w[category asc]] }

      it "sorts case insensitive" do
        query_results.work_packages
        [work_package1, work_package2, work_package3]

        expect(query_results.work_packages)
          .to match [work_package1, work_package2, work_package3]
      end
    end

    context "when descending" do
      let(:sort_by) { [%w[category desc]] }

      it "sorts case insensitive" do
        expect(query_results.work_packages)
          .to match [work_package3, work_package2, work_package1]
      end
    end
  end

  context "when sorting by subject" do
    let(:query) do
      build_stubbed(:query,
                    show_hierarchies: false,
                    project: nil,
                    sort_criteria: sort_by)
    end
    let(:work_package1) { create(:work_package, project: project1, subject: "WorkPackage A") }
    let(:work_package2) { create(:work_package, project: project1, subject: "WorkPackage b") }
    let(:work_package3) { create(:work_package, project: project1, subject: "WorkPackage C") }

    before { [work_package1, work_package2, work_package3] }

    context "when ascending" do
      let(:sort_by) { [%w[subject asc]] }

      it "sorts case insensitive" do
        query_results.work_packages
        [work_package1, work_package2, work_package3]

        expect(query_results.work_packages)
          .to match [work_package1, work_package2, work_package3]
      end
    end

    context "when descending" do
      let(:sort_by) { [%w[subject desc]] }

      it "sorts case insensitive" do
        expect(query_results.work_packages)
          .to match [work_package3, work_package2, work_package1]
      end
    end
  end

  context "when sorting by finish date" do
    let(:query) do
      build_stubbed(:query,
                    show_hierarchies: false,
                    project: nil,
                    sort_criteria: sort_by)
    end
    let(:work_package1) { create(:work_package, project: project1, due_date: 3.days.ago) }
    let(:work_package2) { create(:work_package, project: project1, due_date: 2.days.ago) }
    let(:work_package3) { create(:work_package, project: project1, due_date: 1.day.ago) }

    before { [work_package1, work_package2, work_package3] }

    context "when ascending" do
      let(:sort_by) { [%w[due_date asc]] }

      it "sorts case insensitive" do
        expect(query_results.work_packages)
          .to match [work_package1, work_package2, work_package3]
      end
    end

    context "when descending" do
      let(:sort_by) { [%w[due_date desc]] }

      it "sorts case insensitive" do
        expect(query_results.work_packages)
          .to match [work_package3, work_package2, work_package1]
      end
    end
  end

  context "when sorting by string custom field" do
    let(:query) do
      build_stubbed(:query,
                    show_hierarchies: false,
                    project: nil,
                    sort_criteria: sort_by)
    end

    let(:work_package1) { create(:work_package, project: project1) }
    let(:work_package2) { create(:work_package, project: project1) }
    let(:work_package3) { create(:work_package, project: project1) }
    let(:string_cf) { create(:string_wp_custom_field, is_filter: true) }
    let!(:custom_value) do
      create(:custom_value,
             custom_field: string_cf,
             customized: work_package1,
             value: "String A")
    end
    let!(:custom_value2) do
      create(:custom_value,
             custom_field: string_cf,
             customized: work_package2,
             value: "String b")
    end

    let!(:custom_value3) do
      create(:custom_value,
             custom_field: string_cf,
             customized: work_package3,
             value: "String C")
    end

    before do
      [work_package1, work_package2, work_package3]

      work_package1.project.work_package_custom_fields << string_cf
      work_package1.type.custom_fields << string_cf

      work_package1.reload
      project1.reload
    end

    context "when ascending" do
      let(:sort_by) { [[string_cf.column_name, "asc"]] }

      it "sorts case insensitive" do
        expect(query_results.work_packages)
          .to match [work_package1, work_package2, work_package3]
      end
    end

    context "when descending" do
      let(:sort_by) { [["assigned_to", "desc"]] }

      it "sorts case insensitive" do
        expect(query_results.work_packages)
          .to match [work_package3, work_package2, work_package1]
      end
    end
  end

  context "when sorting by integer custom field" do
    let(:query) do
      build_stubbed(:query,
                    show_hierarchies: false,
                    project: nil,
                    sort_criteria: sort_by)
    end

    let(:work_package1) { create(:work_package, project: project1) }
    let(:work_package2) { create(:work_package, project: project1) }
    let(:work_package3) { create(:work_package, project: project1) }
    let(:int_cf) { create(:integer_wp_custom_field, is_filter: true) }
    let!(:custom_value) do
      create(:custom_value,
             custom_field: int_cf,
             customized: work_package1,
             value: 1)
    end
    let!(:custom_value2) do
      create(:custom_value,
             custom_field: int_cf,
             customized: work_package2,
             value: 2)
    end

    let!(:custom_value3) do
      create(:custom_value,
             custom_field: int_cf,
             customized: work_package3,
             value: 3)
    end

    before do
      [work_package1, work_package2, work_package3]

      work_package1.project.work_package_custom_fields << int_cf
      work_package1.type.custom_fields << int_cf

      work_package1.reload
      project1.reload
    end

    context "when ascending" do
      let(:sort_by) { [[int_cf.column_name, "asc"]] }

      it "sorts case insensitive" do
        expect(query_results.work_packages)
          .to match [work_package1, work_package2, work_package3]
      end
    end

    context "when descending" do
      let(:sort_by) { [[int_cf.column_name, "desc"]] }

      it "sorts case insensitive" do
        expect(query_results.work_packages)
          .to match [work_package3, work_package2, work_package1]
      end
    end
  end

  context "when sorting by typeahead" do
    before do
      work_package1.update_column(:updated_at, 5.days.ago)
      work_package2.update_column(:updated_at, Time.current)
      work_package3.update_column(:updated_at, 10.days.ago)
    end

    let(:sort_by) { [%w[typeahead asc]] }

    current_user { user1 }

    it "sorts by updated_at desc" do
      expect(query_results.work_packages)
        .to match [work_package2, work_package1, work_package3]
    end
  end
end
