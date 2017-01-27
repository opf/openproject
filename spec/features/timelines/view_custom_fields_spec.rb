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

describe Timeline, 'view custom fields', type: :feature, js: true do
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:permissions) do
    [:view_work_packages,
     :view_timelines,
     :edit_timelines,
     :edit_work_packages]
  end
  let(:project) { FactoryGirl.create(:project, name: "Lil'ol'project") }
  let(:user) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let(:other_user) do
    FactoryGirl.create(:user,
                       firstname: 'Other',
                       lastname: 'User',
                       member_in_project: project,
                       member_through_role: role)
  end
  let(:type) { project.types.first }

  let(:bool_cf) do
    field = FactoryGirl.create(:bool_wp_custom_field,
                               name: 'A_bool',
                               is_filter: true,
                               is_for_all: true)

    type.custom_fields << field

    field
  end
  let(:list_cf) do
    field = FactoryGirl.create(:list_wp_custom_field,
                               name: 'A_list',
                               is_filter: true,
                               is_for_all: true,
                               possible_values: ['A_list_value',
                                                 'B_list_value',
                                                 'C_list_value'])

    type.custom_fields << field

    field
  end
  let(:bool_cf_local) do
    field = FactoryGirl.create(:bool_wp_custom_field,
                               name: 'A_local_bool',
                               is_filter: true,
                               is_for_all: false)

    type.custom_fields << field
    project.work_package_custom_fields << field

    field
  end
  let(:user_cf_local) do
    field = FactoryGirl.create(:user_wp_custom_field,
                               name: 'A_user',
                               is_filter: true,
                               is_for_all: false)

    type.custom_fields << field
    project.work_package_custom_fields << field

    field
  end
  let(:work_package1) do
    wp = FactoryGirl.build(:work_package,
                           subject: "Lil'ol'wp",
                           assigned_to: other_user,
                           type: type,
                           project: project)

    wp.custom_field_values = { bool_cf.id => true,
                               bool_cf_local.id => false,
                               user_cf_local.id => user,
                               list_cf.id => list_cf.possible_values.first.id }

    wp.save!

    wp
  end

  let(:timeline) do
    FactoryGirl.create(:timeline, project: project)
  end

  before do
    work_package1

    login_as(user)
  end

  include_context 'ui-select helpers'

  it 'displays custom values' do
    visit edit_project_timeline_path(project_id: project, id: timeline)

    select = page.find('#s2id_timeline_options_columns_')
    ui_select(select, list_cf.name)
    ui_select(select, 'Assignee')
    ui_select(select, bool_cf_local.name)

    click_button 'Save'

    within '#timeline' do
      expect(page).to have_content(work_package1.subject)

      expect(page).to have_selector('th:nth-of-type(2)',
                                    text: list_cf.name)
      expect(page).to have_selector('td:nth-of-type(2)',
                                    text: list_cf.possible_values.first.value)
      expect(page).to have_selector('th:nth-of-type(3)',
                                    text: 'Assignee')
      expect(page).to have_selector('td:nth-of-type(3)',
                                    text: work_package1.assigned_to.name)
      expect(page).to have_selector('th:nth-of-type(4)',
                                    text: bool_cf_local.name)
      expect(page).to have_selector('td:nth-of-type(4)',
                                    text: 'No')
      expect(page).to have_no_selector('td', text: 'Yes')
      expect(page).to have_no_selector('td', text: user.name)
    end

    visit edit_project_timeline_path(project_id: project, id: timeline)

    select = page.find('#s2id_timeline_options_columns_')
    ui_select_clear(select)
    ui_select(select, bool_cf.name)
    ui_select(select, user_cf_local.name)

    click_button 'Save'

    within '#timeline' do
      expect(page).to have_content(work_package1.subject)

      expect(page).to have_selector('th:nth-of-type(2)',
                                    text: bool_cf.name)
      expect(page).to have_selector('td:nth-of-type(2)',
                                    text: 'Yes')
      expect(page).to have_selector('th:nth-of-type(3)',
                                    text: user_cf_local.name)
      expect(page).to have_selector('td:nth-of-type(3)',
                                    text: user.name)
      expect(page).to have_no_selector('td', text: 'No')
      expect(page).to have_no_selector('td', text: list_cf.possible_values.first.value)
      expect(page).to have_no_selector('td', text: work_package1.assigned_to.name)
    end

    # if the custom value has been deactivated in the project
    # the value is no longer displayed

    project.work_package_custom_fields = []

    visit project_timeline_path(project_id: project, id: timeline)

    within '#timeline' do
      expect(page).to have_content(work_package1.subject)

      expect(page).to have_selector('th:nth-of-type(2)',
                                    text: bool_cf.name)
      expect(page).to have_selector('td:nth-of-type(2)',
                                    text: 'Yes')
      expect(page).to have_no_selector('td', text: user.name)
      expect(page).to have_no_selector('td', text: 'No')
      expect(page).to have_no_selector('td', text: list_cf.possible_values.first.value)
      expect(page).to have_no_selector('td', text: work_package1.assigned_to.name)
    end
  end
end
