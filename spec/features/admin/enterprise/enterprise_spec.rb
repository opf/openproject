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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Enterprise token", :js do
  include Redmine::I18n

  shared_let(:admin) { create(:admin) }

  let(:enterprise_tokens_page) { Pages::Admin::EnterpriseTokens::Index.new }

  describe "EnterpriseToken management" do
    before do
      login_as admin
      enterprise_tokens_page.visit!
    end

    it "shows a teaser page and has a button to add a token with a dialog" do
      expect(page).to have_link("Start free trial")

      expect(page).to have_button("Add Enterprise token")
      click_button "Add Enterprise token"

      expect(page).to have_dialog("Add Enterprise token")
      expect(page).to have_field("Your Enterprise token text", type: "textarea")
    end

    context "with invalid input" do
      it "shows an error message" do
        enterprise_tokens_page.add_enterprise_token("foobar")

        # The dialog is still open with an error message on token field
        validation_error = "Enterprise support token can't be read. Are you sure it is a support token?"
        enterprise_tokens_page.expect_add_token_validation_error(validation_error)
      end
    end

    context "with valid input" do
      let(:token_object) do
        OpenProject::Token.new.tap do |token|
          token.subscriber = "Foobar"
          token.mail = "foo@example.org"
          token.starts_at = Date.current
          token.expires_at = nil
          token.domain = Setting.host_name
        end
      end
      let(:modals) { Components::Common::Modal.new }

      before do
        allow(OpenProject::Token).to receive(:import).and_return(token_object)
      end

      it "allows token import flow" do
        enterprise_tokens_page.add_enterprise_token("foobar")

        enterprise_tokens_page.close_welcome_video_modal

        # Table headers
        [
          "Subscription",
          "Active users",
          "Domain",
          "Dates"
        ].each do |attribute|
          expect(page).to have_text(attribute)
        end

        # Token values
        [
          "Enterprise Plan\nFoobar",
          "Unlimited",
          Setting.host_name,
          "#{format_date(Date.current)} – Unlimited"
        ].each do |attribute|
          expect(page).to have_text(attribute)
        end

        # Token is stored in the database
        expect(EnterpriseToken.last.encoded_token).to eq("foobar")

        # Remove token
        click_on "more-button"
        find(:menuitem, "Delete").click
        wait_for_network_idle

        # Expect deletion modal
        modals.expect_modal("Delete enterprise token")
        within_dialog("Delete enterprise token") do
          click_button "Delete"
        end

        # Token deleted
        expect_and_dismiss_flash(message: I18n.t(:notice_successful_delete))
        expect(EnterpriseToken.all).to be_empty
      end

      it "cannot import same token twice" do
        enterprise_tokens_page.add_enterprise_token("foobar")

        enterprise_tokens_page.close_welcome_video_modal

        # Add the token a second time
        enterprise_tokens_page.add_enterprise_token("foobar")

        # The dialog is still open with an error message on token field
        enterprise_tokens_page.expect_add_token_validation_error("This token has already been added.")

        # Try importing with blank spaces and newlines before and after
        fill_in "Your Enterprise token text", with: " \nfoobar \n"
        click_button "Add"

        # The dialog is still open with an error message on token field
        enterprise_tokens_page.expect_add_token_validation_error("This token has already been added.")
      end
    end
  end
end
