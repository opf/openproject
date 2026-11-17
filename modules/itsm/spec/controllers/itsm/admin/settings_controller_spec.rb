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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe ITSM::Admin::SettingsController, with_flag: { helpdesk: true } do
  current_user { create(:admin) }

  describe "POST #enable_helpdesk" do
    subject(:enable) { post :enable_helpdesk, params: { value: }, format: :turbo_stream }

    context "when enabling the help desk" do
      let(:value) { "1" }

      it "creates the help desk user" do
        expect { enable }.to change(ServiceAccount, :count).by(1)
        expect(Setting.helpdesk_enabled?).to be(true)
      end

      context "when the help desk role cannot be created" do
        before { create(:project_role, name: "Help desk") }

        it "keeps the help desk off and shows why", :aggregate_failures do
          expect { enable }.not_to change(ServiceAccount, :count)
          expect(Setting.helpdesk_enabled?).to be(false)
          expect(response).to have_http_status(:ok)
          expect(response).to have_turbo_stream(action: "update", target: "itsm-admin-helpdesk-toggle-component")
          expect(response).to have_turbo_stream(action: "flash")
          expect(response.body).to include("its role or user could not be created: Name has already been taken.")
        end
      end
    end

    context "when disabling the help desk" do
      let(:value) { "0" }

      it "does not create the help desk user" do
        expect { enable }.not_to change(ServiceAccount, :count)
        expect(Setting.helpdesk_enabled?).to be(false)
      end
    end
  end
end
