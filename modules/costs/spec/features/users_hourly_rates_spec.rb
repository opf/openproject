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

require_relative "../spec_helper"

RSpec.describe "hourly rates on user edit", :js do
  let(:user) { create(:admin) }

  def view_rates
    visit edit_user_path(user, tab: "rates")
  end

  before do
    login_as user
  end

  context "with no rates" do
    before do
      view_rates
    end

    it "shows no data message" do
      expect(page).to have_text I18n.t("no_results_title_text")
    end
  end

  context "with rates" do
    let!(:rate) { create(:default_hourly_rate, user:) }

    before do
      view_rates
    end

    it "shows the rates" do
      expect(page).to have_text "Current rate".upcase
    end

    describe "deleting all rates" do
      before do
        click_link "Update" # go to update view for rates
        SeleniumHubWaiter.wait
        find(".icon-delete").click # delete last existing rate
        click_on "Save" # save change
      end

      # regression test: clicking save used to result in a error
      it "leads back to the now empty rate overview" do
        expect(page).to have_text /rate history/i
        expect(page).to have_text I18n.t("no_results_title_text")

        expect(page).to have_no_text "Current rate"
      end
    end
  end

  describe "updating rates as German user", driver: :firefox_de do
    let(:user) { create(:admin, language: "de") }
    let!(:rate) { create(:default_hourly_rate, user:, rate: 1.0) }

    it "allows editing without reinterpreting the number (Regression #42219)" do
      visit edit_hourly_rate_path(user)

      # Expect the german locale output
      expect(page).to have_field("user[existing_rate_attributes][#{rate.id}][rate]", with: "1,00")

      click_link "Satz hinzufügen"

      fill_in "user_new_rate_attributes_1_valid_from", with: (Time.zone.today + 1.day).iso8601
      find("input#user_new_rate_attributes_1_valid_from").send_keys :escape
      fill_in "user_new_rate_attributes_1_rate", with: "5,12"

      click_button "Speichern"

      view_rates

      expect(page).to have_css(".currency", text: "1,00")
      expect(page).to have_css(".currency", text: "5,12")
    end
  end
end
