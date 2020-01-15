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

require_relative '../support/pages/dashboard'

describe 'Work package calendar widget on dashboard',
         type: :feature,
         with_mail: false,
         js: true do
  let!(:type) { FactoryBot.create :type }
  let!(:priority) { FactoryBot.create :default_priority }
  let!(:project) { FactoryBot.create :project, types: [type] }
  let!(:other_project) { FactoryBot.create :project, types: [type] }
  let!(:open_status) { FactoryBot.create :default_status }
  let!(:spanning_work_package) do
    FactoryBot.create :work_package,
                      subject: 'Spanning work package',
                      project: project,
                      start_date: Date.today - 8.days,
                      due_date: Date.today + 8.days,
                      type: type,
                      author: user,
                      responsible: user
  end
  let!(:starting_work_package) do
    FactoryBot.create :work_package,
                      subject: 'Starting work package',
                      project: project,
                      start_date: Date.today,
                      due_date: Date.today + 8.days,
                      type: type,
                      author: user,
                      responsible: user
  end
  let!(:ending_work_package) do
    FactoryBot.create :work_package,
                      subject: 'Ending work package',
                      project: project,
                      start_date: Date.today - 8.days,
                      due_date: Date.today,
                      type: type,
                      author: user,
                      responsible: user
  end
  let!(:outdated_work_package) do
    FactoryBot.create :work_package,
                      subject: 'Outdated work package',
                      project: project,
                      start_date: Date.today - 9.days,
                      due_date: Date.today - 7.days,
                      type: type,
                      author: user,
                      responsible: user
  end
  let!(:other_project_work_package) do
    FactoryBot.create :work_package,
                      subject: 'Other project work package',
                      project: other_project,
                      start_date: Date.today - 9.days,
                      due_date: Date.today + 7.days,
                      type: type,
                      author: user,
                      responsible: user
  end

  let(:permissions) do
    %i[view_work_packages
       view_dashboards
       manage_dashboards]
  end

  let(:role) do
    FactoryBot.create(:role, permissions: permissions)
  end

  let(:user) do
    FactoryBot.create(:user).tap do |u|
      FactoryBot.create(:member, project: project, user: u, roles: [role])
      FactoryBot.create(:member, project: other_project, user: u, roles: [role])
    end
  end

  let(:dashboard) do
    Pages::Dashboard.new(project)
  end

  before do
    login_as user

    dashboard.visit!
  end

  it 'can add the widget and see the work packages of the project' do
    dashboard.add_widget(1, 1, :within, "Calendar")

    sleep(0.1)

    # As the user lacks the necessary permisisons, no widget is preconfigured
    calendar_widget = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)')

    within(calendar_widget.area) do
      expect(page)
        .to have_selector('.fc-event-container', text: spanning_work_package.subject)

      expect(page)
        .to have_selector('.fc-event-container', text: starting_work_package.subject)

      expect(page)
        .to have_selector('.fc-event-container', text: ending_work_package.subject)

      expect(page)
        .to have_no_selector('.fc-event-container', text: outdated_work_package.subject)

      expect(page)
        .to have_no_selector('.fc-event-container', text: other_project_work_package.subject)
    end
  end
end
