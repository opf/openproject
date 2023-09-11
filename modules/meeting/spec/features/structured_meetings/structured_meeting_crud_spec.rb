#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

require_relative '../../support/pages/meetings/new'
require_relative '../../support/pages/structured_meeting/show'

RSpec.describe 'Structured meetings CRUD', :js, with_cuprite: true do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  let(:time_zone) { 'utc' }
  let(:user) do
    create(:user,
           lastname: 'First',
           member_in_project: project,
           member_with_permissions: permissions).tap do |u|
      u.pref[:time_zone] = time_zone

      u.save!
    end
  end
  let!(:other_user) do
    create(:user,
           lastname: 'Second',
           member_in_project: project,
           member_with_permissions: permissions)
  end
  let(:permissions) { %i[view_meetings create_meetings create_meeting_agendas] }
  let(:current_user) { user }
  let(:new_page) { Pages::Meetings::New.new(project) }
  let(:show_page) { Pages::StructuredMeeting::Show.new(StructuredMeeting.order(id: :asc).last) }

  before do
    login_as current_user
  end

  it 'can create a structured meeting and add agenda items' do
    new_page.visit!
    expect(page).to have_current_path(new_page.path)
    new_page.set_title 'Some title'
    new_page.set_type 'Structured'

    new_page.set_start_date '2013-03-28'
    new_page.set_start_time '13:30'
    new_page.set_duration '1.5'
    new_page.invite(other_user)

    new_page.click_create
    show_page.expect_toast(message: 'Successful creation')

    show_page.add_agenda_item do
      fill_in 'Title', with: 'My agenda item'
      fill_in 'Duration in minutes', with: '25'
      click_button 'Save'
    end

    show_page.expect_agenda_item title: 'My agenda item'
    item = MeetingAgendaItem.find_by(title: 'My agenda item')
    show_page.edit_agenda_item(item) do
      fill_in 'Title', with: 'Updated title'
      click_button 'Save'
    end

    show_page.expect_no_agenda_item title: 'My agenda item'
  end
end
