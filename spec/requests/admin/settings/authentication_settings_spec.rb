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

RSpec.describe "Authentication Settings",
               :skip_csrf,
               type: :rails_request do
  let(:admin) { create(:admin) }

  before do
    login_as(admin)
  end

  describe "GET /admin/settings/authentication?tab=passwords" do
    context "with password login enabled" do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(false)
        get "/admin/settings/authentication.html?tab=passwords"
      end

      it "shows password settings" do
        expect(response).to have_http_status(:success)

        expect(page).to have_field(I18n.t(:setting_lost_password), disabled: false)
        expect(page).to have_field(I18n.t(:setting_brute_force_block_after_failed_logins), disabled: false)
      end
    end

    context "with password login disabled" do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
        get "/admin/settings/authentication.html?tab=passwords"
      end

      it "disables password settings" do
        expect(response).to have_http_status(:success)

        expect(page).to have_field(I18n.t(:setting_lost_password), disabled: true)
        expect(page).to have_field(I18n.t(:setting_brute_force_block_after_failed_logins), disabled: true)
      end
    end
  end

  describe "PATCH /admin/settings/authentication?tab=passwords" do
    context "when all password requirement checkboxes are unchecked" do
      before do
        Setting.password_active_rules = %w[lowercase uppercase]
        patch "/admin/settings/authentication.html?tab=passwords",
              params: { settings: { password_active_rules: [""] } }
      end

      it "saves an empty list of active rules" do
        expect(Setting.password_active_rules).to eq([])
      end
    end
  end
end
