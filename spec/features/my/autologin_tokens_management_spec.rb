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

RSpec.describe "My account autologin tokens management", :js, :with_cuprite do
  include Redmine::I18n
  shared_let(:user) { create(:user) }
  shared_let(:old_token) { create(:autologin_token, user:, created_at: 1.year.ago) }
  shared_let(:new_token) do
    create(:autologin_token,
           user:,
           data: { browser: "Mozilla Firefox", browser_version: "12.3", platform: "Linux" })
  end

  before do
    login_as user
    visit my_sessions_path
  end

  context "with autologin disabled", with_settings: { autologin: 0 } do
    it "does not show tokens" do
      expect(page).to have_no_text "Remembered devices"
      expect(page).not_to have_test_selector("Users::AutoLoginTokens::TableComponent")
    end
  end

  context "with autologin enabled", with_settings: { autologin: 1 } do
    it "can list and terminate sessions" do
      page.within_test_selector("Users::AutoLoginTokens::TableComponent") do
        expect(page).to have_css(".generic-table tbody tr", count: 2)
        trs = page.all(".generic-table tbody tr")
        expect(trs[0]).to have_text("unknown browser")
        expect(trs[0]).to have_text("unknown operating system")
        expect(trs[0]).to have_css(".buttons a")
        expect(trs[0]).to have_no_css(".icon-yes")
        expect(trs[0]).to have_text format_date(1.year.ago + 1.day)

        expect(trs[1]).to have_text("Mozilla Firefox (Version 12.3)")
        expect(trs[1]).to have_text("Linux")
        expect(trs[1]).to have_no_css(".icon-yes")
        expect(trs[1]).to have_css(".buttons a")
        expect(trs[1]).to have_text format_date(1.day.from_now)

        accept_confirm do
          trs[1].find(".buttons a").click
        end
      end

      expect(page).to have_text "Successful deletion"
      page.within_test_selector("Users::AutoLoginTokens::TableComponent") do
        expect(page).to have_css(".generic-table tbody tr", count: 1)
      end

      expect { new_token.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
