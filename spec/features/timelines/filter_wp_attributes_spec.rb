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

describe Timeline, 'filtering by wp attributes', type: :feature, js: true do
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
  let(:type2) do
    type = FactoryGirl.create(:type)

    project.types << type

    type
  end
  let(:wp1) do
    FactoryGirl.create(:work_package, project: project, type: type, responsible: user, author: user)
  end
  let(:wp2) do
    FactoryGirl.create(:work_package, project: project, type: type2, responsible: nil, author: user)
  end
  let(:timeline) do
    FactoryGirl.create(:timeline, project: project)
  end
  before do
    wp1
    wp2
    login_as(user)
  end

  include_context 'ui-select helpers'

  it 'allows filtering by type' do
    # no filter
    visit project_timeline_path(project_id: project, id: timeline)

    expect(page).to have_content wp1.subject
    expect(page).to have_content wp2.subject

    # filtering by type
    visit edit_project_timeline_path(project_id: project, id: timeline)

    page.find('#planning_element_filters legend a').click

    select = page.find('#s2id_timeline_options_planning_element_types')

    ui_select(select, type.name)

    click_button 'Save'

    expect(page).to have_content wp1.subject
    expect(page).to have_no_content wp2.subject

    # filtering by responsible
    # specific responsible name
    visit edit_project_timeline_path(project_id: project, id: timeline)

    page.find('#planning_element_filters legend a').click

    select = page.find("#s2id_timeline_options_planning_element_types")

    ui_select_clear(select)

    select = page.find("#s2id_timeline_options_planning_element_responsibles")

    ui_select(select, user.name)

    click_button 'Save'

    expect(page).to have_content wp1.subject
    expect(page).to have_no_content wp2.subject

    # filtering by responsible
    # specifically no responsible
    visit edit_project_timeline_path(project_id: project, id: timeline)

    page.find('#planning_element_filters legend a').click

    select = page.find("#s2id_timeline_options_planning_element_responsibles")

    ui_select_clear(select)
    ui_select(select, '(none)')

    click_button 'Save'

    expect(page).to have_no_content wp1.subject
    expect(page).to have_content wp2.subject
  end
end
