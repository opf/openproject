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

describe Timeline, 'reporting and grouping', type: :feature, js: true do
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:permissions) do
    [:view_work_packages,
     :view_timelines,
     :edit_timelines,
     :view_reportings,
     :edit_work_packages]
  end
  let(:project) { FactoryGirl.create(:project) }
  let(:empty_project) { FactoryGirl.create(:project, parent: empty_project_parent) }
  let(:empty_project_parent) { FactoryGirl.create(:project) }
  let(:project_with_responsible) do
    FactoryGirl.create(:project, responsible: user, parent: project_with_responsible_parent)
  end
  let(:project_with_responsible_parent) { FactoryGirl.create(:project) }
  let(:project_without_permissions) { FactoryGirl.create(:project) }
  let(:project_without_reportings) { FactoryGirl.create(:project) }
  let(:user) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let(:type) { project.types.first }
  let(:wp1) do
    FactoryGirl.create(:work_package,
                       project: project,
                       type: type,
                       responsible: user,
                       author: user)
  end
  let(:wp_in_project_with_responsible) do
    FactoryGirl.create(:work_package,
                       author: user,
                       project: project_with_responsible,
                       type: project_with_responsible.types.first)
  end

  let(:timeline) do
    FactoryGirl.create(:timeline, project: project)
  end
  let(:empty_project_to_project_reporting) do
    FactoryGirl.create(:reporting,
                       project: empty_project,
                       reporting_to_project: project)
  end
  let(:empty_project_parent_to_project_reporting) do
    FactoryGirl.create(:reporting,
                       project: empty_project_parent,
                       reporting_to_project: project)
  end
  let(:project_with_responsible_to_project_reporting) do
    FactoryGirl.create(:reporting,
                       project: project_with_responsible,
                       reporting_to_project: project)
  end
  let(:project_with_responsible_parent_to_project_reporting) do
    FactoryGirl.create(:reporting,
                       project: project_with_responsible_parent,
                       reporting_to_project: project)
  end
  let(:project_without_permissions_to_project_reporting) do
    FactoryGirl.create(:reporting,
                       project: project_without_permissions,
                       reporting_to_project: project)
  end
  let(:member_in_empty_project) do
    FactoryGirl.create(:member, project: empty_project,
                                roles: [role],
                                user: user)
  end
  let(:member_in_project_with_responsible) do
    FactoryGirl.create(:member, project: project_with_responsible,
                                roles: [role],
                                user: user)
  end
  let(:member_in_project_without_reportings) do
    FactoryGirl.create(:member, project: project_without_reportings,
                                roles: [role],
                                user: user)
  end
  let(:member_in_project_with_responsible_parent) do
    FactoryGirl.create(:member, project: project_with_responsible_parent,
                                roles: [role],
                                user: user)
  end
  let(:member_in_empty_project_parent) do
    FactoryGirl.create(:member, project: empty_project_parent,
                                roles: [role],
                                user: user)
  end

  before do
    wp1

    empty_project_to_project_reporting
    empty_project_parent_to_project_reporting
    project_with_responsible_to_project_reporting
    project_with_responsible_parent_to_project_reporting
    project_without_permissions_to_project_reporting
    project_without_permissions
    wp_in_project_with_responsible

    member_in_empty_project
    member_in_project_with_responsible
    member_in_project_without_reportings
    member_in_project_with_responsible_parent
    member_in_empty_project_parent

    login_as(user)
  end

  include_context 'ui-select helpers'

  it 'allows reporting and grouping' do
    visit project_timeline_path(project_id: project, id: timeline)

    within '#content' do
      expect(page).to have_content project.name
      expect(page).to have_content empty_project.name
      expect(page).to have_content project_with_responsible.name
      expect(page).to have_no_content project_without_permissions.name
      expect(page).to have_no_content project_without_reportings.name
    end

    # Filter out empty projects
    visit edit_project_timeline_path(project_id: project, id: timeline)

    page.find('#project_filters legend a').click

    page.check('Hide empty projects')

    click_button 'Save'

    expect(page).to have_content project.name
    expect(page).to have_no_content empty_project.name

    # Filter for projects with responsible
    visit edit_project_timeline_path(project_id: project, id: timeline)

    page.uncheck('Hide empty projects')

    select = page.find('#s2id_timeline_options_project_responsibles')

    ui_select(select, user.name)

    click_button 'Save'

    within '#content' do
      expect(page).to have_content project_with_responsible.name
      expect(page).to have_content project.name
      expect(page).to have_no_content empty_project.name
    end

    # First level grouping sorted by explicit order

    visit edit_project_timeline_path(project_id: project, id: timeline)

    page.find('#project_filters legend a').click

    select = page.find('#s2id_timeline_options_project_responsibles')

    ui_select_clear(select)

    page.find('#grouping legend a').click

    page.check('First grouping criterion')

    select = page.find('#s2id_timeline_options_grouping_one_sort')

    ui_select(select, 'explicit order')

    select = page.find('#s2id_timeline_options_grouping_one_selection')

    ui_select(select, empty_project_parent.name)
    ui_select(select, project_with_responsible_parent.name)

    click_button 'Save'

    within '#content' do
      expect(page).to have_content empty_project.name
      expect(page).to have_content project_with_responsible.name

      expect(page.body.index(empty_project.name) <
             page.body.index(project_with_responsible.name)).to be_truthy

      expect(page).to have_no_content project.name
    end

    # First level grouping sorted by explicit reverse order

    visit edit_project_timeline_path(project_id: project, id: timeline)

    page.find('#project_filters legend a').click

    select = page.find('#s2id_timeline_options_grouping_one_selection')

    ui_select_clear(select)
    ui_select(select, project_with_responsible_parent.name)
    ui_select(select, empty_project_parent.name)

    click_button 'Save'

    within '#content' do
      expect(page).to have_content project_with_responsible.name
      expect(page).to have_content empty_project.name

      expect(page.body.index(empty_project.name) >
             page.body.index(project_with_responsible.name)).to be_truthy

      expect(page).to have_no_content project.name
    end
  end
end
