#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe 'history',
               :js,
               :with_cuprite do
  include Components::Autocompleter::NgSelectAutocompleteHelpers
  include Redmine::I18n

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create(:user,
           lastname: 'First',
           member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings delete_meetings manage_agendas
                                                    view_work_packages] })
  end
  shared_let(:view_only_user) do
    create(:user,
           lastname: 'Second',
           member_with_permissions: { project => %i[view_meetings view_work_packages] })
  end
  shared_let(:no_member_user) do
    create(:user,
           lastname: 'Third')
  end
  shared_let(:meeting) do
    create(:structured_meeting,
           project:,
           start_time: Time.current + 2.days,
           title: "Some title",
           author: user, # why does the corresponding journal list user as anonyous instead?
           duration: 1.5).tap do |m|
            create(:meeting_participant, :invitee, meeting: m, user: view_only_user)
          end
  end

  let(:datetime) { Time.current }

  let(:show_page) { Pages::StructuredMeeting::Show.new(meeting) }

  it 'for a user with view permissions', with_settings: { journal_aggregation_time_minutes: 0 } do
    login_as view_only_user
    show_page.visit!

    click_button('op-meetings-header-action-trigger')
    click_button 'History'

    within("li.op-activity-list--item", match: :first) do
      expect(page).to have_css('.op-activity-list--item-title', text: "Meeting", exact_text: true)
      # expect(page).to have_css('.op-activity-list--item-subtitle', text: "created by #{current_user.name} on #{format_time(datetime)}") # formatting issues?
    end

    login_as user
    meeting_data =
    {
      start_time: meeting.start_time + 1.day + 1.hour,
      duration: 1,
      title: "Updated",
      location: "Wakanda"
    }
    meeting.update!(meeting_data)

    page.refresh
    login_as view_only_user

    click_button('op-meetings-header-action-trigger')
    click_button 'History'

    binding.pry

    within("li.op-activity-list--item", match: :first) do
      expect(page).to have_css('.op-activity-list--item-title', text: "Meeting details")
      # expect(page).to have_css('.op-activity-list--item-subtitle', text: "updated by #{current_user.name} on #{format_time(datetime)}")
      expect(page).to have_css('li', text: 'Title changed from Some title to Updated')
      expect(page).to have_css('li', text: 'Location changed from https://some-url.com to Wakanda')
      expect(page).to have_css('li', text: 'Time changed from 13:30 to 14:30')
      expect(page).to have_css('li', text: 'Date changed from 28.03.2024 to 29.03.2024')
    end
  end

  it 'for a user with no permissions', with_settings: { journal_aggregation_time_minutes: 0 } do
    login_as no_member_user

    visit history_meeting_path(meeting)

    expected = '[Error 403] You are not authorized to access this page.'
    expect(page).to have_css('.op-toast.-error', text: expected)
  end
end
