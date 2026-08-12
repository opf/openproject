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

RSpec.describe Admin::Settings::NewProjectSettingsController do
  shared_let(:user) { create(:admin) }
  current_user { user }

  before do
    allow(controller).to receive(:set_localization)
  end

  describe "GET #show" do
    render_views

    describe "default project modules" do
      it "contains a check box for the activity module on the settings tab" do
        get "show", params: { tab: "settings" }

        expect(response).to be_successful
        expect(response).to render_template "admin/settings/new_project_settings/show"
        expect(response.body).to have_css "input[@name='settings[default_projects_modules][]'][@value='activity']"
      end

      context "without activated activity module" do
        before do
          Setting.default_projects_modules = %w[wiki]
        end

        it "contains an unchecked checkbox for activity" do
          get "show", params: { tab: "settings" }

          expect(response).to be_successful
          expect(response).to render_template "admin/settings/new_project_settings/show"

          expect(response.body)
            .to have_no_css "input[@name='settings[default_projects_modules][]'][@value='activity'][@checked='checked']"
        end
      end

      context "with activity in Setting.default_projects_modules" do
        before do
          Setting.default_projects_modules = %w[activity]
        end

        it "contains a checked checkbox for activity" do
          get "show", params: { tab: "settings" }

          expect(response).to be_successful
          expect(response).to render_template "admin/settings/new_project_settings/show"
          expect(response.body)
            .to have_css "input[@name='settings[default_projects_modules][]'][@value='activity'][@checked='checked']"
        end
      end
    end

    describe "default role for new projects" do
      let!(:qualifying_role) { create(:project_creator_role, name: "Project lead") }
      let!(:non_qualifying_role) do
        create(:project_role, name: "Reader", permissions: %i[view_work_packages])
      end

      it "lists only roles with the required permissions" do
        get "show", params: { tab: "settings" }

        expect(response.body)
          .to have_css("select[name='settings[new_project_user_role_id]'] option",
                       text: qualifying_role.name)
        expect(response.body)
          .to have_no_css("select[name='settings[new_project_user_role_id]'] option",
                          text: non_qualifying_role.name)
      end

      context "when the configured role no longer has the required permissions" do
        before do
          Setting.new_project_user_role_id = non_qualifying_role.id
        end

        it "still lists the configured role, marked as missing required permissions, and selected" do
          get "show", params: { tab: "settings" }

          expect(response.body)
            .to have_css("select[name='settings[new_project_user_role_id]'] " \
                         "option[selected][value='#{non_qualifying_role.id}']",
                         text: "#{non_qualifying_role.name} (missing required permissions)")
        end
      end
    end

    describe "project creation notifications" do
      it "contains a checkbox for sending confirmation emails in the notifications tab" do
        get "show", params: { tab: "notifications" }

        expect(response).to be_successful
        expect(response).to render_template "admin/settings/new_project_settings/show"
        expect(response.body).to have_css "input[@name='settings[new_project_send_confirmation_email]']"
      end
    end
  end

  describe "PATCH #update" do
    render_views

    describe "default project modules" do
      it "does not store the activity in the default_projects_modules if unchecked" do
        patch "update",
              params: {
                tab: "settings",
                settings: {
                  default_projects_modules: ["wiki"]
                }
              }

        expect(response).to be_redirect
        expect(response).to redirect_to action: "show", tab: "settings"

        expect(Setting.default_projects_modules).to eq(["wiki"])
      end

      it "stores the activity in the default_projects_modules if checked" do
        patch "update",
              params: {
                tab: "settings",
                settings: {
                  default_projects_modules: ["activity", "wiki"]
                }
              }

        expect(response).to be_redirect
        expect(response).to redirect_to action: "show", tab: "settings"

        expect(Setting.default_projects_modules).to eq(["activity", "wiki"])
      end
    end

    describe "project creation notifications" do
      it "enables confirmation emails when checked" do
        expect(Setting.new_project_send_confirmation_email).to be false

        patch "update",
              params: {
                tab: "notifications",
                settings: {
                  new_project_send_confirmation_email: "1"
                }
              }

        expect(response).to be_redirect
        expect(response).to redirect_to action: "show", tab: "notifications"

        expect(Setting.new_project_send_confirmation_email).to be true
      end

      it "stores the notification text" do
        patch "update",
              params: {
                tab: "notifications",
                settings: {
                  new_project_send_confirmation_email: "1",
                  new_project_notification_text: "Custom notification message"
                }
              }

        expect(response).to be_redirect
        expect(Setting.new_project_notification_text).to eq("Custom notification message")
      end
    end

    describe "password settings" do
      let(:new_settings) do
        {
          password_min_length: 42,
          password_active_rules: %w(uppercase lowercase),
          password_days_valid: 13,
          password_count_former_banned: 80,
          lost_password: false
        }
      end

      before do
        old_settings = {
          password_min_length: 10,
          password_active_rules: [],
          password_days_valid: 365,
          password_count_former_banned: 2,
          lost_password: true
        }

        old_settings.each do |key, value|
          Setting[key] = value
        end
      end

      context "with password login enabled" do
        before do
          allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(false)

          patch "update", params: { tab: "authentication", settings: new_settings }
        end

        it "is successful" do
          expect(response).to be_redirect # to auth tab
        end

        it "sets the minimum password length to 42" do
          expect(Setting[:password_min_length]).to eq 42
        end

        it "sets the active character classes to lowercase and uppercase" do
          expect(Setting[:password_active_rules]).to eq %w[uppercase lowercase]
        end

        it "sets passwords to expire after 13 days" do
          expect(Setting[:password_days_valid]).to eq 13
        end

        it "bans the last 80 passwords" do
          expect(Setting[:password_count_former_banned]).to eq 80
        end

        it "sets the lost password option to false" do
          expect(Setting[:lost_password]).to be false
        end
      end

      describe "with password login disabled" do
        before do
          allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)

          patch "update", params: { tab: "authentication", settings: new_settings }
        end

        it "is successful" do
          expect(response).to be_redirect # to auth tab
        end

        it "does not set the minimum password length to 42" do
          expect(Setting[:password_min_length]).to eq 10
        end

        it "does not set the active character classes to lowercase and uppercase" do
          expect(Setting[:password_active_rules]).to eq []
        end

        it "does not set passwords to expire after 13 days" do
          expect(Setting[:password_days_valid]).to eq 365
        end

        it "does not ban the last 80 passwords" do
          expect(Setting[:password_count_former_banned]).to eq 2
        end

        it "keeps the lost password option" do
          expect(Setting[:lost_password]).to be true
        end
      end
    end
  end
end
