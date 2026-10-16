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

RSpec.describe "My account browser notifications",
               :skip_csrf,
               with_flag: { progressive_web_app: true },
               with_settings: { web_push_enabled: true } do
  let(:password) { "Sup3rS3cret!pass" }
  let(:user) { create(:user, password:, password_confirmation: password) }

  before do
    login_with(user.login, password)
  end

  it "shows the tab, the device explanation, the disabled banner and the empty state" do
    visit my_notifications_path(tab: "push")

    expect(page).to have_link(I18n.t("my_account.notifications_and_email.tabs.browser_push"))
    expect(page).to have_text(I18n.t("my_account.push_notifications.description"))
    expect(page).to have_text(I18n.t("my_account.push_notifications.status.disabled"))
    expect(page).to have_text(I18n.t("my_account.push_notifications.no_devices"))
    expect(page).to have_text(I18n.t("my_account.push_notifications.no_devices_description"))
    expect(page).to have_no_test_selector("push-subscription-row")
  end

  it "renders the device list fresh after returning through browser history", :js do
    visit my_notifications_path(tab: "push")
    expect(page).to have_text(I18n.t("my_account.push_notifications.no_devices"))

    other_session = create(:user_session, user:)
    create(:push_subscription, user:, session: Sessions::UserSession.find_by!(session_id: other_session.session_id),
                               browser_name: "Safari", browser_version: "17", platform: "iOS")

    click_on I18n.t(:label_account)
    expect(page).to have_current_path(my_account_path, wait: 10)

    page.go_back

    expect(page).to have_test_selector("push-subscription-row", count: 1)
    expect(page).to have_text("Safari (Version 17)")
  end

  context "when the VAPID key is unreadable" do
    before { allow(OpenProject::WebPush).to receive(:key_readable?).and_return(false) }

    it "shows the unavailable status and no buttons without reading the public key" do
      allow(OpenProject::WebPush).to receive(:public_key).and_raise(OpenProject::WebPush::UnreadableKey)

      visit my_notifications_path(tab: "push")

      expect(page).to have_text(I18n.t("my_account.push_notifications.unavailable"))
      expect(page).to have_no_button(I18n.t("my_account.push_notifications.enable"))
      expect(page).to have_no_button(I18n.t("my_account.push_notifications.disable"))
      expect(OpenProject::WebPush).not_to have_received(:public_key)
    end
  end

  context "with the setting off", with_settings: { web_push_enabled: false } do
    it "hides the tab" do
      visit my_notifications_path

      expect(page).to have_link(I18n.t("my_account.notifications_and_email.tabs.email_reminders"))
      expect(page).to have_no_link(I18n.t("my_account.notifications_and_email.tabs.browser_push"))
    end
  end

  context "with a subscription for this device and another one" do
    let(:current_session_row) do
      Sessions::UserSession.find_by!(session_id: page.driver.request.session.id.private_id)
    end
    let(:other_session_row) do
      Sessions::UserSession.find_by!(session_id: create(:user_session, user:).session_id)
    end
    let!(:current_subscription) { create(:push_subscription, user:, session: current_session_row) }
    let!(:other_subscription) do
      create(:push_subscription, user:, session: other_session_row,
                                 browser_name: "Safari", browser_version: "17", platform: "iOS")
    end

    before { visit my_notifications_path(tab: "push") }

    it "lists both devices, marks this one without offering to revoke it and shows the enabled banner" do
      expect(page).to have_text(I18n.t("my_account.push_notifications.status.enabled"))
      expect(page).to have_no_text(I18n.t("my_account.push_notifications.status.disabled"))
      expect(page).to have_test_selector("push-subscription-row", count: 2)
      expect(page).to have_text("Safari (Version 17)")
      expect(page).to have_text("iOS")
      expect(page).to have_text(I18n.t("my_account.push_notifications.this_session"), count: 1)

      within_test_selector("push-subscription-row", text: I18n.t("my_account.push_notifications.this_session")) do
        expect(page).to have_no_test_selector("push-subscription-revoke-button")
      end
    end

    it "revokes the other device" do
      within_test_selector("push-subscription-row", text: "Safari") do
        find_test_selector("push-subscription-revoke-button").click
      end

      expect(page).to have_text(I18n.t("my_account.push_notifications.revoked"))
      expect(page).to have_test_selector("push-subscription-row", count: 1)
      expect(PushSubscription.where(id: other_subscription.id)).not_to exist
      expect(PushSubscription.where(id: current_subscription.id)).to exist
    end
  end

  context "with a device that is signed out" do
    let!(:dormant_subscription) do
      create(:push_subscription, user:, session: nil, browser_name: "Firefox", browser_version: "133", platform: "Linux")
    end

    before { visit my_notifications_path(tab: "push") }

    it "shows the device as signed out and lets the user revoke it" do
      within_test_selector("push-subscription-row") do
        expect(page).to have_text("Firefox (Version 133)")
        expect(page).to have_text("Linux")
        expect(page).to have_text(I18n.t("my_account.push_notifications.signed_out"))

        find_test_selector("push-subscription-revoke-button").click
      end

      expect(page).to have_text(I18n.t("my_account.push_notifications.revoked"))
      expect(page).to have_no_test_selector("push-subscription-row")
      expect(PushSubscription.where(id: dormant_subscription.id)).not_to exist
    end
  end
end
