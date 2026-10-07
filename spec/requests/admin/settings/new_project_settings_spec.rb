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

require "spec_helper"

RSpec.describe "New project settings", :settings_reset, :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }

  before { login_as(admin) }

  def page_html = Capybara.string(response.body)

  describe "GET the settings tab" do
    let!(:qualifying_role) { create(:project_creator_role, name: "Project lead") }
    let!(:non_qualifying_role) { create(:project_role, name: "Reader", permissions: %i[view_work_packages]) }

    it "renders the project modules with the default ones checked", :aggregate_failures,
       with_settings: { default_projects_modules: %w[news] } do
      get admin_settings_new_project_path(tab: "settings")

      expect(page_html).to have_field "settings[default_projects_modules][]", with: "activity", checked: false
      expect(page_html).to have_field "settings[default_projects_modules][]", with: "news", checked: true
    end

    it "lists only roles with the required permissions", :aggregate_failures do
      get admin_settings_new_project_path(tab: "settings")

      expect(page_html).to have_select "settings[new_project_user_role_id]", with_options: [qualifying_role.name]
      expect(page_html).to have_no_css "option", text: non_qualifying_role.name
    end

    context "when the configured role no longer has the required permissions" do
      before { Setting.new_project_user_role_id = non_qualifying_role.id }

      it "still lists the configured role, marked as missing required permissions, and selected" do
        get admin_settings_new_project_path(tab: "settings")

        expect(page_html).to have_select "settings[new_project_user_role_id]",
                                         selected: "#{non_qualifying_role.name} (missing required permissions)"
      end
    end
  end

  describe "GET the notifications tab" do
    it "renders the notification settings and both tabs", :aggregate_failures do
      get admin_settings_new_project_path(tab: "notifications")

      expect(page_html).to have_field "settings[new_project_send_confirmation_email]", type: :checkbox
      expect(page_html).to have_no_field "settings[default_projects_modules][]"
      expect(page_html).to have_link "Settings", href: admin_settings_new_project_path(tab: "settings")
    end
  end

  describe "PATCH" do
    it "stores the project modules and redirects back to the tab", :aggregate_failures do
      patch admin_settings_new_project_path(tab: "settings"),
            params: { settings: { default_projects_modules: %w[activity news] } }

      expect(response).to redirect_to admin_settings_new_project_path(tab: "settings")
      expect(Setting.default_projects_modules).to eq %w[activity news]
    end

    it "rejects project modules without their dependencies", :aggregate_failures do
      dependent = OpenProject::AccessControl.modules.find { it[:dependencies].present? }
      skip "No project module with dependencies" unless dependent

      patch admin_settings_new_project_path(tab: "settings"),
            params: { settings: { default_projects_modules: [dependent[:name].to_s] } }

      expect(flash[:error]).to include I18n.t("project_module_#{dependent[:name]}")
      expect(Setting.default_projects_modules).not_to eq [dependent[:name].to_s]
    end

    it "stores the notification settings", :aggregate_failures do
      patch admin_settings_new_project_path(tab: "notifications"),
            params: { settings: { new_project_send_confirmation_email: "1", new_project_notification_text: "Custom message" } }

      expect(response).to redirect_to admin_settings_new_project_path(tab: "notifications")
      expect(Setting.new_project_send_confirmation_email).to be true
      expect(Setting.new_project_notification_text).to eq "Custom message"
    end

    it "ignores settings of other pages" do
      expect { patch admin_settings_new_project_path(tab: "settings"), params: { settings: { password_min_length: 42 } } }
        .not_to change(Setting, :password_min_length)
    end
  end

  describe "password settings on the authentication page" do
    let(:new_settings) { { password_min_length: 42, lost_password: false } }

    before do
      Setting.password_min_length = 10
      Setting.lost_password = true
    end

    it "updates them with password login enabled", :aggregate_failures do
      allow(Users::PasswordLogin).to receive(:none?).and_return(false)

      patch admin_settings_authentication_path(tab: "passwords"), params: { settings: new_settings }

      expect(Setting.password_min_length).to eq 42
      expect(Setting.lost_password?).to be false
    end

    it "ignores them with password login disabled", :aggregate_failures do
      allow(Users::PasswordLogin).to receive(:none?).and_return(true)

      patch admin_settings_authentication_path(tab: "passwords"), params: { settings: new_settings }

      expect(Setting.password_min_length).to eq 10
      expect(Setting.lost_password?).to be true
    end
  end
end
