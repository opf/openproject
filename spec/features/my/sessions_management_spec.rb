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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "My account session management", :js do
  include Redmine::I18n
  let(:user) { create(:user) }

  let(:old_session_time) { 5.days.ago }
  let(:session_data) do
    { browser: "Mozilla Firefox", browser_version: "12.3", platform: "Linux", updated_at: old_session_time }
  end

  let!(:plain_session) { create(:user_session, user:, data: session_data) }
  let!(:user_session) { Sessions::UserSession.find_by(session_id: plain_session.session_id) }

  before do
    login_as(user)
    # Session is inserted with now() by default, and doesn't take the data attribute
    Sessions::UserSession.where(id: user_session.id).update_all(updated_at: 5.days.ago)
    visit my_account_path
  end

  it "can list and terminate sessions" do
    click_on "Session management"

    page.within_test_selector("Users::Sessions::TableComponent") do
      expect(page).to have_css(".generic-table tbody tr", count: 2)
      trs = page.all(".generic-table tbody tr")
      expect(trs[0]).to have_css(".icon-yes")
      expect(trs[0]).to have_text("Current session")
      expect(trs[0]).to have_text("unknown browser")
      expect(trs[0]).to have_text("unknown operating system")
      expect(trs[0]).to have_no_css(".buttons a")
      expect(trs[1]).to have_no_css(".spot-icon_yes")
      expect(trs[1]).to have_text("Mozilla Firefox (Version 12.3)")
      expect(trs[1]).to have_text("Linux")
      expect(trs[1]).to have_text format_time(old_session_time)
      expect(trs[1]).to have_css(".buttons a")

      trs[1].find(".buttons a").click
    end

    page.driver.browser.switch_to.alert.accept

    page.within_test_selector("Users::Sessions::TableComponent") do
      expect(page).to have_css(".generic-table tbody tr", count: 1)
    end

    expect { user_session.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
