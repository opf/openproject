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

describe 'My notifications spec', type: :feature, js: true do
  let!(:project) { FactoryBot.create :project, name: 'My Foo Project' }
  let!(:role) { FactoryBot.create(:role, permissions: [:view_work_packages]) }

  let(:user) do
    FactoryBot.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  end

  before do
    login_as user
    visit my_account_path

    click_on 'Email notifications'
  end

  it 'allows to select a project to receive notifications for (Regression #28519)' do
    select 'For any event on the selected projects only', from: 'Send email notifications'
    expect(page).to have_selector('.form--label-with-check-box', text: 'My Foo Project')

    # Check the project
    find("#notified_project_ids_#{project.id}", wait: 5).set true

    click_on 'Save'
    expect(page).to have_selector('.flash.notice')

    user.reload
    expect(user.mail_notification).to eq(User::USER_MAIL_OPTION_SELECTED.first)
    expect(user.notified_projects_ids).to eq [project.id]


    select 'No events', from: 'Send email notifications'
    click_on 'Save'
    expect(page).to have_selector('.flash.notice')

    user.reload
    expect(user.mail_notification).to eq(User::USER_MAIL_OPTION_NON.first)
    expect(user.notified_projects_ids).to eq []
  end
end
