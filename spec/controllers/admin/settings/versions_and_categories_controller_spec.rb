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

  describe "POST #enable_multiple_versions",
           with_settings: { work_package_multiple_versions: false } do
    let(:component_target) { "work-packages-admin-settings-target-versions-section-component" }

    it "enqueues the job and streams the section in the in_progress state" do
      expect do
        post :enable_multiple_versions, format: :turbo_stream
      end.to have_enqueued_job(WorkPackages::EnableMultipleVersionsJob)

      expect(response).to have_http_status(:ok)
      expect(response).to have_turbo_stream(action: "replace", target: component_target)
      expect(response.body).to include("Enabling multiple versions")
    end

    # The response asserts in_progress instead of re-deriving the state, so the admin
    # sees the spinner even when the job finishes before the first poll.
    it "streams the in_progress state although the job is not yet visible as running" do
      post :enable_multiple_versions, format: :turbo_stream

      expect(WorkPackages::EnableMultipleVersionsJob.in_progress?).to be false
      expect(response.body).to include("Enabling multiple versions")
    end

    context "when the job is already in progress" do
      before do
        allow(WorkPackages::EnableMultipleVersionsJob).to receive(:in_progress?).and_return(true)
      end

      it "does not enqueue another job and streams the in_progress state" do
        expect do
          post :enable_multiple_versions, format: :turbo_stream
        end.not_to have_enqueued_job(WorkPackages::EnableMultipleVersionsJob)

        expect(response).to have_turbo_stream(action: "replace", target: component_target)
        expect(response.body).to include("Enabling multiple versions")
      end
    end

    context "when the setting is already on", with_settings: { work_package_multiple_versions: true } do
      it "does not enqueue another job and streams the completed state" do
        expect do
          post :enable_multiple_versions, format: :turbo_stream
        end.not_to have_enqueued_job(WorkPackages::EnableMultipleVersionsJob)

        expect(response).to have_turbo_stream(action: "replace", target: component_target)
        expect(response.body).to include("Recent changes")
      end
    end

    context "when the setting is not writable" do
      before do
        allow(Settings::Definition[:work_package_multiple_versions]).to receive(:writable?).and_return(false)
      end

      it "does not enqueue the job and streams the action_required state" do
        expect do
          post :enable_multiple_versions, format: :turbo_stream
        end.not_to have_enqueued_job(WorkPackages::EnableMultipleVersionsJob)

        expect(response).to have_turbo_stream(action: "replace", target: component_target)
        expect(response.body).to include("Action required")
      end
    end
  end

  describe "GET #status",
           with_settings: { work_package_multiple_versions: false } do
    let(:component_target) { "work-packages-admin-settings-target-versions-section-component" }

    context "when the job is in progress" do
      before do
        allow(WorkPackages::EnableMultipleVersionsJob).to receive(:in_progress?).and_return(true)
      end

      it "returns 200 with a turbo stream replacing the section component in the in_progress state" do
        get :status, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response).to have_turbo_stream(action: "replace", target: component_target)
        expect(response.body).to include("Enabling multiple versions")
      end

      it "re-arms the polling controller so the page keeps checking until the job finishes" do
        get :status, format: :turbo_stream

        expect(response.body).to include("data-controller=\"poll-for-changes\"")
        expect(response.body).to include("data-poll-for-changes-url-value")
      end
    end

    context "when the setting is already on", with_settings: { work_package_multiple_versions: true } do
      it "returns 200 with a turbo stream replacing the section component in the completed state" do
        get :status, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response).to have_turbo_stream(action: "replace", target: component_target)
        expect(response.body).to include("Recent changes")
      end

      it "stops the polling by returning markup without the polling controller" do
        get :status, format: :turbo_stream

        expect(response.body).not_to include("poll-for-changes")
      end
    end

    context "when neither the job is in progress nor the setting is on" do
      it "returns 200 with a turbo stream replacing the section component in the action_required state" do
        get :status, format: :turbo_stream

        expect(response).to have_http_status(:ok)
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
