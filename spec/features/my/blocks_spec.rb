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

describe 'Blocks on the my page', type: :feature, js: true do
  let(:project) { FactoryGirl.create :project }
  let(:open_status) { FactoryGirl.create :default_status }
  let(:closed_status) { FactoryGirl.create :closed_status }

  let!(:open_wp) { FactoryGirl.create(:work_package, project: project, status: open_status) }
  let!(:closed_wp) { FactoryGirl.create(:work_package, project: project, status: closed_status) }
  let!(:unwatched_wp) { FactoryGirl.create(:work_package, project: project, status: open_status) }

  let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }

  let(:layout) do
    { 'top' => ['issueswatched'], 'left' => [], 'right' => [] }
  end

  let(:user) do
    FactoryGirl.create(:user,
                       member_in_project: project,
                       member_through_role: role,
                       firstname: 'Mahboobeh').tap do |u|
      u.pref[:my_page_layout] = layout
      u.pref.save!
    end
  end

  before do
    Watcher.create(watchable: open_wp, user: user)
    Watcher.create(watchable: closed_wp, user: user)

    login_as user

    visit my_page_path
  end

  scenario 'viewing the blocks' do
    # displays only the open and watched work packages for the watched block
    expect(page)
      .to have_selector('#top .wp-table--cell-td.subject', text: open_wp.subject)
    expect(page)
      .to have_no_selector('#top .wp-table--cell-td.subject', text: closed_wp.subject)
    expect(page)
      .to have_no_selector('#top .wp-table--cell-td.subject', text: unwatched_wp.subject)
  end
end
