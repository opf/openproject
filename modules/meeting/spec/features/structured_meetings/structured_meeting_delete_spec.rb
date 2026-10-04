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

require_relative "../../support/pages/meetings/show"
require_relative "../../support/pages/meetings/index"

RSpec.describe "Meetings deletion",
               :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings work_package_tracking]) }
  shared_let(:user) do
    create(:user,
           lastname: "First",
           member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings delete_meetings] }).tap do |u|
      u.pref[:time_zone] = "Etc/UTC"

      u.save!
    end
  end

  shared_let(:meeting) do
    create(:meeting,
           :author_participates,
           project:,
           author: user)
  end

  let(:current_user) { user }
  let(:meetings_page) { Pages::Meetings::Index.new(project: nil) }

  before do
    login_as current_user
    meetings_page.visit!
  end

  it "can delete globally, redirecting back to global" do
    expect(page).to have_current_path(meetings_page.path)
    expect(page).to have_text meeting.title

    within_row(meeting.title) do
      click_on "more-button"
      click_on "Delete meeting"
    end

    within("#delete-meeting-dialog") do
      expect(page).to have_text "Delete this meeting?"
      click_on "Delete"
    end

    expect(page).to have_current_path(meetings_page.path)
  end
end
