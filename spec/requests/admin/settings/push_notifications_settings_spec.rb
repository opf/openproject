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

RSpec.describe "Push Notifications Settings",
               :skip_csrf,
               type: :rails_request do
  let(:current_user) { create(:admin) }

  before do
    login_as(current_user)
  end

  describe "GET /admin/settings/push_notifications" do
    context "with the feature flag on", with_flag: { progressive_web_app: true } do
      it "shows the setting and the data disclosure" do
        get "/admin/settings/push_notifications"

        expect(response).to have_http_status(:ok)
        expect(page).to have_field(I18n.t(:setting_web_push_enabled))
        expect(page).to have_text(I18n.t("admin.settings.push_notifications.what_is_sent"))
        expect(page).to have_text("fcm.googleapis.com")
        expect(page).to have_button(I18n.t("admin.settings.push_notifications.check_reachability"))
        expect(page).to have_no_text(I18n.t("admin.settings.push_notifications.reachable"))
      end

      it "offers to regenerate a readable key after confirmation" do
        get "/admin/settings/push_notifications"

        expect(page).to have_no_text(I18n.t("admin.settings.push_notifications.key_unreadable"))
        expect(page).to have_button(I18n.t("admin.settings.push_notifications.regenerate_key"))
        confirmation = I18n.t("admin.settings.push_notifications.regenerate_key_confirm")
        expect(page).to have_css("form[data-turbo-confirm='#{confirmation}']")
      end

      context "when the key is managed through the environment",
              :settings_reset,
              with_env: { "OPENPROJECT_WEB__PUSH__VAPID__PRIVATE__KEY" => Base64.strict_encode64(
                OpenSSL::PKey::EC.generate("prime256v1").private_to_der
              ) } do
        before { reset(:web_push_vapid_private_key) }

        it "explains the rotation instead of offering to regenerate" do
          get "/admin/settings/push_notifications"

          expect(page).to have_text(I18n.t("admin.settings.push_notifications.key_managed_by_environment"))
          expect(page).to have_no_button(I18n.t("admin.settings.push_notifications.regenerate_key"))
        end
      end

      context "when the key is unreadable" do
        before { allow(OpenProject::WebPush).to receive(:key_readable?).and_return(false) }

        it "shows the danger banner with the regenerate button" do
          get "/admin/settings/push_notifications"

          expect(page).to have_text(I18n.t("admin.settings.push_notifications.key_unreadable"))
          expect(page).to have_button(I18n.t("admin.settings.push_notifications.regenerate_key"))
        end
      end

      context "when logged in as a non-admin" do
        let(:current_user) { create(:user) }

        it "is forbidden" do
          get "/admin/settings/push_notifications"

          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "with the feature flag off", with_flag: { progressive_web_app: false } do
      it "is not found" do
        get "/admin/settings/push_notifications"

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /admin/settings/push_notifications/check" do
    let(:results) do
      [
        OpenProject::WebPush::ReachabilityCheck::Result.new(host: "fcm.googleapis.com", reachable: true,
                                                            reason: nil, code: "404"),
        OpenProject::WebPush::ReachabilityCheck::Result.new(host: "push.apple.com", reachable: false,
                                                            reason: :unresolved, code: nil)
      ]
    end

    before { allow(OpenProject::WebPush::ReachabilityCheck).to receive(:call).and_return(results) }

    context "with the feature flag on", with_flag: { progressive_web_app: true } do
      it "redirects to the settings page, which shows the per-host results" do
        post "/admin/settings/push_notifications/check"

        expect(response).to redirect_to("/admin/settings/push_notifications")
        expect(response).to have_http_status(:see_other)

        follow_redirect!

        expect(page).to have_text(I18n.t("admin.settings.push_notifications.reachable"))
        expect(page).to have_text(I18n.t("admin.settings.push_notifications.http_status", code: "404"))
        expect(page).to have_text(I18n.t("admin.settings.push_notifications.unreachable"))
        expect(page).to have_text(I18n.t("admin.settings.push_notifications.reasons.unresolved"))
      end

      context "when logged in as a non-admin" do
        let(:current_user) { create(:user) }

        it "is forbidden and makes no request" do
          post "/admin/settings/push_notifications/check"

          expect(response).to have_http_status(:forbidden)
          expect(OpenProject::WebPush::ReachabilityCheck).not_to have_received(:call)
        end
      end
    end

    context "with the feature flag off", with_flag: { progressive_web_app: false } do
      it "is not found and makes no request" do
        post "/admin/settings/push_notifications/check"

        expect(response).to have_http_status(:not_found)
        expect(OpenProject::WebPush::ReachabilityCheck).not_to have_received(:call)
      end
    end
  end

  describe "POST /admin/settings/push_notifications/regenerate_key" do
    context "with the feature flag on", with_flag: { progressive_web_app: true } do
      let!(:subscription) { create(:push_subscription) }
      let!(:old_public_key) { OpenProject::WebPush.public_key }

      it "replaces the key, deletes the subscriptions and redirects with a notice" do
        post "/admin/settings/push_notifications/regenerate_key"

        expect(response).to redirect_to("/admin/settings/push_notifications")
        expect(response).to have_http_status(:see_other)
        expect(flash[:notice]).to eq(I18n.t("admin.settings.push_notifications.key_regenerated"))
        expect(PushSubscription.count).to eq(0)
        expect(OpenProject::WebPush.public_key).not_to eq(old_public_key)
      end

      context "when the key is managed through the environment",
              :settings_reset,
              with_env: { "OPENPROJECT_WEB__PUSH__VAPID__PRIVATE__KEY" => Base64.strict_encode64(
                OpenSSL::PKey::EC.generate("prime256v1").private_to_der
              ) } do
        before { reset(:web_push_vapid_private_key) }

        it "redirects with an error and keeps the subscriptions" do
          post "/admin/settings/push_notifications/regenerate_key"

          expect(response).to redirect_to("/admin/settings/push_notifications")
          expect(flash[:error]).to eq(I18n.t("admin.settings.push_notifications.key_managed_by_environment"))
          expect(PushSubscription.count).to eq(1)
        end
      end

      context "when logged in as a non-admin" do
        let(:current_user) { create(:user) }

        it "is forbidden and keeps the key and the subscriptions" do
          post "/admin/settings/push_notifications/regenerate_key"

          expect(response).to have_http_status(:forbidden)
          expect(PushSubscription.count).to eq(1)
          expect(OpenProject::WebPush.public_key).to eq(old_public_key)
        end
      end
    end

    context "with the feature flag off", with_flag: { progressive_web_app: false } do
      it "is not found" do
        create(:push_subscription)

        post "/admin/settings/push_notifications/regenerate_key"

        expect(response).to have_http_status(:not_found)
        expect(PushSubscription.count).to eq(1)
      end
    end
  end

  describe "PATCH /admin/settings/push_notifications", with_flag: { progressive_web_app: true } do
    before { create(:push_subscription) }

    it "switches the setting off and deletes the subscriptions" do
      patch "/admin/settings/push_notifications", params: { settings: { web_push_enabled: "0" } }

      expect(Setting.web_push_enabled?).to be(false)
      expect(PushSubscription.count).to eq(0)
    end

    context "with the feature flag off", with_flag: { progressive_web_app: false } do
      it "is not found and keeps the subscriptions" do
        patch "/admin/settings/push_notifications", params: { settings: { web_push_enabled: "0" } }

        expect(response).to have_http_status(:not_found)
        expect(PushSubscription.count).to eq(1)
      end
    end
  end
end
