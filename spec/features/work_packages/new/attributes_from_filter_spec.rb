#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

RSpec.feature 'Work package create uses attributes from filters', js: true, selenium: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:type_bug) { FactoryBot.create(:type_bug) }
  let(:type_task) { FactoryBot.create(:type_task) }
  let(:project) { FactoryBot.create(:project, types: [type_task, type_bug]) }
  let(:status) { FactoryBot.create(:default_status) }

  let!(:status) { FactoryBot.create(:default_status) }
  let!(:priority) { FactoryBot.create :priority, is_default: true }

  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:split_view_create) { ::Pages::SplitWorkPackageCreate.new(project: project) }

  let(:role) { FactoryBot.create :existing_role, permissions: [:view_work_packages] }

  let!(:query) do
    FactoryBot.build(:query, project: project, user: user).tap do |query|
      query.filters.clear

      filters.each do |filter|
        query.add_filter(*filter)
      end

      query.column_names = ['id', 'subject', 'type', 'assigned_to']
      query.save!
    end
  end

  let(:filters) do
    [['type_id', '=', [type_task.id]]]
  end

  before do
    login_as(user)
    wp_table.visit_query query
    wp_table.expect_no_work_package_listed
  end

  context 'with a multi-value custom field' do
    let(:type_task) { FactoryBot.create(:type_task, custom_fields: [custom_field]) }
    let!(:project) do
      FactoryBot.create :project,
                        types: [type_task],
                        work_package_custom_fields: [custom_field]
    end

    let!(:custom_field) do
      FactoryBot.create(
        :list_wp_custom_field,
        multi_value: true,
        is_filter: true,
        name: "Gate",
        possible_values: %w(A B C),

        is_required: false
      )
    end

    let(:filters) do
      [['type_id', '=', [type_task.id]],
       ["cf_#{custom_field.id}", '=', [custom_field.custom_options.detect { |o| o.value == 'A' }.id]]]
    end

    it 'allows to save with a single value (Regression test #27833)' do
      split_page = wp_table.create_wp_by_button type_task

      subject = split_page.edit_field(:subject)
      subject.expect_active!
      subject.set_value 'Foobar!'
      split_page.save!

      wp_table.expect_and_dismiss_notification(
        message: 'Successful creation. Click here to open this work package in fullscreen view.'
      )
      wp = WorkPackage.last
      expect(wp.subject).to eq 'Foobar!'
      expect(wp.send("custom_field_#{custom_field.id}")).to eq %w(A)
      expect(wp.type_id).to eq type_task.id
    end
  end

  context 'with assignee filter' do
    let!(:assignee) do
      FactoryBot.create(:user,
                        firstname: 'An',
                        lastname: 'assignee',
                        member_in_project: project,
                        member_through_role: role)
    end

    let(:filters) do
      [['type_id', '=', [type_task.id]],
       ['assigned_to_id', '=', [assignee.id]]]
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
      assignee_field.expect_state_text type_task.name.upcase

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
      type_field.expect_state_text type_bug.name.upcase

      # Assignee is synced
      assignee_field = split_view_create.edit_field :assignee
      expect(assignee_field.input_element.find('.ng-value-label').text).to eql('An assignee')

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
