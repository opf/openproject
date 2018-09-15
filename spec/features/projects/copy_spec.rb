#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe 'Projects copy',
         type: :feature,
         js: true do
  let!(:project) do
    project = FactoryBot.create(:project,
                                 parent: parent_project,
                                 types: active_types,
                                 custom_field_values: { project_custom_field.id => 'some text cf' })

    FactoryBot.create(:member,
                       project: project,
                       user: user,
                       roles: [role])

    project.work_package_custom_fields << wp_custom_field
    project.types.first.custom_fields << wp_custom_field

    project
  end
  let!(:parent_project) do
    project = FactoryBot.create(:project)

    FactoryBot.create(:member,
                       project: project,
                       user: user,
                       roles: [role])
    project
  end
  let!(:project_custom_field) do
    FactoryBot.create(:text_project_custom_field, is_required: true)
  end
  let!(:wp_custom_field) do
    FactoryBot.create(:text_wp_custom_field)
  end
  let!(:inactive_wp_custom_field) do
    FactoryBot.create(:text_wp_custom_field)
  end
  let(:active_types) do
    [FactoryBot.create(:type), FactoryBot.create(:type)]
  end
  let!(:inactive_type) do
    FactoryBot.create(:type)
  end
  let(:user) { FactoryBot.create(:user) }
  let(:role) do
    FactoryBot.create(:role,
                       permissions: permissions)
  end
  let(:permissions) { %i(copy_projects edit_project add_subprojects manage_types view_work_packages) }
  let(:wp_user) do
    user = FactoryBot.create(:user)

    FactoryBot.create(:member,
                       project: project,
                       user: user,
                       roles: [role])
    user
  end
  let(:category) do
    FactoryBot.create(:category, project: project)
  end
  let(:version) do
    FactoryBot.create(:version, project: project)
  end
  let!(:work_package) do
    FactoryBot.create(:work_package,
                       project: project,
                       type: project.types.first,
                       author: wp_user,
                       assigned_to: wp_user,
                       responsible: wp_user,
                       done_ratio: 20,
                       category: category,
                       fixed_version: version,
                       description: 'Some desciption',
                       custom_field_values: { wp_custom_field.id => 'Some wp cf text' })
  end

  before do
    login_as user

    allow(Delayed::Worker)
      .to receive(:delay_jobs)
            .and_return(false)
  end

  it 'copies projects and the associated objects' do
    original_settings_page = Pages::Projects::Settings.new(project)
    original_settings_page.visit!

    click_link 'Copy'
    fill_in 'Name', with: 'Copied project'

    # the value of the custom field should be preselected
    expect(page)
      .to have_field(project_custom_field.name, with: 'some text cf')

    click_button 'Copy'

    original_settings_page.expect_notification message: I18n.t('copy_project.started',
                                                               source_project_name: project.name,
                                                               target_project_name: 'Copied project'),
                                               type: 'notice'

    copied_project = Project.find_by(name: 'Copied project')

    expect(copied_project)
      .to be_present

    copied_settings_page = Pages::Projects::Settings.new(copied_project)
    copied_settings_page.visit!

    # has the parent of the original project
    expect(page)
      .to have_select('Subproject of',
                      selected: parent_project.name)

    # copies over the value of the custom field
    expect(page)
      .to have_field(project_custom_field.name, with: 'some text cf')

    # has wp custom fields of original project active
    copied_settings_page.visit_tab!('custom_fields')

    copied_settings_page.expect_wp_custom_field_active(wp_custom_field)
    copied_settings_page.expect_wp_custom_field_inactive(inactive_wp_custom_field)

    # has types of original project activ
    copied_settings_page.visit_tab!('types')

    active_types.each do |type|
      copied_settings_page.expect_type_active(type)
    end

    copied_settings_page.expect_type_inactive(inactive_type)

    # custom field is copied over where the author is the current user
    # Using the db directly due to performance and clarity
    copied_work_packages = copied_project.work_packages

    expect(copied_work_packages.length)
      .to eql 1

    copied_work_package = copied_work_packages[0]

    expect(copied_work_package.subject)
      .to eql work_package.subject
    expect(copied_work_package.author)
      .to eql user
    expect(copied_work_package.assigned_to)
      .to eql work_package.assigned_to
    expect(copied_work_package.responsible)
      .to eql work_package.responsible
    expect(copied_work_package.status)
      .to eql work_package.status
    expect(copied_work_package.done_ratio)
      .to eql work_package.done_ratio
    expect(copied_work_package.description)
      .to eql work_package.description
    expect(copied_work_package.category)
      .to eql copied_project.categories.find_by(name: category.name)
    expect(copied_work_package.fixed_version)
      .to eql copied_project.versions.find_by(name: version.name)
    expect(copied_work_package.custom_value_attributes)
      .to eql(wp_custom_field.id => 'Some wp cf text')
  end
end
