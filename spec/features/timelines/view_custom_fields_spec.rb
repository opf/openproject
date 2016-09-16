#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
  let(:project) { FactoryGirl.create(:project) }
  let(:user) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let(:type) { project.types.first }

  let(:bool_cf) {
    field = FactoryGirl.create(:bool_wp_custom_field,
                               name: 'A_bool',
                               is_filter: true,
                               is_for_all: true)

    type.custom_fields << field

    field
  }
  let(:list_cf) {
    field = FactoryGirl.create(:list_wp_custom_field,
                               name: 'A_list',
                               is_filter: true,
                               is_for_all: true,
                               possible_values: ['A_list_value',
                                                 'B_list_value',
                                                 'C_list_value'])

    type.custom_fields << field

    field
  }
  let(:bool_cf_local) {
    field = FactoryGirl.create(:bool_wp_custom_field,
                               name: 'A_local_bool',
                               is_filter: true,
                               is_for_all: false)

    type.custom_fields << field
    project.work_package_custom_fields << field

    field
  }
  let(:user_cf) {
    field = FactoryGirl.create(:user_wp_custom_field,
                               name: 'A_user',
                               is_filter: true,
                               is_for_all: true)

    type.custom_fields << field

    field
  }
  let(:work_package1) {
    wp = FactoryGirl.create(:work_package,
                            type: type,
                            project: project)
    FactoryGirl.create(:custom_value,
                       custom_field: bool_cf,
                       customized: wp,
                       value: 't')
    FactoryGirl.create(:custom_value,
                       custom_field: bool_cf_local,
                       customized: wp,
                       value: 'f')
    FactoryGirl.create(:custom_value,
                       custom_field: user_cf,
                       customized: wp,
                       value: user.id)
    FactoryGirl.create(:custom_value,
                       custom_field: list_cf,
                       customized: wp,
                       value: list_cf.possible_values.first)

    wp
  }

  let(:timeline) do
    FactoryGirl.create(:timeline, project: project)
  end

  before do
    bool_cf
    list_cf
    bool_cf_local
    user_cf

    work_package1

    login_as(user)
  end

  include_context 'ui-select helpers'

  it 'displays custom values' do
    visit edit_project_timeline_path(project_id: project, id: timeline)

    select = page.find('#s2id_timeline_options_columns_')
    ui_select(select, bool_cf.name)
    ui_select(select, list_cf.name)

    click_button 'Save'

    within '#content' do
      expect(page).to have_content(work_package1.subject)

      expect(page).to have_selector('.tl-column', text: 'Yes')
      expect(page).to have_selector('.tl-column', text: list_cf.possible_values.first)
      expect(page).to have_no_selector('.tl-column', text: 'No')
      expect(page).to have_no_selector('.tl-column', text: user.name)

      expect(page.body.index(bool_cf.name) <
             page.body.index(list_cf.name)).to be_truthy
      expect(page.body.index('Yes') <
             page.body.index(list_cf.possible_values.first)).to be_truthy
    end

    visit edit_project_timeline_path(project_id: project, id: timeline)

    select = page.find('#s2id_timeline_options_columns_')
    ui_select_clear(select)
    ui_select(select, bool_cf_local.name)
    ui_select(select, user_cf.name)

    click_button 'Save'

    within '#content' do
      expect(page).to have_content(work_package1.subject)

      expect(page).to have_selector('.tl-column', text: 'No')
      expect(page).to have_selector('.tl-column', text: user.name)
      expect(page).to have_no_selector('.tl-column', text: 'Yes')
      expect(page).to have_no_selector('.tl-column', text: list_cf.possible_values.first)

      expect(page.body.index(bool_cf_local.name) <
             page.body.index(user_cf.name)).to be_truthy
      expect(page.body.index('No') <
             page.body.index(user.name)).to be_truthy
    end

    # if the custom value has been deactivated in the project
    # the value is no longer displayed

    project.work_package_custom_fields = []

    visit project_timeline_path(project_id: project, id: timeline)

    within '#content' do
      expect(page).to have_content(work_package1.subject)

      expect(page).to have_selector('.tl-column', text: user.name)
      expect(page).to have_no_selector('.tl-column', text: 'No')
      expect(page).to have_no_selector('.tl-column', text: 'Yes')
      expect(page).to have_no_selector('.tl-column', text: list_cf.possible_values.first)
    end
  end
end
