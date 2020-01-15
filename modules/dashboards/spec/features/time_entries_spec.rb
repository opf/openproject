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

describe 'Time entries widget on dashboard', type: :feature, js: true, with_mail: false do
  let!(:type) { FactoryBot.create :type }
  let!(:project) { FactoryBot.create :project, types: [type] }
  let!(:other_project) { FactoryBot.create :project, types: [type] }
  let!(:work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type,
                      author: user
  end
  let!(:visible_time_entry) do
    FactoryBot.create :time_entry,
                      work_package: work_package,
                      project: project,
                      user: user,
                      spent_on: Date.today,
                      hours: 6,
                      comments: 'My comment'
  end
  let!(:other_visible_time_entry) do
    FactoryBot.create :time_entry,
                      work_package: work_package,
                      project: project,
                      user: other_user,
                      spent_on: Date.today - 1.day,
                      hours: 5,
                      comments: 'Another`s comment'
  end
  let!(:invisible_time_entry) do
    FactoryBot.create :time_entry,
                      work_package: work_package,
                      project: other_project,
                      user: user,
                      hours: 4
  end
  let(:role) do
    FactoryBot.create(:role,
                      permissions: %i[view_time_entries
                                      view_dashboards
                                      manage_dashboards])
  end
  let(:other_user) do
    FactoryBot.create(:user)
  end
  let(:user) do
    FactoryBot.create(:user).tap do |u|
      FactoryBot.create(:member, project: project, roles: [role], user: u)
      FactoryBot.create(:member, project: other_project, roles: [role], user: u)
    end
  end

  let(:dashboard) do
    Pages::Dashboard.new(project)
  end

  before do
    login_as user

    dashboard.visit!
  end

  it 'adds the widget and checks the displayed entries' do
    # within top-right area, add an additional widget
    dashboard.add_widget(1, 1, :within, 'Spent time \(last 7 days\)')

    spent_time_widget = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)')

    within spent_time_widget.area do
      expect(page)
        .to have_content "Total: 11.00"

      expect(page)
        .to have_content Date.today.strftime('%m/%d/%Y')
      expect(page)
        .to have_selector('.activity', text: visible_time_entry.activity.name)
      expect(page)
        .to have_selector('.subject', text: "#{project.name} - ##{work_package.id}: #{work_package.subject}")
      expect(page)
        .to have_selector('.comments', text: visible_time_entry.comments)
      expect(page)
        .to have_selector('.hours', text: visible_time_entry.hours)

      expect(page)
        .to have_content((Date.today - 1.day).strftime('%m/%d/%Y'))
      expect(page)
        .to have_selector('.activity', text: other_visible_time_entry.activity.name)
      expect(page)
        .to have_selector('.subject', text: "#{project.name} - ##{work_package.id}: #{work_package.subject}")
      expect(page)
        .to have_selector('.comments', text: other_visible_time_entry.comments)
      expect(page)
        .to have_selector('.hours', text: other_visible_time_entry.hours)
    end
  end
end
