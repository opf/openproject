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

RSpec.describe "Menu item traversal" do
  shared_let(:admin) { create(:admin) }

  describe "EnterpriseToken management" do
    before do
      login_as(admin)
      visit admin_index_path
    end

    it "correctly maps the menu items for controllers in their namespace (Regression #30859)" do
      expect(page).to have_css(".admin-overview-menu-item.selected", text: "Overview")

      find(".plugin-webhooks-menu-item").click

      # using `controller_name` in `menu_controller.rb` has broken this example,
      # due to the plugin controller also being named 'admin' thus falling back to 'admin#index' => overview selected
      expect(page).to have_css(".plugin-webhooks-menu-item.selected", text: "Webhooks", wait: 5)
      expect(page).to have_no_css(".admin-overview-menu-item.selected")
    end
  end

  describe "route authorization", with_settings: { login_required?: false } do
    let(:user) { create(:user) }
    let(:anon) { User.anonymous }

    let(:check_link) do
      ->(link) {
        visit link

        if current_url.include? "/login?back_url="
          expect(page).to have_text("Sign in"), "#{link} should redirect to sign in"
        else
          expect(page).to have_text(I18n.t(:notice_not_authorized)), "#{link} should result in 403 response"
        end
      }
    end

    let(:check_authorized_link) do
      ->(link) {
        visit link

        expect(current_url).to include link
        expect(page).to have_http_status(:ok)
        expect(page).to have_no_text(I18n.t(:notice_not_authorized))
        expect(page).to have_css "#menu-sidebar .selected"
      }
    end

    it "checks for authorized status for all links" do
      login_as admin
      visit admin_index_path

      # Get all admin links from there
      links = all("#menu-sidebar a[href]", visible: :all)
        .map { |node| node["href"] }
        .reject { |link| link.end_with? "/#" }
        .compact
        .uniq

      links.each(&check_authorized_link)

      login_as anon
      links.each(&check_link)

      login_as user
      links.each(&check_link)
    end
  end
end
