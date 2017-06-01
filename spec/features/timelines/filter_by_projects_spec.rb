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

describe Timeline, 'fitler by projects', type: :feature, js: true do
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:permissions) do
    [:view_work_packages,
     :view_timelines,
     :view_reportings,
     :edit_timelines,
     :edit_work_packages]
  end
  let(:project) { FactoryGirl.create(:project) }
  let(:project1) { FactoryGirl.create(:project) }
  let(:project2) { FactoryGirl.create(:project) }
  let(:project3) { FactoryGirl.create(:project) }
  let(:project4) { FactoryGirl.create(:project) }
  let(:user) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let(:type) { project.types.first }
  let(:type2) do
    type = FactoryGirl.create(:type)

    project.types << type
    project1.types << type
    project2.types << type
    project3.types << type
    project4.types << type

    type
  end
  let(:wp1) do
    FactoryGirl.create(:work_package,
                       project: project1,
                       type: type2,
                       author: user,
                       start_date: '2012-03-15',
                       due_date: '2012-03-20')
  end
  let(:wp2) do
    FactoryGirl.create(:work_package,
                       project: project2,
                       type: project2.types.first,
                       author: user,
                       start_date: '2012-03-15',
                       due_date: '2012-03-20')
  end
  let(:wp3) do
    FactoryGirl.create(:work_package,
                       project: project3,
                       type: type2,
                       author: user,
                       start_date: '2012-03-21',
                       due_date: '2012-03-22')
  end
  let(:wp4) do
    FactoryGirl.create(:work_package,
                       project: project4,
                       type: type2,
                       author: user,
                       start_date: '2012-03-11',
                       due_date: '2012-03-14')
  end

  let(:timeline) do
    FactoryGirl.create(:timeline, project: project)
  end
  let(:project1_to_project_reporting) do
    FactoryGirl.create(:reporting,
                       project: project1,
                       reporting_to_project: project)
  end
  let(:project2_to_project_reporting) do
    FactoryGirl.create(:reporting,
                       project: project2,
                       reporting_to_project: project)
  end
  let(:project3_to_project_reporting) do
    FactoryGirl.create(:reporting,
                       project: project3,
                       reporting_to_project: project)
  end
  let(:project4_to_project_reporting) do
    FactoryGirl.create(:reporting,
                       project: project4,
                       reporting_to_project: project)
  end
  let(:member_in_project1) do
    FactoryGirl.create(:member, project: project1,
                                roles: [role],
                                user: user)
  end
  let(:member_in_project2) do
    FactoryGirl.create(:member, project: project2,
                                roles: [role],
                                user: user)
  end
  let(:member_in_project3) do
    FactoryGirl.create(:member, project: project3,
                                roles: [role],
                                user: user)
  end
  let(:member_in_project4) do
    FactoryGirl.create(:member, project: project4,
                                roles: [role],
                                user: user)
  end

  before do
    wp1
    wp2
    wp3
    wp4

    project1_to_project_reporting
    project2_to_project_reporting
    project3_to_project_reporting
    project4_to_project_reporting
    member_in_project1
    member_in_project2
    member_in_project3
    member_in_project4

    login_as(user)
  end

  include_context 'ui-select helpers'

  it "allows filtering for project's work packages by time and type" do
    visit edit_project_timeline_path(project_id: project, id: timeline)

    page.find('#project_filters legend a').click

    select = page.find('#s2id_timeline_options_planning_element_time_types')
    ui_select(select, type2.name)

    choose('Absolute')

    fill_in('timeline_options_planning_element_time_absolute_one', with: '2012-03-15')
    fill_in('timeline_options_planning_element_time_absolute_two', with: '2012-03-20')

    click_button 'Save'

    within '#content' do
      expect(page).to have_content wp1.subject
      expect(page).to have_content project1.name
      expect(page).to have_no_content wp2.subject
      expect(page).to have_no_content wp3.subject
      expect(page).to have_no_content wp4.subject
      expect(page).to have_no_content project2.name
      expect(page).to have_no_content project3.name
      expect(page).to have_no_content project4.name
    end
  end
end
