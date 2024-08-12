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

RSpec.describe "Enterprise token", :js, :with_cuprite do
  include Redmine::I18n

  shared_let(:admin) { create(:admin) }
  let(:token_object) do
    OpenProject::Token.new.tap do |token|
      token.subscriber = "Foobar"
      token.mail = "foo@example.org"
      token.starts_at = Time.zone.today
      token.expires_at = nil
      token.domain = Setting.host_name
    end
  end

  let(:textarea) { find_by_id "enterprise_token_encoded_token" }
  let(:submit_button) { find_by_id "token-submit-button" }

  describe "EnterpriseToken management" do
    before do
      login_as admin
      visit enterprise_path
    end

    it "shows a teaser and token form without a token" do
      expect(page).to have_css(".button", text: "Start free trial")
      expect(page).to have_css(".button", text: "Book now")
      expect(textarea.value).to be_empty

      textarea.set "foobar"
      submit_button.click

      # Error output
      expect(page).to have_css(".errorExplanation",
                               text: "Enterprise support token can't be read. " \
                                     "Are you sure it is a support token?")

      within "span.errorSpan" do
        expect(page).to have_css("#enterprise_token_encoded_token")
      end
    end

    context "with valid input" do
      before do
        allow(OpenProject::Token).to receive(:import).and_return(token_object)
      end

      it "allows token import flow" do
        textarea.set "foobar"
        submit_button.click

        expect(page).to have_css(".op-toast.-success", text: I18n.t(:notice_successful_update))
        expect(page).to have_test_selector("op-enterprise--active-token")

        expect(page.all(".attributes-key-value--key").map(&:text))
          .to eq ["Subscriber", "Email", "Domain", "Maximum active users", "Starts at", "Expires at"]
        expect(page.all(".attributes-key-value--value").map(&:text))
          .to eq ["Foobar", "foo@example.org", Setting.host_name, "Unlimited", format_date(Time.zone.today), "Unlimited"]

        expect(page).to have_css(".button.icon-delete", text: I18n.t(:button_delete))

        # Expect section to be collapsed
        expect(page).to have_no_css("#token_encoded_token")

        RequestStore.clear!
        expect(EnterpriseToken.current.encoded_token).to eq("foobar")

        expect(page).to have_text("Successful update")
        click_on "Replace your current support token"
        fill_in "enterprise_token_encoded_token", with: "blabla"
        submit_button.click

        wait_for_reload

        expect(page).to have_css(".op-toast.-success", text: I18n.t(:notice_successful_update))

        # Assume next request
        RequestStore.clear!
        expect(EnterpriseToken.current.encoded_token).to eq("blabla")

        # Remove token
        click_on "Delete"

        # Expect modal
        find_test_selector("confirmation-modal--confirmed").click

        wait_for_reload

        expect(page).to have_css(".op-toast.-success", text: I18n.t(:notice_successful_delete))

        # Assume next request
        RequestStore.clear!
        expect(EnterpriseToken.current).to be_nil
      end
    end
  end
end
