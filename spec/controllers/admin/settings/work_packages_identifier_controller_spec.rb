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

RSpec.describe Admin::Settings::WorkPackagesIdentifierController do
  shared_let(:user) { create(:admin) }

  current_user { user }

  describe "GET #status" do
    let(:component_target) { "work-packages-admin-settings-identifier-settings-form-component" }

    context "when a migration job is in progress" do
      before do
        allow(ProjectIdentifiers::IdentifierAutofix).to receive_messages(job_in_progress?: true, reversion_in_progress?: false)
        allow(ProjectIdentifiers::PendingProjectsFinder).to receive(:count).and_return(5)
      end

      it "returns 200 with a turbo stream replacing the form component in change_in_progress state" do
        get :status, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response).to have_turbo_stream(action: "replace", target: component_target)
        expect(response.body).to include("Background conversion is in progress")
      end
    end

    context "when no migration job is in progress" do
      before do
        allow(ProjectIdentifiers::IdentifierAutofix).to receive(:job_in_progress?).and_return(false)
      end

      it "returns 200 with a turbo stream replacing the form component in completed state" do
        get :status, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response).to have_turbo_stream(action: "replace", target: component_target)
        expect(response.body).to include("Successfully updated work package identifier format.")
      end
    end
  end

  describe "PATCH #update" do
    context "when work_packages_identifier is 'semantic'" do
      it "enqueues ProjectIdentifiers::ConvertInstanceToSemanticIdsJob and redirects" do
        expect do
          patch :update, params: { settings: { work_packages_identifier: "semantic" } }
        end.to have_enqueued_job(ProjectIdentifiers::ConvertInstanceToSemanticIdsJob)

        expect(response).to redirect_to(action: "show")
      end

      context "when a migration job is already in progress" do
        before do
          allow(ProjectIdentifiers::IdentifierAutofix).to receive(:job_in_progress?).and_return(true)
        end

        it "does not enqueue another job but still redirects" do
          expect do
            patch :update, params: { settings: { work_packages_identifier: "semantic" } }
          end.not_to have_enqueued_job(ProjectIdentifiers::ConvertInstanceToSemanticIdsJob)

          expect(response).to redirect_to(action: "show")
        end
      end
    end

    context "when work_packages_identifier is 'classic'" do
      it "updates the setting to classic, enqueues RevertInstanceToClassicIdsJob, and redirects" do
        expect do
          patch :update, params: { settings: { work_packages_identifier: "classic" } }
        end.to have_enqueued_job(ProjectIdentifiers::RevertInstanceToClassicIdsJob)

        expect(Setting.work_packages_identifier).to eq("classic")
        expect(response).to redirect_to(action: "show")
      end

      context "when a migration job is already in progress" do
        before do
          allow(ProjectIdentifiers::IdentifierAutofix).to receive(:job_in_progress?).and_return(true)
        end

        it "does not enqueue another job but still updates the setting and redirects" do
          expect do
            patch :update, params: { settings: { work_packages_identifier: "classic" } }
          end.not_to have_enqueued_job(ProjectIdentifiers::RevertInstanceToClassicIdsJob)

          expect(Setting.work_packages_identifier).to eq("classic")
          expect(response).to redirect_to(action: "show")
        end
      end
    end

    context "when work_packages_identifier is missing" do
      it "renders 400 without enqueuing a job" do
        patch :update, params: {}

        expect(response).to have_http_status(:bad_request)
        expect(ProjectIdentifiers::ConvertInstanceToSemanticIdsJob).not_to have_been_enqueued
        expect(ProjectIdentifiers::RevertInstanceToClassicIdsJob).not_to have_been_enqueued
      end
    end

    context "when work_packages_identifier is an unknown value" do
      it "renders 400 without enqueuing a job" do
        patch :update, params: { settings: { work_packages_identifier: "unknown_value" } }

        expect(response).to have_http_status(:bad_request)
        expect(ProjectIdentifiers::ConvertInstanceToSemanticIdsJob).not_to have_been_enqueued
        expect(ProjectIdentifiers::RevertInstanceToClassicIdsJob).not_to have_been_enqueued
      end
    end
  end
end
