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

RSpec.describe "Meeting agenda polling when logged out", :js do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) { create(:admin) }

  let(:password) { "adminADMIN!" }
  let(:meeting) { create(:meeting, project:, author: user) }
  let(:show_page) { Pages::Meetings::Show.new(meeting) }

  before do
    allow_any_instance_of(Meetings::HeaderComponent) # rubocop:disable RSpec/AnyInstance
      .to receive(:check_for_updates_interval)
            .and_return(0)

    # Log in via the real session cookie
    login_with(user.login, password)
  end

  it "replaces the page with the login screen instead of appending it to the agenda" do
    show_page.visit!
    expect(page).to have_css("#meetings-header-component")

    # Simulate logging out
    page.driver.clear_cookies

    show_page.trigger_change_poll

    expect(page).to have_current_path(signin_path, ignore_query: true, wait: 10)
    expect(page).to have_test_selector("user-login--form")
    expect(page).to have_no_css("#meetings-header-component")
  end
end
