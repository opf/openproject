#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

RSpec.feature 'Work package create uses attributes from filters', js: true, selenium: true do
  let(:user) { FactoryGirl.create(:admin) }
  let(:type_bug) { FactoryGirl.create(:type_bug) }
  let(:type_task) { FactoryGirl.create(:type_task) }
  let(:project) { FactoryGirl.create(:project, types: [type_task, type_bug]) }
  let(:status) { FactoryGirl.create(:default_status) }

  let!(:status) { FactoryGirl.create(:default_status) }
  let!(:priority) { FactoryGirl.create :priority, is_default: true }


  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:split_view_create) { ::Pages::SplitWorkPackageCreate.new(project: project) }
  let(:filters) { ::Components::WorkPackages::Filters.new }

  let(:role) { FactoryGirl.create :existing_role, permissions: [:view_work_packages] }


  let!(:query) do
    FactoryGirl.build(:query, project: project, user: user).tap do |query|
      query.filters.clear
      query.column_names = ['id', 'subject', 'type', 'assigned_to']
      query.save!
    end
  end


  before do
    login_as(user)
    wp_table.visit_query query
    wp_table.expect_no_work_package_listed

    filters.expect_filter_count 0
    filters.open
    filters.add_filter_by('Type', 'is', type_task.name)
  end

  context 'with a multi-value custom field' do
    let(:type_task) { FactoryGirl.create(:type_task, custom_fields: [custom_field]) }
    let!(:project) {
      FactoryGirl.create :project,
                         types: [type_task],
                         work_package_custom_fields: [custom_field]
    }

    let!(:custom_field) do
      FactoryGirl.create(
        :list_wp_custom_field,
        multi_value: true,
        is_filter: true,
        name: "Gate",
        possible_values: %w(A B C),

        is_required: false
      )
    end

    before do
      filters.add_filter_by('Gate', 'is', 'A', "customField#{custom_field.id}")
    end

    it 'allows to save with a single value (Regression test #27833)' do
      split_page = wp_table.create_wp_split_screen type_task.name

      subject = split_page.edit_field(:subject)
      subject.expect_active!
      subject.set_value 'Foobar!'
      subject.submit_by_enter

      wp_table.expect_notification(
        message: 'Successful creation. Click here to open this work package in fullscreen view.'
      )
      wp_table.dismiss_notification!
      wp = WorkPackage.last
      expect(wp.subject).to eq 'Foobar!'
      expect(wp.send("custom_field_#{custom_field.id}")).to eq %w(A)
      expect(wp.type_id).to eq type_task.id
    end
  end

  context 'with assignee filter' do
    let!(:assignee) do
      FactoryGirl.create(:user,
                         firstname: 'An',
                         lastname: 'assignee',
                         member_in_project: project,
                         member_through_role: role)
    end


    before do
      filters.add_filter_by('Assignee', 'is', assignee.name)
    end

    it 'uses the assignee filter in inline-create and split view' do
      wp_table.click_inline_create

      subject_field = wp_table.edit_field(nil, :subject)
      subject_field.expect_active!

      # Expect assignee to be set to the current user
      assignee_field = wp_table.edit_field(nil, :assignee)
      assignee_field.expect_state_text assignee.name

      # Expect type set to task
      assignee_field = wp_table.edit_field(nil, :type)
      assignee_field.expect_state_text type_task.name

      # Save the WP
      subject_field.set_value 'Foobar!'
      subject_field.submit_by_enter

      wp_table.expect_notification(
        message: 'Successful creation. Click here to open this work package in fullscreen view.'
      )
      wp_table.dismiss_notification!

      wp = WorkPackage.last
      expect(wp.subject).to eq 'Foobar!'
      expect(wp.assigned_to_id).to eq assignee.id
      expect(wp.type_id).to eq type_task.id

      # Open split view create
      split_view_create.click_create_wp_button(type_bug)

      # Subject
      subject_field = split_view_create.edit_field :subject
      subject_field.expect_active!
      subject_field.set_value 'Split Foobar!'

      # Type field IS NOT synced
      type_field = split_view_create.edit_field :type
      type_field.expect_state_text type_bug

      # Assignee is synced
      assignee_field = split_view_create.edit_field :assignee
      assignee_field.expect_value "/api/v3/users/#{assignee.id}"

      within '.work-packages--edit-actions' do
        click_button 'Save'
      end

      wp_table.expect_notification(message: 'Successful creation.')

      wp = WorkPackage.last
      expect(wp.subject).to eq 'Split Foobar!'
      expect(wp.assigned_to_id).to eq assignee.id
      expect(wp.type_id).to eq type_bug.id
    end
  end
end
