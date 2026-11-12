# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

require_relative "../../support/pages/meetings/mobile/show"

RSpec.describe "Meetings CRUD",
               :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings work_package_tracking]) }
  shared_let(:user) do
    create(:user,
           lastname: "First",
           member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings delete_meetings manage_agendas
                                                    view_work_packages] }).tap do |u|
      u.pref[:time_zone] = "Etc/UTC"

      u.save!
    end
  end
  shared_let(:other_user) do
    create(:user,
           lastname: "Second",
           member_with_permissions: { project => %i[view_meetings view_work_packages] })
  end
  shared_let(:no_member_user) do
    create(:user,
           lastname: "Third")
  end

  shared_let(:meeting) do
    create(:meeting,
           :author_participates,
           project:,
           state: :in_progress,
           author: user)
  end

  let(:current_user) { user }
  let(:show_page) { Pages::Meetings::Mobile::Show.new(Meeting.last) }

  include_context "with mobile screen size"

  before do
    login_as current_user
    show_page.visit!
  end

  it "can edit participants of a meeting" do
    expect(page).to have_current_path(show_page.path)
    show_page.expect_participants(count: 1)

    show_page.open_participant_form
    show_page.in_participant_form do
      show_page.expect_participant(user)

      show_page.toggle_attendance(user)
      show_page.expect_participant(user, attended: true)
      show_page.expect_available_participants(count: 1)

      show_page.select_participant(other_user)
      show_page.expect_participant(other_user)
      show_page.expect_available_participants(count: 2)
    end

    # other_user cannot manage participants
    login_as other_user
    show_page.visit!

    show_page.expect_no_participants_form

    # when meeting is closed, cannot manage participants
    login_as user
    show_page.visit!
    show_page.close_meeting_from_in_progress

    show_page.expect_no_participants_form

    # when meeting is open, can add/remove participants but not mark as attended
    show_page.reopen_meeting

    show_page.open_participant_form
    show_page.in_participant_form do
      show_page.expect_participant(user, editable: false)
      show_page.expect_participant(other_user, editable: false)

      show_page.remove_participant(other_user)
      show_page.expect_available_participants(count: 1)
    end
  end
end
