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

require "rails_helper"

RSpec.describe Backlogs::SprintsController do
  describe "new actions" do
    shared_let(:type_feature) { create(:type_feature) }
    shared_let(:type_task) { create(:type_task) }

    let(:all_permissions) { %i[view_sprints view_work_packages create_sprints start_complete_sprint show_board_views] }
    let(:permissions) { all_permissions }
    let(:user) do
      create(:user, member_with_permissions: { project => permissions })
    end
    let(:project) { create(:project) }

    current_user { user }

    describe "GET #index" do
      it "responds with success", :aggregate_failures do
        get :index, params: { project_id: project.id }

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(assigns(:project)).to eq(project)
        expect(assigns(:sprints)).not_to be_nil
        expect(assigns(:work_package_counts)).to be_a(Hash)
      end
    end

    describe "GET #new_dialog" do
      it "responds with success", :aggregate_failures do
        get :new_dialog, params: { project_id: project.id }, format: :turbo_stream

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(response).to have_turbo_stream action: "dialog", target: "backlogs-sprint-dialog-component"
        expect(assigns(:project)).to eq(project)
      end

      context "without the 'create_sprints' permission" do
        let(:permissions) { all_permissions - [:create_sprints] }

        it "responds with forbidden", :aggregate_failures do
          get :new_dialog, params: { project_id: project.id }, format: :turbo_stream

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end
    end

    describe "GET #edit_dialog" do
      let!(:sprint) { create(:sprint, project:) }

      it "responds with success", :aggregate_failures do
        get :edit_dialog, params: { project_id: project.id, sprint_id: sprint.id }, format: :turbo_stream

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(response).to have_turbo_stream action: "dialog", target: "backlogs-sprint-dialog-component"
        expect(assigns(:project)).to eq(project)
        expect(assigns(:sprint)).to eq(sprint)
      end

      context "without the 'create_sprints' permission" do
        let(:permissions) { all_permissions - [:create_sprints] }

        it "responds with forbidden", :aggregate_failures do
          get :edit_dialog, params: { project_id: project.id, sprint_id: sprint.id }, format: :turbo_stream

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end
    end

    describe "POST #create" do
      let(:params) do
        {
          project_id: project.id,
          sprint: { name: "My Sprint", start_date: "2025-10-05", finish_date: "2025-10-15" }
        }
      end

      it "responds with success, creates a sprint, and redirects to backlogs", :aggregate_failures do
        post :create, format: :turbo_stream, params: params

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(response.body).to include("turbo-stream")
        expect(response.body).to have_turbo_stream(
          action: "redirect_to",
          url: project_backlogs_backlog_path(project)
        )
        expect(project.reload.sprints.last.name).to eq("My Sprint")
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_create))
      end

      context "when all=1 is passed" do
        it "redirects to backlogs preserving the all param" do
          post :create, format: :turbo_stream, params: params.merge(all: 1)

          expect(response.body).to include(project_backlogs_backlog_path(project, all: 1))
        end
      end

      context "without the 'create_sprints' permission" do
        let(:permissions) { all_permissions - [:create_sprints] }

        it "responds with forbidden", :aggregate_failures do
          post :create, format: :turbo_stream, params: params

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end
    end

    describe "PUT #update" do
      let!(:sprint) { create(:sprint, name: "Original sprint name", project:) }

      let(:params) do
        {
          project_id: project.id,
          sprint_id: sprint.id,
          sprint: { name: "Changed sprint name" }
        }
      end

      it "responds with success via the namespaced update action", :aggregate_failures do
        put :update, format: :turbo_stream, params: params

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(response.body).to have_turbo_stream action: "flash"
        expect(response.body).to have_turbo_stream action: "update", target: "backlogs-sprint-component-#{sprint.id}"
        assert_select %(turbo-stream[action="update"][target="backlogs-sprint-component-#{sprint.id}"][method="morph"])
        expect(response.body).to include("Successful update.")
        expect(sprint.reload.name).to eq("Changed sprint name")
        expect(controller.controller_path).to eq("backlogs/sprints")
        expect(controller.action_name).to eq("update")
      end

      context "without the 'create_sprints' permission" do
        let(:permissions) { all_permissions - [:create_sprints] }

        it "responds with forbidden", :aggregate_failures do
          put :update, format: :turbo_stream, params: params

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end
    end

    describe "POST #start" do
      let!(:sprint) { create(:sprint, project:) }
      let(:service_result) { ServiceResult.success(result: sprint.tap { it.status = "active" }) }
      let(:service) { instance_double(Backlogs::Sprints::StartService, call: service_result) }
      let(:request_params) { { project_id: project.id, sprint_id: sprint.id } }

      before do
        allow(Backlogs::Sprints::StartService)
          .to receive(:new)
          .with(user:, model: sprint)
          .and_return(service)
      end

      context "when the sprint is rendered in a receiving project" do
        let(:source_project) { create(:project, sprint_sharing: "share_all_projects") }
        let(:project) { create(:project, sprint_sharing: "receive_shared") }
        let!(:sprint) { create(:sprint, project: source_project) }
        let(:source_permissions) { %i[view_sprints start_complete_sprint] }
        let!(:board) { create(:board_grid_with_query, project:, linked: sprint) }

        before do
          create(:member,
                 project: source_project,
                 principal: user,
                 roles: [create(:project_role, permissions: source_permissions)])
        end

        it "starts the sprint and redirects to the board", :aggregate_failures do
          post :start, format: :turbo_stream, params: request_params

          expect(response).to be_successful
          expect(response).to have_turbo_stream(action: "redirect_to")
          expect(service).to have_received(:call)
        end

        context "without source-project start permission" do
          let(:source_permissions) { %i[view_sprints] }

          it "responds with forbidden and does not call the service", :aggregate_failures do
            post :start, params: request_params

            expect(response).not_to be_successful
            expect(response).to have_http_status(:forbidden)
            expect(service).not_to have_received(:call)
          end
        end

        context "without rendered-project board access" do
          let(:permissions) { all_permissions - [:show_board_views] }

          it "responds with forbidden and does not call the service", :aggregate_failures do
            post :start, params: request_params

            expect(response).not_to be_successful
            expect(response).to have_http_status(:forbidden)
            expect(service).not_to have_received(:call)
          end
        end
      end

      context "when a board already exists" do
        let!(:existing_board) do
          create(:board_grid_with_query,
                 project:,
                 linked: sprint)
        end

        it "starts the sprint and redirects to the board", :aggregate_failures do
          post :start, format: :turbo_stream, params: request_params

          expect(response).to be_successful
          expect(response).to have_turbo_stream(action: "redirect_to")
          expect(service).to have_received(:call)
        end
      end

      context "when board creation succeeds" do
        let(:board) { create(:board_grid_with_query, project:, linked: sprint) }
        let(:service_result) do
          started_sprint = sprint.tap { it.status = "active" }
          allow(started_sprint).to receive(:task_board_for).with(project).and_return(board)

          ServiceResult.success(
            result: started_sprint
          )
        end

        it "creates the board, starts the sprint, and redirects to the board", :aggregate_failures do
          post :start, format: :turbo_stream, params: request_params

          expect(response).to be_successful
          expect(response).to have_turbo_stream(action: "redirect_to")
          expect(flash[:notice]).to eq(I18n.t(:notice_successful_start))
          expect(service).to have_received(:call)
        end
      end

      context "when board creation fails" do
        let(:service_result) { ServiceResult.failure(message: "something went wrong") }

        it "redirects back to the backlog and leaves the sprint in planning", :aggregate_failures do
          post :start, params: request_params

          expect(response).to redirect_to(project_backlogs_backlog_path(project))
          expect(flash[:alert]).to eq(
            I18n.t(:notice_unsuccessful_start_with_reason, reason: "something went wrong")
          )
          expect(sprint.reload).to be_in_planning
        end
      end

      context "when sprint start fails without an explicit message" do
        let(:service_result) { ServiceResult.failure }

        it "redirects back with the default start failure message", :aggregate_failures do
          post :start, params: request_params

          expect(response).to redirect_to(project_backlogs_backlog_path(project))
          expect(flash[:alert]).to eq(I18n.t(:notice_unsuccessful_start))
          expect(service).to have_received(:call)
        end
      end

      context "when another sprint is already active" do
        let!(:active_sprint) { create(:sprint, project:, status: "active") }
        let(:service_result) do
          ServiceResult.failure(
            result: sprint,
            message: sprint.errors.full_messages.to_sentence
          )
        end

        it "redirects back to the backlog and leaves the sprint in planning", :aggregate_failures do
          post :start, params: request_params

          expect(response).to redirect_to(project_backlogs_backlog_path(project))
          expect(flash[:alert]).to eq(I18n.t(:notice_unsuccessful_start))
          expect(service).to have_received(:call)
        end
      end

      context "without the 'start_complete_sprint' permission" do
        let(:permissions) { all_permissions - [:start_complete_sprint] }

        it "responds with forbidden", :aggregate_failures do
          post :start, params: request_params

          expect(response).not_to be_successful
          expect(response).to have_http_status(:forbidden)
        end
      end

      context "when the sprint is already active" do
        let!(:sprint) { create(:sprint, project:, status: "active") }
        let(:service_result) { ServiceResult.failure }

        it "redirects back with the default start failure message", :aggregate_failures do
          post :start, params: request_params

          expect(response).to redirect_to(project_backlogs_backlog_path(project))
          expect(flash[:alert]).to eq(I18n.t(:notice_unsuccessful_start))
          expect(service).to have_received(:call)
        end
      end
    end

    describe "POST #finish" do
      let!(:sprint) { create(:sprint, project:, status: "active") }
      let(:request_params) { { project_id: project.id, sprint_id: sprint.id } }
      let(:service_result) do
        ServiceResult.success(
          result: sprint.tap { |finished_sprint| finished_sprint.status = "completed" }
        )
      end
      let(:service) { instance_double(Backlogs::Sprints::FinishService, call: service_result) }

      before do
        allow(Backlogs::Sprints::FinishService)
          .to receive(:new)
          .with(user:, model: sprint)
          .and_return(service)
      end

      context "when the sprint is rendered in a receiving project" do
        let(:source_project) { create(:project, sprint_sharing: "share_all_projects") }
        let(:project) { create(:project, sprint_sharing: "receive_shared") }
        let!(:sprint) { create(:sprint, project: source_project, status: "active") }
        let(:source_permissions) { %i[view_sprints start_complete_sprint] }

        before do
          create(:member,
                 project: source_project,
                 principal: user,
                 roles: [create(:project_role, permissions: source_permissions)])
        end

        it "finishes the sprint and redirects to the backlog", :aggregate_failures do
          post :finish, params: request_params

          expect(response).to be_successful
          expect(response.body).to have_turbo_stream(
            action: "redirect_to",
            url: project_backlogs_backlog_path(project)
          )
          expect(flash[:notice]).to eq(I18n.t(:notice_successful_finish))
          expect(service).to have_received(:call)
        end

        context "without source-project start permission" do
          let(:source_permissions) { %i[view_sprints] }

          it "responds with forbidden and does not call the service", :aggregate_failures do
            post :finish, params: request_params

            expect(response).not_to be_successful
            expect(response).to have_http_status(:forbidden)
            expect(service).not_to have_received(:call)
          end
        end
      end

      it "finishes the sprint and redirects to the backlog via turbo stream", :aggregate_failures do
        post :finish, format: :turbo_stream, params: request_params

        expect(response).to be_successful
        expect(response.body).to have_turbo_stream(
          action: "redirect_to",
          url: project_backlogs_backlog_path(project)
        )
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_finish))
        expect(service).to have_received(:call)
      end

      context "when finishing fails" do
        let(:service_result) { ServiceResult.failure(message: "something went wrong") }

        it "redirects back to the backlog", :aggregate_failures do
          post :finish, params: request_params

          expect(response).to redirect_to(project_backlogs_backlog_path(project))
          expect(flash[:alert]).to eq(
            I18n.t(:notice_unsuccessful_finish_with_reason, reason: "something went wrong")
          )
          expect(service).to have_received(:call)
        end
      end

      context "when finishing fails without an explicit message" do
        let(:service_result) { ServiceResult.failure }

        it "redirects back with the default finish failure message", :aggregate_failures do
          post :finish, params: request_params

          expect(response).to redirect_to(project_backlogs_backlog_path(project))
          expect(flash[:alert]).to eq(I18n.t(:notice_unsuccessful_finish))
          expect(service).to have_received(:call)
        end
      end

      context "without the 'start_complete_sprint' permission" do
        let(:permissions) { all_permissions - [:start_complete_sprint] }

        it "responds with forbidden", :aggregate_failures do
          post :finish, params: request_params

          expect(response).not_to be_successful
          expect(response).to have_http_status(:forbidden)
        end
      end

      context "when the sprint is already completed" do
        let!(:sprint) { create(:sprint, project:, status: "completed") }
        let(:service_result) { ServiceResult.failure }

        it "redirects back with the default finish failure message", :aggregate_failures do
          post :finish, params: request_params

          expect(response).to redirect_to(project_backlogs_backlog_path(project))
          expect(flash[:alert]).to eq(I18n.t(:notice_unsuccessful_finish))
          expect(service).to have_received(:call)
        end
      end

      context "when moving to the top of the backlog" do
        let(:request_params) { { project_id: project.id, sprint_id: sprint.id, unfinished_action: "move_to_top_of_backlog" } }

        it "passes unfinished_action to the service and redirects via turbo stream", :aggregate_failures do
          post :finish, format: :turbo_stream, params: request_params

          expect(response).to be_successful
          expect(response.body).to have_turbo_stream(action: "redirect_to")

          expect(service).to have_received(:call)
            .with(hash_including(unfinished_action: "move_to_top_of_backlog"))
        end
      end

      context "when moving to the bottom of the backlog" do
        let(:request_params) { { project_id: project.id, sprint_id: sprint.id, unfinished_action: "move_to_bottom_of_backlog" } }

        it "passes unfinished_action to the service and redirects via turbo stream", :aggregate_failures do
          post :finish, format: :turbo_stream, params: request_params

          expect(response).to be_successful
          expect(response.body).to have_turbo_stream(action: "redirect_to")

          expect(service).to have_received(:call)
            .with(hash_including(unfinished_action: "move_to_bottom_of_backlog"))
        end
      end
    end

    describe "GET #refresh_form" do
      let(:params) do
        {
          project_id: project.id,
          sprint: { name: "My Sprint", start_date: "2025-10-05", finish_date: "2025-10-15" }
        }
      end

      it "responds with success", :aggregate_failures do
        get :refresh_form, format: :turbo_stream, params: params

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(response).to have_turbo_stream action: "update", target: "backlogs-sprint-form-component"
        expect(assigns(:sprint)).to be_nil
      end

      context "without the 'create_sprints' permission" do
        let(:permissions) { all_permissions - [:create_sprints] }

        it "responds with forbidden", :aggregate_failures do
          get :refresh_form, format: :turbo_stream, params: params

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end

      context "when refreshing the form in edit mode by passing a sprint id" do
        let!(:sprint) { create(:sprint, project:) }
        let(:params) do
          {
            project_id: project.id,
            sprint: { id: sprint.id, name: "My Sprint", start_date: "2025-10-05", finish_date: "2025-10-15" }
          }
        end

        it "responds with success", :aggregate_failures do
          get :refresh_form, format: :turbo_stream, params: params

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response).to have_turbo_stream action: "update", target: "backlogs-sprint-form-component"
        end
      end
    end
  end
end
