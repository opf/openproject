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

RSpec.describe Admin::Settings::VersionsAndCategoriesController do
  shared_let(:admin) { create(:admin) }

  current_user { admin }

  describe "GET #show" do
    it "renders the show template" do
      get :show

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
    end

    context "when the current user is not an admin" do
      current_user { create(:user) }

      it "renders 403" do
        get :show

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # Persisted rather than stubbed so the request's write is observable.
  describe "POST #enable_multiple_versions" do
    let(:component_target) { "work-packages-admin-settings-target-versions-section-component" }

    before { Setting.work_package_multiple_versions = false }

    it "flips the setting and streams the section in the completed state" do
      expect do
        post :enable_multiple_versions, format: :turbo_stream
      end.to change(Setting, :work_package_multiple_versions?).from(false).to(true)

      expect(response).to have_http_status(:ok)
      expect(response).to have_turbo_stream(action: "replace", target: component_target)
      expect(response.body).to include("Recent changes")
    end

    context "when the setting is already on" do
      before { Setting.work_package_multiple_versions = true }

      it "is a no-op and streams the completed state" do
        expect do
          post :enable_multiple_versions, format: :turbo_stream
        end.not_to change(Setting, :work_package_multiple_versions?).from(true)

        expect(response).to have_turbo_stream(action: "replace", target: component_target)
        expect(response.body).to include("Recent changes")
      end
    end

    context "when the current user is not an admin" do
      current_user { create(:user) }

      it "renders 403 and leaves the setting off" do
        expect do
          post :enable_multiple_versions, format: :turbo_stream
        end.not_to change(Setting, :work_package_multiple_versions?).from(false)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the setting is not writable" do
      before do
        allow(Settings::Definition[:work_package_multiple_versions])
          .to receive_messages(writable?: false, value: false)
      end

      it "leaves the setting off, logs the failure, and streams the action_required state" do
        allow(Rails.logger).to receive(:error)

        expect do
          post :enable_multiple_versions, format: :turbo_stream
        end.not_to change(Setting, :work_package_multiple_versions?).from(false)

        expect(Rails.logger).to have_received(:error).with(/not writable/i)
        expect(response).to have_turbo_stream(action: "replace", target: component_target)
        expect(response.body).to include("Action required")
      end
    end
  end

  describe "GET #confirm_dialog" do
    it "renders the dialog turbo stream" do
      get :confirm_dialog, format: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Enable multiple target versions?")
    end
  end
end
