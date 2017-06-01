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

describe 'my/page', type: :view do
  let(:project)    { FactoryGirl.create :valid_project }
  let(:user)       { FactoryGirl.create :admin, member_in_project: project }
  let(:issue)      { FactoryGirl.create :work_package, project: project, author: user }
  let(:time_entry) {
    FactoryGirl.create :time_entry,
                       project: project,
                       user: user,
                       work_package: issue,
                       hours: 1
  }

  describe 'timelog block' do
    before do
      assign(:user, user)
      time_entry.spent_on = Date.today
      time_entry.save!
    end

    it 'renders the timelog block' do
      assign :blocks,  'top' => ['timelog'], 'left' => [], 'right' => []

      render

      expect(rendered).to have_selector("tr.time-entry td.subject a[href='#{work_package_path(issue)}']",
                                        text: "#{issue.type.name} ##{issue.id}")
    end
  end

  describe 'watched work packages block' do
    let!(:open_status) { FactoryGirl.create :default_status }
    let!(:closed_status) { FactoryGirl.create :closed_status }

    let!(:open_wp) { FactoryGirl.create(:work_package, project: project, status: open_status) }
    let!(:closed_wp) { FactoryGirl.create(:work_package, project: project, status: closed_status) }

    let!(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
    let!(:watching_user) do
      FactoryGirl.create(:user,
                         member_in_project: project,
                         member_through_role: role,
                         firstname: 'Mahboobeh')
        .tap do |user|
        Watcher.create(watchable: open_wp, user: user)
        Watcher.create(watchable: closed_wp, user: user)
      end
    end

    before do
      allow(User).to receive(:current).and_return(watching_user)
      assign(:user, watching_user)
      assign :blocks,  'top' => [], 'left' => ['issueswatched'], 'right' => []

      render
    end

    it 'should render only one wp' do
      expect(response).to have_selector('table.work_packages tbody tr', count: 1)
    end
  end
end
