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

describe Timeline, 'filtering custom fields', type: :feature, js: true do
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
    field = FactoryGirl.create(:bool_wp_custom_field, is_filter: true, is_for_all: true)

    type.custom_fields << field

    field
  }
  let(:bool_cf_local) {
    field = FactoryGirl.create(:bool_wp_custom_field, is_filter: true, is_for_all: false)

    type.custom_fields << field
    project.work_package_custom_fields << field

    field
  }
  let(:list_cf) {
    field = FactoryGirl.create(:list_wp_custom_field,
                               is_filter: true,
                               is_for_all: true,
                               possible_values: ['A', 'B', 'C'])

    type.custom_fields << field

    field
  }
  let(:list_cf_local) {
    field = FactoryGirl.create(:list_wp_custom_field,
                               is_filter: true,
                               is_for_all: false,
                               possible_values: ['A', 'B', 'C'])

    type.custom_fields << field
    project.work_package_custom_fields << field

    field
  }
  let(:wp1) do
    FactoryGirl.create(:work_package, project: project, type: type)
  end
  let(:wp2) do
    FactoryGirl.create(:work_package, project: project, type: type)
  end
  let(:wp3) do
    FactoryGirl.create(:work_package, project: project, type: type)
  end
  let(:wp4) do
    FactoryGirl.create(:work_package, project: project, type: type)
  end

  let(:timeline) do
    FactoryGirl.create(:timeline, project: project)
  end

  before do
    login_as(user)
  end

  include_context 'ui-select helpers'

  shared_examples_for 'filtering by bool custom field' do
    it 'filters accordingly' do
      wp1.custom_field_values = { cf.id => false }
      wp1.save!

      wp2.custom_field_values = { cf.id => true }
      wp2.save!
      wp3
      # wp3 has no such custom value

      visit edit_project_timeline_path(project_id: project, id: timeline)

      page.find('#planning_element_filters legend a').click

      select = page.find("#s2id_timeline_options_custom_fields_#{cf.id}")

      ui_select(select, 'Yes')

      click_button 'Save'

      expect(page).to have_content wp2.subject
      expect(page).to have_no_content wp1.subject
      expect(page).to have_no_content wp3.subject

      visit edit_project_timeline_path(project_id: project, id: timeline)

      page.find('#planning_element_filters legend a').click

      select = page.find("#s2id_timeline_options_custom_fields_#{cf.id}")

      ui_select(select, 'No')

      click_button 'Save'

      expect(page).to have_content wp1.subject
      expect(page).to have_no_content wp2.subject
      expect(page).to have_no_content wp3.subject

      visit edit_project_timeline_path(project_id: project, id: timeline)

      page.find('#planning_element_filters legend a').click

      select = page.find("#s2id_timeline_options_custom_fields_#{cf.id}")

      ui_select(select, '(none)')

      click_button 'Save'

      expect(page).to have_content wp3.subject
      expect(page).to have_no_content wp1.subject
      expect(page).to have_no_content wp2.subject
    end
  end

  context 'with a global bool custom field' do
    let(:cf) { bool_cf }
    it_behaves_like 'filtering by bool custom field'
  end

  context 'with a global bool custom field' do
    let(:cf) { bool_cf_local }
    it_behaves_like 'filtering by bool custom field'
  end

  shared_examples_for 'filtering by list custom field' do
    it 'filters accordingly' do
      def value_for(string)
        cf.custom_options.find { |co| co.value == string }.id
      end

      FactoryGirl.create(:custom_value, customized: wp1, custom_field: cf, value: value_for('A'))
      FactoryGirl.create(:custom_value, customized: wp2, custom_field: cf, value: value_for('B'))
      FactoryGirl.create(:custom_value, customized: wp3, custom_field: cf, value: value_for('C'))
      wp4
      # wp4 has no custom value

      visit edit_project_timeline_path(project_id: project, id: timeline)

      page.find('#planning_element_filters legend a').click

      select = page.find("#s2id_timeline_options_custom_fields_#{cf.id}_")

      ui_select(select, 'B')

      click_button 'Save'

      expect(page).to have_content wp2.subject
      expect(page).to have_no_content wp1.subject
      expect(page).to have_no_content wp3.subject
      expect(page).to have_no_content wp4.subject

      visit edit_project_timeline_path(project_id: project, id: timeline)

      page.find('#planning_element_filters legend a').click

      select = page.find("#s2id_timeline_options_custom_fields_#{cf.id}_")

      ui_select_clear(select)
      ui_select(select, 'A')
      ui_select(select, 'C')

      click_button 'Save'

      expect(page).to have_content wp1.subject
      expect(page).to have_content wp3.subject
      expect(page).to have_no_content wp2.subject
      expect(page).to have_no_content wp4.subject

      visit edit_project_timeline_path(project_id: project, id: timeline)

      page.find('#planning_element_filters legend a').click

      select = page.find("#s2id_timeline_options_custom_fields_#{cf.id}_")

      ui_select_clear(select)
      ui_select(select, '(none)')
      ui_select(select, 'A')
      ui_select(select, 'B')
      ui_select(select, 'C')

      click_button 'Save'

      expect(page).to have_content wp1.subject
      expect(page).to have_content wp2.subject
      expect(page).to have_content wp3.subject
      expect(page).to have_content wp4.subject

      visit edit_project_timeline_path(project_id: project, id: timeline)

      page.find('#planning_element_filters legend a').click

      select = page.find("#s2id_timeline_options_custom_fields_#{cf.id}_")

      ui_select_clear(select)
      ui_select(select, '(none)')

      click_button 'Save'

      expect(page).to have_content wp4.subject
      expect(page).to have_no_content wp1.subject
      expect(page).to have_no_content wp2.subject
      expect(page).to have_no_content wp3.subject
    end
  end

  context 'with a global list custom field' do
    let(:cf) { list_cf }
    it_behaves_like 'filtering by list custom field'
  end

  context 'with a global list custom field' do
    let(:cf) { list_cf_local }
    it_behaves_like 'filtering by list custom field'
  end
end
