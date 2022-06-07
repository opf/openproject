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

describe ::Query::Results, type: :model, with_mail: false do
  let(:query) do
    build :query,
          show_hierarchies: false
  end
  let(:query_results) do
    described_class.new query
  end
  let(:project1) { create :project }
  let(:role_pm) do
    create(:role,
           permissions: %i(
             view_work_packages
             edit_work_packages
             create_work_packages
             delete_work_packages
           ))
  end
  let(:role_dev) do
    create(:role,
           permissions: [:view_work_packages])
  end
  let(:user1) do
    create(:user,
           firstname: 'user',
           lastname: '1',
           member_in_project: project1,
           member_through_role: [role_dev, role_pm])
  end
  let(:wp_p1) do
    (1..3).map do
      create(:work_package,
             project: project1,
             assigned_to_id: user1.id)
    end
  end

  describe '#work_package_count_by_group' do
    let(:query) do
      build :query,
            show_hierarchies: false,
            group_by:,
            project: project1
    end
    let(:type1) do
      create(:type)
    end
    let(:type2) do
      create(:type)
    end
    let(:work_package1) do
      create(:work_package,
             type: type1,
             project: project1)
    end
    let(:work_package2) do
      create(:work_package,
             type: type2,
             project: project1)
    end

    context 'when grouping by responsible' do
      let(:group_by) { 'responsible' }

      it 'produces a valid SQL statement' do
        expect { query_results.work_package_count_by_group }.not_to raise_error
      end
    end

    context 'when grouping and filtering by text' do
      let(:group_by) { 'responsible' }

      before do
        query.add_filter('search', '**', ['asdf'])
      end

      it 'produces a valid SQL statement (Regression #29598)' do
        expect { query_results.work_package_count_by_group }.not_to raise_error
      end
    end

    context 'when grouping by assigned_to' do
      let(:group_by) { 'assigned_to' }

      before do
        work_package1
        work_package2.update_column(:assigned_to_id, user1.id)

        login_as(user1)
      end

      it 'returns a hash of counts by value' do
        expect(query_results.work_package_count_by_group).to eql(nil => 1, user1 => 1)
      end
    end

    context 'when grouping by assigned_to with only a nil group' do
      let(:group_by) { 'assigned_to' }

      before do
        work_package1

        login_as(user1)
      end

      it 'returns a hash of counts by value' do
        expect(query_results.work_package_count_by_group).to eql(nil => 1)
      end
    end

    context 'when grouping by type' do
      let(:group_by) { 'type' }

      before do
        work_package1
        work_package2

        login_as(user1)
      end

      it 'returns the groups sorted by type`s position' do
        type1.update_column(:position, 1)
        type2.update_column(:position, 2)

        result = query_results.work_package_count_by_group

        expect(result.length)
          .to be 2

        expect(result.keys.map(&:id))
          .to eql [type1.id, type2.id]

        type1.update_column(:position, 2)
        type2.update_column(:position, 1)

        new_results = described_class.new(query)

        result = new_results.work_package_count_by_group

        expect(result.length)
          .to be 2

        expect(result.keys.map(&:id))
          .to eql [type2.id, type1.id]
      end
    end

    context 'when grouping by list custom field and filtering for it at the same time' do
      let!(:custom_field) do
        create(:list_wp_custom_field,
               is_for_all: true,
               is_filter: true,
               multi_value: true).tap do |cf|
          work_package1.type.custom_fields << cf
          work_package2.type.custom_fields << cf
        end
      end
      let(:first_value) do
        custom_field.custom_options.first
      end
      let(:last_value) do
        custom_field.custom_options.last
      end
      let(:group_by) { "cf_#{custom_field.id}" }

      before do
        login_as(user1)

        work_package1.send(:"custom_field_#{custom_field.id}=", first_value)
        work_package1.save!
        work_package2.send(:"custom_field_#{custom_field.id}=", [first_value,
                                                                 last_value])
        work_package2.save!
      end

      it 'yields no error but rather returns the result' do
        expect { query_results.work_package_count_by_group }.not_to raise_error

        group_count = query_results.work_package_count_by_group
        expected_groups = [[first_value], [first_value, last_value]]

        group_count.each do |key, count|
          expect(count).to be 1
          expect(expected_groups).to(be_any { |group| group & key == key & group })
        end
      end
    end

    context 'when grouping by int custom field' do
      let!(:custom_field) do
        create(:int_wp_custom_field, is_for_all: true, is_filter: true)
      end

      let(:group_by) { "cf_#{custom_field.id}" }

      before do
        login_as(user1)

        wp_p1[0].type.custom_fields << custom_field
        project1.work_package_custom_fields << custom_field

        wp_p1[0].update_attribute(:"custom_field_#{custom_field.id}", 42)
        wp_p1[0].save
        wp_p1[1].update_attribute(:"custom_field_#{custom_field.id}", 42)
        wp_p1[1].save
      end

      it 'returns a hash of counts by value' do
        expect(query_results.work_package_count_by_group).to eql(42 => 2, nil => 1)
      end
    end

    context 'when grouping by user custom field' do
      let!(:custom_field) do
        create(:user_wp_custom_field, is_for_all: true, is_filter: true)
      end

      let(:group_by) { "cf_#{custom_field.id}" }

      before do
        login_as(user1)

        wp_p1[0].type.custom_fields << custom_field
        project1.work_package_custom_fields << custom_field
      end

      it 'returns nil as user custom fields are not groupable' do
        expect(query_results.work_package_count_by_group).to be_nil
      end
    end

    context 'when grouping by bool custom field' do
      let!(:custom_field) do
        create(:bool_wp_custom_field, is_for_all: true, is_filter: true)
      end

      let(:group_by) { "cf_#{custom_field.id}" }

      before do
        login_as(user1)

        wp_p1[0].type.custom_fields << custom_field
        project1.work_package_custom_fields << custom_field

        wp_p1[0].update_attribute(:"custom_field_#{custom_field.id}", true)
        wp_p1[0].save
        wp_p1[1].update_attribute(:"custom_field_#{custom_field.id}", true)
        wp_p1[1].save
      end

      it 'returns a hash of counts by value' do
        expect(query_results.work_package_count_by_group).to eql(true => 2, nil => 1)
      end
    end

    context 'when grouping by date custom field' do
      let!(:custom_field) do
        create(:date_wp_custom_field, is_for_all: true, is_filter: true)
      end

      let(:group_by) { "cf_#{custom_field.id}" }

      before do
        login_as(user1)

        wp_p1[0].type.custom_fields << custom_field
        project1.work_package_custom_fields << custom_field

        wp_p1[0].update_attribute(:"custom_field_#{custom_field.id}", Time.zone.today)
        wp_p1[0].save
        wp_p1[1].update_attribute(:"custom_field_#{custom_field.id}", Time.zone.today)
        wp_p1[1].save
      end

      it 'returns a hash of counts by value' do
        expect(query_results.work_package_count_by_group).to eql(Time.zone.today => 2, nil => 1)
      end
    end
  end

  describe 'filtering' do
    let!(:project1) { create :project }
    let!(:project2) { create :project }
    let!(:member) do
      create(:member,
             project: project2,
             principal: user1,
             roles: [role_pm])
    end
    let!(:user2) do
      create(:user,
             firstname: 'user',
             lastname: '2',
             member_in_project: project2,
             member_through_role: role_dev)
    end

    let!(:wp_p2) do
      create(:work_package,
             project: project2,
             assigned_to_id: user2.id)
    end
    let!(:wp2_p2) do
      create(:work_package,
             project: project2,
             assigned_to_id: user1.id)
    end

    before do
      wp_p1
    end

    context 'when filtering for assigned_to_role' do
      before do
        allow(User).to receive(:current).and_return(user2)
        allow(project2.descendants).to receive(:active).and_return([])

        query.add_filter('assigned_to_role', '=', [role_dev.id.to_s])
      end

      context 'when a project is set' do
        let(:query) { build :query, project: project2 }

        it 'displays only wp for selected project and selected role' do
          expect(query_results.work_packages).to match_array([wp_p2])
        end
      end

      context 'when no project is set' do
        let(:query) { build :query, project: nil }

        it 'displays all wp from projects where User.current has access' do
          expect(query_results.work_packages).to match_array([wp_p2, wp2_p2])
        end
      end
    end

    # this tests some unfortunate combination of filters where wrong
    # sql statements where produced.
    context 'with a custom field being returned and paginating' do
      let(:group_by) { nil }
      let(:query) do
        build_stubbed :query,
                      show_hierarchies: false,
                      group_by:,
                      project: project2
      end

      let!(:custom_field) { create(:work_package_custom_field, is_for_all: true) }

      before do
        allow(User).to receive(:current).and_return(user2)

        # reload in order to have the custom field as an available
        # custom field
        query.project = Project.find(query.project.id)
      end

      context 'when grouping by assignees' do
        before do
          query.column_names = [:assigned_to, :"cf_#{custom_field.id}"]
          query.group_by = 'assigned_to'
        end

        it 'returns all work packages of project 2' do
          work_packages = query
                          .results
                          .work_packages
                          .page(1)
                          .per_page(10)

          expect(work_packages).to match_array([wp_p2, wp2_p2])
        end
      end

      context 'when grouping by responsibles' do
        let(:group_by) { 'responsible' }

        before do
          query.column_names = [:responsible, :"cf_#{custom_field.id}"]
        end

        it 'returns all work packages of project 2' do
          work_packages = query
                          .results
                          .work_packages
                          .page(1)
                          .per_page(10)

          expect(work_packages).to match_array([wp_p2, wp2_p2])
        end
      end
    end

    context 'when grouping by responsible' do
      let(:query) do
        build :query,
              show_hierarchies: false,
              group_by:,
              project: project1
      end
      let(:group_by) { 'responsible' }

      before do
        allow(User).to receive(:current).and_return(user1)

        wp_p1[0].update_attribute(:responsible, user1)
        wp_p1[1].update_attribute(:responsible, user2)
      end

      it 'outputs the work package count in the schema { <User> => count }' do
        expect(query_results.work_package_count_by_group)
          .to eql(user1 => 1, user2 => 1, nil => 1)
      end
    end

    context 'when filtering by precedes and ordering by id' do
      let(:query) do
        build :query,
              project: project1
      end

      before do
        login_as(user1)

        create(:follows_relation, to: wp_p1[1], from: wp_p1[0])

        query.add_filter('precedes', '=', [wp_p1[0].id.to_s])

        query.sort_criteria = [['id', 'asc']]
      end

      it 'returns the work packages preceding the filtered for work package' do
        expect(query.results.work_packages)
          .to match_array(wp_p1[1])
      end
    end
  end

  describe 'sorting' do
    let(:work_package1) { create(:work_package, project: project1, id: 1) }
    let(:work_package2) { create(:work_package, project: project1, id: 2) }
    let(:work_package3) { create(:work_package, project: project1, id: 3) }
    let(:sort_by) { [['id', 'asc']] }
    let(:columns) { %i(id subject) }
    let(:group_by) { '' }

    let(:query) do
      build_stubbed :query,
                    show_hierarchies: false,
                    group_by:,
                    sort_criteria: sort_by,
                    project: project1,
                    column_names: columns
    end

    let(:query_results) do
      described_class.new query
    end

    let(:user_a) { create(:user, firstname: 'AAA', lastname: 'AAA') }
    let(:user_m) { create(:user, firstname: 'mmm', lastname: 'mmm') }
    let(:user_z) { create(:user, firstname: 'ZZZ', lastname: 'ZZZ') }

    context 'when grouping by assigned_to, having the author column selected' do
      let(:group_by) { 'assigned_to' }
      let(:columns) { %i(id subject author) }

      before do
        allow(User).to receive(:current).and_return(user1)

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

      it 'sorts case insensitive first by assigned_to (group by), then by sort criteria' do
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

    context 'when sorting by author, grouping by assigned_to' do
      let(:group_by) { 'assigned_to' }
      let(:sort_by) { [['author', 'asc']] }

      before do
        allow(User).to receive(:current).and_return(user1)

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

      it 'sorts case insensitive first by group by, then by assigned_to' do
        # Would look like this in the table
        #
        # user_m
        #   work_package 3
        #   work_package 1
        # user_z
        #   work_package 2
        expect(query_results.work_packages)
          .to match [work_package3, work_package1, work_package2]

        query.sort_criteria = [['author', 'desc']]

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

    context 'when sorting and grouping by priority' do
      let(:prio_low) { create :issue_priority, position: 1 }
      let(:prio_high) { create :issue_priority, position: 0 }
      let(:group_by) { 'priority' }

      before do
        allow(User).to receive(:current).and_return(user1)

        work_package1.priority = prio_low
        work_package2.priority = prio_high

        work_package1.save(validate: false)
        work_package2.save(validate: false)
      end

      it 'respects the sorting (Regression #29689)' do
        query.sort_criteria = [['priority', 'asc']]

        expect(query_results.work_packages)
          .to match [work_package1, work_package2]

        query.sort_criteria = [['priority', 'desc']]

        expect(query_results.work_packages)
          .to match [work_package2, work_package1]
      end
    end

    context 'when sorting by priority, grouping by project' do
      let(:prio_low) { create :issue_priority, position: 1 }
      let(:prio_high) { create :issue_priority, position: 0 }
      let(:group_by) { 'project' }

      before do
        allow(User).to receive(:current).and_return(user1)

        work_package1.priority = prio_low
        work_package2.priority = prio_high

        work_package1.save(validate: false)
        work_package2.save(validate: false)
      end

      it 'properly selects project_id (Regression #31667)' do
        query.sort_criteria = [['priority', 'asc']]

        expect(query_results.work_packages)
          .to match [work_package1, work_package2]

        query.sort_criteria = [['priority', 'desc']]

        expect(query_results.work_packages)
          .to match [work_package2, work_package1]

        group_count = query_results.work_package_count_by_group

        expect(group_count).to eq({ project1 => 2 })
      end
    end

    context 'when sorting by author and responsible, grouping by assigned_to' do
      let(:group_by) { 'assigned_to' }
      let(:sort_by) { [['author', 'asc'], ['responsible', 'desc']] }

      before do
        allow(User).to receive(:current).and_return(user1)

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

      it 'sorts case insensitive first by group by, then by assigned_to (neutral as equal), then by responsible' do
        # Would look like this in the table
        #
        # user_m
        #   work_package 3
        #   work_package 1
        # user_z
        #   work_package 2
        expect(query_results.work_packages)
          .to match [work_package3, work_package1, work_package2]

        query.sort_criteria = [['author', 'desc'], ['responsible', 'asc']]

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

    context 'when sorting by project' do
      let(:user1) { create(:admin) }
      let(:query) do
        build_stubbed :query,
                      show_hierarchies: false,
                      project: nil,
                      sort_criteria: sort_by
      end

      let(:project1) { create :project, name: 'Project A' }
      let(:project2) { create :project, name: 'Project b'  }
      let(:project3) { create :project, name: 'Project C'  }
      let(:work_package1) { create(:work_package, project: project1) }
      let(:work_package2) { create(:work_package, project: project2) }
      let(:work_package3) { create(:work_package, project: project3) }

      before { login_as(user1) }

      context 'when ascending' do
        let(:sort_by) { [['project', 'asc']] }

        it 'sorts case insensitive' do
          expect(query_results.work_packages)
            .to match [work_package1, work_package2, work_package3]
        end
      end

      context 'when descending' do
        let(:sort_by) { [['project', 'desc']] }

        it 'sorts case insensitive' do
          expect(query_results.work_packages)
            .to match [work_package3, work_package2, work_package1]
        end
      end
    end

    context 'when sorting by category' do
      let(:user1) { create(:admin) }
      let(:query) do
        build_stubbed :query,
                      show_hierarchies: false,
                      project: nil,
                      sort_criteria: sort_by
      end
      let(:category1) { create(:category, project: project1, name: 'Category A') }
      let(:category2) { create(:category, project: project1, name: 'Category b') }
      let(:category3) { create(:category, project: project1, name: 'Category C') }
      let(:work_package1) { create(:work_package, project: project1, category: category1) }
      let(:work_package2) { create(:work_package, project: project1, category: category2) }
      let(:work_package3) { create(:work_package, project: project1, category: category3) }

      before { login_as(user1) }

      context 'when ascending' do
        let(:sort_by) { [['category', 'asc']] }

        it 'sorts case insensitive' do
          query_results.work_packages
          [work_package1, work_package2, work_package3]

          expect(query_results.work_packages)
            .to match [work_package1, work_package2, work_package3]
        end
      end

      context 'when descending' do
        let(:sort_by) { [['category', 'desc']] }

        it 'sorts case insensitive' do
          expect(query_results.work_packages)
            .to match [work_package3, work_package2, work_package1]
        end
      end
    end

    context 'when sorting by subject' do
      let(:user1) { create(:admin) }
      let(:query) do
        build_stubbed :query,
                      show_hierarchies: false,
                      project: nil,
                      sort_criteria: sort_by
      end
      let(:work_package1) { create(:work_package, project: project1, subject: 'WorkPackage A') }
      let(:work_package2) { create(:work_package, project: project1, subject: 'WorkPackage b') }
      let(:work_package3) { create(:work_package, project: project1, subject: 'WorkPackage C') }

      before { login_as(user1) }

      context 'when ascending' do
        let(:sort_by) { [['subject', 'asc']] }

        it 'sorts case insensitive' do
          query_results.work_packages
          [work_package1, work_package2, work_package3]

          expect(query_results.work_packages)
            .to match [work_package1, work_package2, work_package3]
        end
      end

      context 'when descending' do
        let(:sort_by) { [['subject', 'desc']] }

        it 'sorts case insensitive' do
          expect(query_results.work_packages)
            .to match [work_package3, work_package2, work_package1]
        end
      end
    end

    context 'when sorting by finish date' do
      let(:user1) { create(:admin) }
      let(:query) do
        build_stubbed :query,
                      show_hierarchies: false,
                      project: nil,
                      sort_criteria: sort_by
      end
      let(:work_package1) { create(:work_package, project: project1, due_date: 3.days.ago) }
      let(:work_package2) { create(:work_package, project: project1, due_date: 2.days.ago) }
      let(:work_package3) { create(:work_package, project: project1, due_date: 1.day.ago) }

      before { login_as(user1) }

      context 'when ascending' do
        let(:sort_by) { [['due_date', 'asc']] }

        it 'sorts case insensitive' do
          expect(query_results.work_packages)
            .to match [work_package1, work_package2, work_package3]
        end
      end

      context 'when descending' do
        let(:sort_by) { [['due_date', 'desc']] }

        it 'sorts case insensitive' do
          expect(query_results.work_packages)
            .to match [work_package3, work_package2, work_package1]
        end
      end
    end

    context 'when sorting by string custom field' do
      let(:user1) { create(:admin) }
      let(:query) do
        build_stubbed :query,
                      show_hierarchies: false,
                      project: nil,
                      sort_criteria: sort_by
      end

      let(:work_package1) { create(:work_package, project: project1) }
      let(:work_package2) { create(:work_package, project: project1) }
      let(:work_package3) { create(:work_package, project: project1) }
      let(:string_cf) { create(:string_wp_custom_field, is_filter: true) }
      let!(:custom_value) do
        create(:custom_value,
               custom_field: string_cf,
               customized: work_package1,
               value: 'String A')
      end
      let!(:custom_value2) do
        create(:custom_value,
               custom_field: string_cf,
               customized: work_package2,
               value: 'String b')
      end

      let!(:custom_value3) do
        create(:custom_value,
               custom_field: string_cf,
               customized: work_package3,
               value: 'String C')
      end

      before do
        work_package1.project.work_package_custom_fields << string_cf
        work_package1.type.custom_fields << string_cf

        work_package1.reload
        project1.reload
        login_as(user1)
      end

      context 'when ascending' do
        let(:sort_by) { [["cf_#{string_cf.id}", 'asc']] }

        it 'sorts case insensitive' do
          expect(query_results.work_packages)
            .to match [work_package1, work_package2, work_package3]
        end
      end

      context 'when descending' do
        let(:sort_by) { [["assigned_to", 'desc']] }

        it 'sorts case insensitive' do
          expect(query_results.work_packages)
            .to match [work_package3, work_package2, work_package1]
        end
      end
    end

    context 'when sorting by integer custom field' do
      let(:user1) { create(:admin) }
      let(:query) do
        build_stubbed :query,
                      show_hierarchies: false,
                      project: nil,
                      sort_criteria: sort_by
      end

      let(:work_package1) { create(:work_package, project: project1) }
      let(:work_package2) { create(:work_package, project: project1) }
      let(:work_package3) { create(:work_package, project: project1) }
      let(:int_cf) { create(:int_wp_custom_field, is_filter: true) }
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
        work_package1.project.work_package_custom_fields << int_cf
        work_package1.type.custom_fields << int_cf

        work_package1.reload
        project1.reload
        login_as(user1)
      end

      context 'when ascending' do
        let(:sort_by) { [["cf_#{int_cf.id}", 'asc']] }

        it 'sorts case insensitive' do
          expect(query_results.work_packages)
            .to match [work_package1, work_package2, work_package3]
        end
      end

      context 'when descending' do
        let(:sort_by) { [["cf_#{int_cf.id}", 'desc']] }

        it 'sorts case insensitive' do
          expect(query_results.work_packages)
            .to match [work_package3, work_package2, work_package1]
        end
      end
    end

    context 'when filtering by bool cf' do
      let(:bool_cf) { create(:bool_wp_custom_field, is_filter: true) }
      let(:custom_value) do
        create(:custom_value,
               custom_field: bool_cf,
               customized: work_package1,
               value:)
      end
      let(:value) { 't' }
      let(:filter_value) { 't' }
      let(:activate_cf) do
        work_package1.project.work_package_custom_fields << bool_cf
        work_package1.type.custom_fields << bool_cf

        work_package1.reload
        project1.reload
      end

      before do
        allow(User).to receive(:current).and_return(user1)

        custom_value

        activate_cf

        query.add_filter(:"cf_#{bool_cf.id}", '=', [filter_value])
      end

      shared_examples_for 'is empty' do
        it 'is empty' do
          expect(query.results.work_packages)
            .to be_empty
        end
      end

      shared_examples_for 'returns the wp' do
        it 'returns the wp' do
          expect(query.results.work_packages)
            .to match_array(work_package1)
        end
      end

      context 'with the wp having true for the cf
               and filtering for true' do
        it_behaves_like 'returns the wp'
      end

      context 'with the wp having true for the cf
               and filtering for false' do
        let(:filter_value) { 'f' }

        it_behaves_like 'is empty'
      end

      context 'with the wp having false for the cf
               and filtering for false' do
        let(:value) { 'f' }
        let(:filter_value) { 'f' }

        it_behaves_like 'returns the wp'
      end

      context 'with the wp having false for the cf
               and filtering for true' do
        let(:value) { 'f' }

        it_behaves_like 'is empty'
      end

      context 'with the wp having no value for the cf
               and filtering for true' do
        let(:custom_value) { nil }

        it_behaves_like 'is empty'
      end

      context 'with the wp having no value for the cf
               and filtering for false' do
        let(:custom_value) { nil }
        let(:filter_value) { 'f' }

        it_behaves_like 'returns the wp'
      end

      context 'with the wp having no value for the cf
               and filtering for false
               and the cf not being active for the type' do
        let(:custom_value) { nil }
        let(:filter_value) { 'f' }

        let(:activate_cf) do
          work_package1.type.custom_fields << bool_cf

          work_package1.reload
          project1.reload
        end

        it_behaves_like 'is empty'
      end

      context 'with the wp having no value for the cf
               and filtering for false
               and the cf not being active in the project
               and the cf being for all' do
        let(:custom_value) { nil }
        let(:filter_value) { 'f' }
        let(:bool_cf) do
          create(:bool_wp_custom_field,
                 is_filter: true,
                 is_for_all: true)
        end

        let(:activate_cf) do
          work_package1.project.work_package_custom_fields << bool_cf

          work_package1.reload
          project1.reload
        end

        it_behaves_like 'is empty'
      end
    end
  end
end
