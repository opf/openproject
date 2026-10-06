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

RSpec.describe Admin::Settings::PagesController do
  shared_let(:user) { create(:admin) }

  current_user { user }

  %w[general external_links].each do |key|
    describe "GET #show for the #{key} page" do
      subject { get :show, params: { settings_page: key } }

      describe "permissions" do
        let(:fetch) { subject }

        it_behaves_like "a controller action with require_admin"
      end

      it "renders the generic settings page template" do
        subject

        expect(response).to be_successful
        expect(response).to render_template "admin/settings/pages/show", "layouts/admin"
      end
    end
  end

  describe "PATCH #update", :settings_reset do
    subject do
      patch :update, params: { settings_page: "general", settings: }
    end

    let(:settings) { { app_title: "Renamed", allowed_link_protocols: "FTP\r\nsftp" } }

    it "saves the settings of the page and redirects back to it", :aggregate_failures do
      subject

      expect(response).to redirect_to admin_settings_general_path
      expect(Setting.app_title).to eq "Renamed"
      expect(Setting.allowed_link_protocols).to eq %w[ftp sftp]
    end

    context "with settings not shown on the page" do
      let(:settings) { { app_title: "Renamed", login_required: "0" } }

      it "ignores them" do
        expect { subject }.not_to change(Setting, :login_required?)
      end
    end
  end
end
