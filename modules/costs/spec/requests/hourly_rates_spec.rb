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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../spec_helper"

RSpec.describe "Managing hourly rates", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[edit_hourly_rates] }) }
  shared_let(:admin) { create(:admin) }

  # Turbo submits dialog forms asking for a stream, and the controllers only
  # answer that format.
  let(:turbo) { { "Accept" => "text/vnd.turbo-stream.html" } }

  describe "default rates" do
    current_user { admin }

    let(:default_rates_table) { "hourly-rates-table-component-default" }

    describe "creating" do
      it "opens the dialog" do
        get new_default_hourly_rate_path(principal_id: user), headers: turbo

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("hourly-rate-dialog")
      end

      it "creates the rate and hands back a refreshed table" do
        expect do
          post default_hourly_rates_path,
               params: { rate: { user_id: user.id, valid_from: "2026-01-01", rate: "95" } },
               headers: turbo
        end.to change { user.default_rates.count }.by(1)

        expect(user.default_rates.sole.rate).to eq(95)
        expect(response.body).to include(default_rates_table)
      end

      it "re-renders the form when the rate is not a number" do
        post default_hourly_rates_path,
             params: { rate: { user_id: user.id, valid_from: "2026-01-01", rate: "nope" } },
             headers: turbo

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include("hourly-rates-rate-form-component")
      end

      context "as a non-admin" do
        current_user { user }

        it "is forbidden" do
          post default_hourly_rates_path,
               params: { rate: { user_id: user.id, valid_from: "2026-01-01", rate: "95" } },
               headers: turbo

          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    # The permission is global, so it reaches the user administration area
    # without the acting user being an admin.
    describe "as a non-admin holding manage_user and manage_default_hourly_rates" do
      # view_all_principals is a declared dependency of manage_user, which the
      # role form grants along with it.
      current_user do
        create(:user, global_permissions: %i[manage_user view_all_principals manage_default_hourly_rates])
      end

      it "reaches the rates tab of the user administration" do
        get edit_user_path(user, tab: :rates)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("rate-history-default")
      end

      it "is offered the button to add a default rate" do
        get edit_user_path(user, tab: :rates)

        expect(response.body).to include(new_default_hourly_rate_path(principal_id: user.id))
      end

      it "creates a default rate" do
        expect do
          post default_hourly_rates_path,
               params: { rate: { user_id: user.id, valid_from: "2026-01-01", rate: "95" } },
               headers: turbo
        end.to change { user.default_rates.count }.by(1)
      end
    end

    describe "as a non-admin holding only manage_user" do
      current_user { create(:user, global_permissions: %i[manage_user view_all_principals]) }

      it "is not offered the rates tab" do
        get edit_user_path(user, tab: :rates)

        expect(response.body).not_to include("rate-history-default")
      end

      it "cannot create a default rate" do
        expect do
          post default_hourly_rates_path,
               params: { rate: { user_id: user.id, valid_from: "2026-01-01", rate: "95" } },
               headers: turbo
        end.not_to change(DefaultHourlyRate, :count)
      end
    end

    describe "editing" do
      let!(:rate) { create(:default_hourly_rate, principal: user, rate: 50) }

      it "opens the same dialog" do
        get edit_default_hourly_rate_path(rate), headers: turbo

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("hourly-rate-dialog")
      end

      it "updates the rate and hands back a refreshed table" do
        patch default_hourly_rate_path(rate),
              params: { rate: { valid_from: "2026-02-01", rate: "1,50" } },
              headers: turbo

        expect(rate.reload).to have_attributes(rate: 1.5, valid_from: Date.new(2026, 2, 1))
        expect(response.body).to include(default_rates_table)
      end

      it "keeps the dialog open on an invalid rate" do
        patch default_hourly_rate_path(rate),
              params: { rate: { valid_from: "2026-02-01", rate: "nope" } },
              headers: turbo

        expect(response).to have_http_status(:bad_request)
        expect(rate.reload.rate).to eq(50)
      end
    end

    describe "deleting" do
      let!(:rate) { create(:default_hourly_rate, principal: user, rate: 50) }

      it "asks for confirmation first" do
        get deletion_dialog_default_hourly_rate_path(rate), headers: turbo

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("hourly-rate-delete-dialog")
      end

      it "deletes the rate and hands back a refreshed table" do
        expect do
          delete default_hourly_rate_path(rate), headers: turbo
        end.to change(DefaultHourlyRate, :count).by(-1)

        expect(response.body).to include(default_rates_table)
      end

      context "as a non-admin" do
        current_user { user }

        it "is forbidden" do
          expect { delete default_hourly_rate_path(rate), headers: turbo }
            .not_to change(DefaultHourlyRate, :count)

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe "project rates" do
    current_user { user }

    let(:project_rates_table) { "hourly-rates-table-component-#{project.id}" }

    describe "creating" do
      it "opens the dialog, warning that booked costs are recalculated" do
        get new_projects_hourly_rate_path(project_id: project, principal_id: user), headers: turbo

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("hourly-rate-dialog")
        expect(response.body).to include(I18n.t(:text_hourly_rate_recalculation))
      end

      it "creates the rate in the project and hands back a refreshed table" do
        expect do
          post projects_hourly_rates_path(project_id: project),
               params: { rate: { user_id: user.id, valid_from: "2026-01-01", rate: "120" } },
               headers: turbo
        end.to change { user.rates.where(project:).count }.by(1)

        expect(user.rates.sole.rate).to eq(120)
        expect(response.body).to include(project_rates_table)
      end

      context "without the permission" do
        current_user { create(:user, member_with_permissions: { project => %i[view_hourly_rates] }) }

        it "does not create the rate" do
          expect do
            post projects_hourly_rates_path(project_id: project),
                 params: { rate: { user_id: user.id, valid_from: "2026-01-01", rate: "120" } },
                 headers: turbo
          end.not_to change(HourlyRate, :count)
        end
      end
    end

    describe "editing" do
      let!(:rate) { create(:hourly_rate, principal: user, project:, rate: 50) }

      it "opens the same dialog, warning that booked costs are recalculated" do
        get edit_hourly_rate_path(rate), headers: turbo

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("hourly-rate-dialog")
        expect(response.body).to include(I18n.t(:text_hourly_rate_recalculation))
      end

      it "updates the rate and hands back a refreshed table" do
        patch hourly_rate_path(rate),
              params: { rate: { valid_from: "2026-02-01", rate: "1,50" } },
              headers: turbo

        expect(rate.reload).to have_attributes(rate: 1.5, valid_from: Date.new(2026, 2, 1))
        expect(response.body).to include(project_rates_table)
      end

      context "without the permission" do
        current_user { create(:user, member_with_permissions: { project => %i[view_hourly_rates] }) }

        it "does not update the rate" do
          patch hourly_rate_path(rate),
                params: { rate: { valid_from: "2026-02-01", rate: "99" } },
                headers: turbo

          expect(rate.reload.rate).to eq(50)
        end
      end
    end

    describe "deleting" do
      let!(:rate) { create(:hourly_rate, principal: user, project:, rate: 50) }

      it "asks for confirmation first" do
        get deletion_dialog_hourly_rate_path(rate), headers: turbo

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("hourly-rate-delete-dialog")
      end

      it "deletes the rate and hands back a refreshed table" do
        expect { delete hourly_rate_path(rate), headers: turbo }.to change(HourlyRate, :count).by(-1)

        expect(response.body).to include(project_rates_table)
      end

      context "without the permission" do
        current_user { create(:user, member_with_permissions: { project => %i[view_hourly_rates] }) }

        it "does not delete the rate" do
          expect { delete hourly_rate_path(rate), headers: turbo }.not_to change(HourlyRate, :count)
        end
      end
    end
  end
end
